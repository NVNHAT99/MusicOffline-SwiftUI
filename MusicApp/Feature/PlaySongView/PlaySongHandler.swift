//
//  PlaySongHandler.swift
//  MusicApp
//
//  Created by Nhat on 9/3/23.
//

import Foundation
import Combine
import SwiftUI

final class PlaySongHandler: ObservableObject {
    @Published private(set) var state: PlaySongState
    private var cancelBag: Set<AnyCancellable> = []
//    @Published currentTimePlay
    init() {
        let playlisManager = PlaylistManager.shared
        self.state = .init(isPlaying: playlisManager.isPlaying(),
                           stateRepeat: playlisManager.getStateRepeat(),
                           currentTimePlaying: playlisManager.getCurrentTimePlay(),
                           song: playlisManager.getCurrentSongInfo())
        
        playlisManager.prepareNewSongPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] songInfo in
                self?.state.song = songInfo
            }
            .store(in: &cancelBag)
        
        playlisManager.currentTimePublisher
            .sink { newValue in
                if !self.state.isDragSlideView {
                    self.state.currentTimePlaying = newValue
                }
            }
            .store(in: &cancelBag)
        
        playlisManager.isPlayingPublisher
            .sink { [weak self] newValue in
                if newValue != self?.state.isPlaying {
                    self?.state.isPlaying = newValue
                }
            }
            .store(in: &cancelBag)
    }
    
    func send(intent: PlaysongViewIntent) {
        switch intent {
        case .play:
            state.isPlaying = true
            PlaylistManager.shared.playSong()
        case .pause:
            state.isPlaying = false
            PlaylistManager.shared.pause()
        case .nextSong:
            PlaylistManager.shared.playNextSong()
        case .previusSong:
            PlaylistManager.shared.playPreviousSong()
        case .stateRepeat:
            var newStateRepeat: StateRepeat
            switch state.stateRepeat {
            case .nomal:
                newStateRepeat = .repeatOne
            case .repeatOne:
                newStateRepeat = .shuffle
            case .shuffle:
                newStateRepeat = .nomal
            }
            PlaylistManager.shared.changeStateRepeat(state: newStateRepeat)
            state.stateRepeat = newStateRepeat
        case .timeTurnOff(let time):
            let seconds = Double(time * 60)
            PlaylistManager.shared.setupTurnOff(time: seconds)
        case .updateRunning(let newTime):
            PlaylistManager.shared.changeCurrentTimePlay(newTime: newTime)
        }
    }
    
    func sliderValue() -> Binding<Double> {
        return Binding<Double>(
            get: { self.state.currentTimePlaying },
            set: { newValue in
                self.state.currentTimePlaying = newValue
            }
        )
    }
    
    func isDrag() -> Binding<Bool> {
        return Binding<Bool>(
            get: {
                self.state.isDragSlideView
            }, set: { newValue in
                self.state.isDragSlideView = newValue
            }
        )
    }
    
    func convertTime(input: Int) -> String {
        let hours = input / 3600
        let minutes = (input % 3600) / 60
        let seconds = (input % 3600) % 60
        let minutesStr = String(format: "%02d", minutes)
        let secondsStr = String(format: "%02d", seconds)
        if hours == 0 {
            return "\(minutesStr):\(secondsStr)"
        } else {
            let hoursStr = String(format: "%02d", hours)
            return "\(hoursStr):\(minutesStr):\(secondsStr)"
        }
    }
    
    func wrapperImage() -> UIImage {
        if let image = state.song?.thumbnail {
            return image
        } else {
            return UIImage(named: "defaultThumbnail") ?? UIImage()
        }
    }
    
    func wrapRepeatIcon() -> String {
        switch state.stateRepeat {
        case .nomal:
            return  "repeat"
        case .repeatOne:
            return "repeat.1"
        case .shuffle:
            return "shuffle"
        }
    }
}
