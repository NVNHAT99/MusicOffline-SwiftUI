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
    /// Remove the lock-screen / Control Center now-playing entry if the user
    /// has never started playback this session. Clears the ghost card that
    /// iOS otherwise leaves behind across app launches.
    func clearIfNeverPlayed()
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

    // Don't publish Now Playing info until the user actually starts playback.
    // Before the audio session is ever activated, iOS renders a default PLAY
    // button on the lock screen regardless of the paused state we send — which
    // looks like "playing" while nothing is. So we stay silent until first play.
    private var hasStartedPlayback = false

    // private init để tránh tạo instance khác
    private init() {}

    func bind(to playerManager: any PlayerManagerProtocol) {
        Logger.debug("[NowPlaying] ===== bind() called — NEW SESSION START =====")
        let before = MPNowPlayingInfoCenter.default().nowPlayingInfo
        Logger.debug("[NowPlaying] bind: existing nowPlayingInfo before wipe = \(before == nil ? "nil" : "\(before!.count) keys, title=\(before?[MPMediaItemPropertyTitle] ?? "nil")")")
        // Wipe any ghost now-playing info left over from a previous app session
        // (MPNowPlayingInfoCenter is system-wide and persists across launches).
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPNowPlayingInfoCenter.default().playbackState = .stopped
        Logger.debug("[NowPlaying] bind: after wipe = \(MPNowPlayingInfoCenter.default().nowPlayingInfo == nil ? "nil ✅" : "STILL SET ❌")")

        // Lắng nghe state thay đổi
        playerManager.statePublisher
            .sink { [weak self] state in
                guard let self else { return }
                Logger.debug("[NowPlaying] statePublisher → song=\(state.currentSong?.title ?? "nil") isPlaying=\(state.isPlaying) time=\(String(format: "%.1f", state.currentTimePlay)) started=\(self.hasStartedPlayback)")

                // Latch on the first real play; once latched we keep updating
                // (so pause/resume still reflect correctly afterwards). Registering
                // remote-command handlers is what makes iOS show the lock-screen
                // media widget, so we defer that until playback actually starts —
                // otherwise a blank "playing" card appears before anything plays.
                if state.isPlaying, !self.hasStartedPlayback {
                    self.hasStartedPlayback = true
                    self.activateRemoteControls(playerManager: playerManager)
                }

                // Before the first play, actively CLEAR the now-playing info.
                // MPNowPlayingInfoCenter is system-wide and survives app kills,
                // so a previous session can leave stale metadata + a stuck
                // "playing" state on the lock screen. Wiping it here removes
                // that ghost until the user actually starts playback.
                guard self.hasStartedPlayback else {
                    self.lastSongID = nil
                    self.lastArtwork = nil
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
                    MPNowPlayingInfoCenter.default().playbackState = .stopped
                    return
                }

                if let song = state.currentSong {
                    self.updateNowPlaying(song: song,
                                          currentTime: state.currentTimePlay,
                                          isPlaying: state.isPlaying)
                } else {
                    // clear info khi không có bài nào
                    self.lastSongID = nil
                    self.lastArtwork = nil
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
                    MPNowPlayingInfoCenter.default().playbackState = .stopped
                }
            }
            .store(in: &cancellables)
    }

    private var remoteControlsActivated = false

    /// Register for remote-control events and wire up the command center. Called
    /// lazily on the first play so the lock-screen widget only appears once the
    /// user actually starts audio (not on a cold launch with nothing playing).
    private func activateRemoteControls(playerManager: any PlayerManagerProtocol) {
        guard !remoteControlsActivated else { return }
        remoteControlsActivated = true
        Logger.debug("[NowPlaying] activateRemoteControls — first play, enabling lock-screen controls")
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
        // A custom AVAudioEngine player (unlike AVPlayer/AVAudioPlayer) must
        // declare its media type, otherwise iOS may not treat it as an audio
        // now-playing app and can ignore PlaybackRate for the CC button state.
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        syncPlaybackState(isPlaying: isPlaying)
    }

    // The lock screen / Control Center button reads the discrete
    // `playbackState` enum, which is more reliable than inferring from
    // `PlaybackRate` for a custom AVAudioEngine player. If it's left at the
    // default (or a stale value), the button can show "pause" (i.e. thinks
    // it's playing) while audio is actually stopped — set it explicitly on
    // every state write so the icon always matches the engine.
    private func syncPlaybackState(isPlaying: Bool, caller: String = #function) {
        let newState: MPNowPlayingPlaybackState = isPlaying ? .playing : .paused
        Logger.debug("[NowPlaying] syncPlaybackState → \(isPlaying ? "playing" : "paused") (rate=\(isPlaying ? 1.0 : 0.0)) from \(caller)")
        MPNowPlayingInfoCenter.default().playbackState = newState
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
            info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            syncPlaybackState(isPlaying: isPlaying)
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
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        syncPlaybackState(isPlaying: isPlaying)

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
    
    func clearIfNeverPlayed() {
        guard !hasStartedPlayback else { return }
        Logger.debug("[NowPlaying] clearIfNeverPlayed → wiping ghost now-playing info")
        lastSongID = nil
        lastArtwork = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPNowPlayingInfoCenter.default().playbackState = .stopped
    }

    func updateProgress(currentTime: TimeInterval, isPlaying: Bool) {
        Logger.debug("[NowPlaying] updateProgress isPlaying=\(isPlaying) time=\(String(format: "%.1f", currentTime))")
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        syncPlaybackState(isPlaying: isPlaying)
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
            Logger.debug("[NowPlaying] CC togglePlayPause → willPlay=\(willPlay) (was isPlaying=\(playerManager.state.isPlaying))")
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
            Logger.debug("[NowPlaying] CC playCommand (was isPlaying=\(playerManager.state.isPlaying))")
            self?.pushPlaybackState(isPlaying: true, currentTime: playerManager.state.currentTimePlay)
            Task { @MainActor in await playerManager.play() }
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self, weak playerManager] _ in
            guard let playerManager else { return .commandFailed }
            Logger.debug("[NowPlaying] CC pauseCommand (was isPlaying=\(playerManager.state.isPlaying))")
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
