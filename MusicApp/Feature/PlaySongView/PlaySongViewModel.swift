//
//  PlaySongViewModel.swift
//  MusicApp
//
//  Created by Nhat on 9/3/23.
//

import Foundation
import Combine
import SwiftUI

final class PlaySongViewModel: ObservableObject {
    @Published private(set) var state: PlaySongState
    private var cancelBag: Set<AnyCancellable> = []
    init() {
        let playlisManager = PlaylistManager.shared
        self.state = .init(isPlaying: playlisManager.isPlaying(),
                           stateRepeat: playlisManager.getStateRepeat(),
                           currentTimePlaying: playlisManager.getCurrentTimePlay(),
                           song: playlisManager.getCurrentSongInfo())
        
        playlisManager.prepareNewSongPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] songInfo in
                guard let self = self else {
                    return
                }
                self.state.song = songInfo
            }
            .store(in: &cancelBag)
        
        playlisManager.currentTimePublisher
            .sink { [weak self] newValue in
                guard let self = self else {
                    return
                }
                if !self.state.isDragSlideView {
                    self.state.currentTimePlaying = newValue
                }
            }
            .store(in: &cancelBag)
        
        playlisManager.isPlayingPublisher
            .sink { [weak self] newValue in
                guard let self = self else {
                    return
                }
                if newValue != self.state.isPlaying {
                    self.state.isPlaying = newValue
                }
            }
            .store(in: &cancelBag)
        
        playlisManager.isPlayAudioFailed
            .sink { [weak self] value in
                guard let self = self else {
                    return
                }
                if value {
                    if self.state.isShowToastView {
                        self.state.isShowToastView = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            var stateCopy = self.state
                            stateCopy.isShowToastView = true
                            stateCopy.toastViewMessage = "Play new song is failed."
                            withAnimation {
                                self.state = stateCopy
                            }
                        }
                    } else {
                        var stateCopy = self.state
                        stateCopy.isShowToastView = true
                        stateCopy.toastViewMessage = "Play new song is failed."
                        withAnimation {
                            self.state.isShowToastView = false
                            self.state = stateCopy
                        }
                    }
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
            changeStateRepeate()
        case .timeTurnOff(let time):
            setupTimeTurnOff(time: time)
        case .updateRunning(let newTime):
            PlaylistManager.shared.changeCurrentTimePlay(newTime: newTime)
        }
    }
    
    private func setupTimeTurnOff(time: Int) {
        let seconds = Double(time * 60)
        PlaylistManager.shared.setupTurnOff(time: seconds)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            var stateCopy = self.state
            stateCopy.isShowToastView = true
            stateCopy.toastViewMessage = "player will turn off in \(time) minutes."
            withAnimation {
                self.state = stateCopy
            }
        }
    }
    private func changeStateRepeate() {
        var newStateRepeat: StateRepeat
        var messageStr: String = String.empty
        switch state.stateRepeat {
        case .nomal:
            newStateRepeat = .repeatOne
            messageStr = "repeat one song."
        case .repeatOne:
            newStateRepeat = .shuffle
            messageStr = "shuffle playlist."
        case .shuffle:
            newStateRepeat = .nomal
            messageStr = "repeat normal."
        }
        PlaylistManager.shared.changeStateRepeat(state: newStateRepeat)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            var stateCopy = self.state
            stateCopy.isShowToastView = true
            stateCopy.toastViewMessage = "\(messageStr)"
            stateCopy.stateRepeat = newStateRepeat
            withAnimation {
                self.state = stateCopy
            }
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
                DispatchQueue.main.async {
                    self.state.isDragSlideView = newValue
                }
            }
        )
    }
    
    // MARK: - TODO: need convert this function move to extension of the string
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
    
    func isShowToastView() -> Binding<Bool> {
        return .init {
            return self.state.isShowToastView
        } set: { newValue in
            DispatchQueue.main.async {
                withAnimation {
                    self.state.isShowToastView = newValue
                }
            }
        }

    }
}
