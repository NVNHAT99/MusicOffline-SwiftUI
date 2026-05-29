//
//  NowPlayingInfoService.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 9/16/25.
//

import Foundation
import MediaPlayer
import Combine
import UIKit

@MainActor
protocol NowPlayingInfoServiceProtocol {
    func bind(to playerManager: any PlayerManagerProtocol)
    func updateProgress(currentTime: TimeInterval, isPlaying: Bool)
}

@MainActor
final class NowPlayingInfoService: NowPlayingInfoServiceProtocol {
    // Singleton instance
    static let shared: NowPlayingInfoServiceProtocol = NowPlayingInfoService()

    private var cancellables = Set<AnyCancellable>()
    private let cache: ImageCacheProtocol = ImageCacheFactory.shared

    // Track the song whose artwork is currently in the now-playing info so we
    // only re-decode/re-fetch on a genuine song change, not on every 1s tick.
    private var lastSongID: String?
    private var lastArtwork: MPMediaItemArtwork?

    // private init để tránh tạo instance khác
    private init() {}

    func bind(to playerManager: any PlayerManagerProtocol) {
        // Lắng nghe state thay đổi
        playerManager.statePublisher
            .sink { [weak self] state in
                guard let self else { return }
                if let song = state.currentSong {
                    self.updateNowPlaying(song: song,
                                          currentTime: state.currentTimePlay,
                                          isPlaying: state.isPlaying)
                } else {
                    // clear info khi không có bài nào
                    self.lastSongID = nil
                    self.lastArtwork = nil
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
                }
            }
            .store(in: &cancellables)

        // Required for the app to receive remote-control events reliably and be
        // recognized as the active now-playing app.
        UIApplication.shared.beginReceivingRemoteControlEvents()

        setupRemoteTransportControls(playerManager: playerManager)
    }

    /// Push the current play/pause state to the system synchronously. Called from
    /// inside the remote-command handlers BEFORE returning .success — the async
    /// statePublisher sink lands too late, so Control Center keeps interpolating
    /// the old rate and flips the button back. Updating elapsed-time + rate here,
    /// in the same dictionary write, stops that.
    private func pushPlaybackState(isPlaying: Bool, currentTime: TimeInterval) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlaying(song: SongModel,
                                  currentTime: TimeInterval,
                                  isPlaying: Bool) {
        let songID = (try? song.fileURLString()) ?? song.title

        // Same song → only the elapsed time / play rate changed. Update those
        // in place (cheap) and reuse the already-decoded artwork. This is the
        // 1s-tick path and must NOT touch disk or allocate.
        if songID == lastSongID {
            var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            return
        }

        // Song changed → rebuild metadata and refresh artwork from the shared cache.
        lastSongID = songID
        lastArtwork = nil

        var nowPlayingInfo: [String: Any] = [:]
        nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = song.artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = song.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        Task { [weak self] in
            guard let self else { return }
            guard let data = await self.cache.get(for: songID),
                  let image = UIImage(data: data) else { return }
            // A newer song may have started while we awaited the cache; bail
            // so we don't attach stale artwork to the wrong track.
            guard self.lastSongID == songID else { return }

            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            self.lastArtwork = artwork
            var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
            info[MPMediaItemPropertyArtwork] = artwork
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }
    
    func updateProgress(currentTime: TimeInterval, isPlaying: Bool) {
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func setupRemoteTransportControls(playerManager: any PlayerManagerProtocol) {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Register fresh handlers. removeTarget(nil) first so re-binding never
        // stacks duplicate handlers on the process-wide shared command center.
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)

        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true

        // Control Center's single media button on iOS uses togglePlayPauseCommand
        // to manage the button's visual state. Handle it explicitly (toggling on
        // the engine's real playing state) so CC reliably flips play↔pause.
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self, weak playerManager] _ in
            guard let playerManager else { return .commandFailed }
            let willPlay = !playerManager.state.isPlaying
            // Push the NEW state to the system synchronously so Control Center
            // doesn't keep interpolating the old rate and flip the button back.
            self?.pushPlaybackState(isPlaying: willPlay, currentTime: playerManager.state.currentTimePlay)
            Task { @MainActor in
                if willPlay { await playerManager.play() } else { await playerManager.pause() }
            }
            return .success
        }

        // Commands we don't support must be disabled, otherwise iOS can route a
        // single-tap to a shadowing command (e.g. seek) and the play button
        // appears to do nothing.
        commandCenter.changePlaybackRateCommand.isEnabled = false
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false

        commandCenter.playCommand.addTarget { [weak self, weak playerManager] _ in
            guard let playerManager else { return .commandFailed }
            self?.pushPlaybackState(isPlaying: true, currentTime: playerManager.state.currentTimePlay)
            Task { @MainActor in await playerManager.play() }
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self, weak playerManager] _ in
            guard let playerManager else { return .commandFailed }
            self?.pushPlaybackState(isPlaying: false, currentTime: playerManager.state.currentTimePlay)
            Task { @MainActor in await playerManager.pause() }
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { _ in
            Task { @MainActor in await playerManager.next() }
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { _ in
            Task { @MainActor in await playerManager.previous() }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { event in
            if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                Task { @MainActor in playerManager.seek(to: positionEvent.positionTime) }
                return .success
            }
            return .commandFailed
        }
    }
}
