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
    private var subscribs: Set<AnyCancellable> = []
    private var playVM: PlayViewModel
    @Published private(set) var state: PlaySongState
//    @Published currentTimePlay
    init(playVM: PlayViewModel) {
        self.playVM = playVM
        self.state = .init(isPlaying: playVM.isPlaying(),
                           stateRepeat: playVM.stateRepeat,
                           timeToTurnOff: UserDefaults.standard.double(forKey: "timeOFF"),
                           currentTimePlaying: 0,
                           duration: playVM.duration())
        
        self.playVM.currentTimePublisher.sink(receiveValue: { [weak self] newValue in
            self?.state.currentTimePlaying = newValue
        })
        .store(in: &subscribs)
        
        self.playVM.isPlayingPublisher.sink { [weak self] newValue in
            //self?.state.isPlaying = newValue
            // MARK: - TODO: can phai nghien cuu lai logic truyen duration cho thang view vi dinh bug phat nhac
            self?.state.duration =  playVM.duration()
        }
        .store(in: &subscribs)
        
        self.playVM.didFishedPlayPublisher.sink { didFinish in
            if didFinish {
                if let urlString = PlaylistManager.shared.getNextSong(), let url = URL(string: urlString) {
                    playVM.prepareAudioToPlay(fileURL: url)
                    playVM.playAudio()
                    
                    
                }
            } else {
                // handle logic in here
            }
        }
        .store(in: &subscribs)
    }
    
    func send(intent: PlaysongViewIntent) {
        switch intent {
        case .play:
            playVM.playAudio()
        case .pause:
            playVM.pauseAudio()
        case .nextSong:
            print("nothing")
        case .previusSong:
            print("nothing")
        case .stateRepeat(let state):
            print("nothing")
        case .timeTurnOff(let time):
            print("nothing")
        default:
            break
        }
    }
    
    func sliderValue() -> Binding<Double> {
        return Binding<Double>(
            get: { self.state.currentTimePlaying },
            set: { newValue in
            }
        )
    }
}
