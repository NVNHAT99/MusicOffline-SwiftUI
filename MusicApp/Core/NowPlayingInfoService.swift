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

        setupRemoteTransportControls(playerManager: playerManager)
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
        
        commandCenter.playCommand.addTarget { _ in
            Task { await playerManager.play() }
            return .success
        }
        commandCenter.pauseCommand.addTarget { _ in
            Task { await playerManager.pause() }
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { _ in
            Task { await playerManager.next() }
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { _ in
            Task { await playerManager.previous() }
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
