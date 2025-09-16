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

protocol NowPlayingInfoServiceProtocol {
    func bind(to playerManager: any PlayerManagerProtocol)
    func updateProgress(currentTime: TimeInterval, isPlaying: Bool)
}

final class NowPlayingInfoService: NowPlayingInfoServiceProtocol {
    // Singleton instance
    static let shared: NowPlayingInfoServiceProtocol = NowPlayingInfoService()
    
    private var cancellables = Set<AnyCancellable>()
    
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
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
                }
            }
            .store(in: &cancellables)
        
        setupRemoteTransportControls(playerManager: playerManager)
    }
    
    private func updateNowPlaying(song: SongModel,
                                  currentTime: TimeInterval,
                                  isPlaying: Bool) {
        Task {
            var nowPlayingInfo: [String: Any] = [:]
            
            nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = song.artist
            
            let cache = ImageCacheFactory.createDefaultCache()
            
            if let data = await cache.get(for: try song.fileURLString()) {
                if let image = UIImage(data: data) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                }
            }
            
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = song.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
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
                playerManager.seek(to: positionEvent.positionTime)
                return .success
            }
            return .commandFailed
        }
    }
}
