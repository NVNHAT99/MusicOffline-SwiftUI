//
//  PlaylistManager.swift
//  MusicApp
//
//  Created by Nhat on 9/5/23.
//

import Foundation
import Combine

final class PlaylistManager: ObservableObject {
    // MARK: - PROPERTIES
    private var playlist: Playlist?
    private var previousIndex: Int?
    private var currentIndex: Int?
    private var playVM: PlayViewModel?
    private var subscribs: Set<AnyCancellable> = []
    
    static let shared: PlaylistManager = PlaylistManager()
    
    // MARK: - Passthrought Subjec
    let isPlayingPublisher = PassthroughSubject<Bool, Never>()
    private init() {
    }
    
    func updatePlaylist(playlist: Playlist?, currentIndex: Int) {
        if playlist?.wrappedId != self.playlist?.wrappedId {
            self.playlist = playlist
        }
        self.currentIndex = currentIndex
    }
    
    func playSong(urlString: String) {
        guard let playVM = playVM, let url = URL(string: urlString) else { return }
        playVM.prepareAudioToPlay(fileURL: url)
        playVM.playAudio()
    }
    
    // MARK: - TODO: can phai xu ly logic sau khi tron mang thi bai hat tiep theo hoac bai hat truoc do trung voi
    func getNextSong() -> String? {
        guard let currentIndex = currentIndex else { return nil}
        
        if currentIndex == (playlist?.songsArray.count ?? 1) - 1 {
            self.currentIndex = 0
        } else {
            self.currentIndex = currentIndex + 1
        }
        self.previousIndex = currentIndex
        return playlist?.songsArray[self.currentIndex ?? 0]
    }
    
    func getPeiviousSong() -> String? {
        guard let previousIndex = previousIndex else {
            if let currentIndex = currentIndex, currentIndex == 0 {
                self.currentIndex = (playlist?.songsArray.count ?? 1) - 1
                self.previousIndex = currentIndex - 1
                
            }
            return playlist?.songsArray[currentIndex ?? 0]
        }
        
        self.currentIndex = previousIndex
        if previousIndex == 0 {
            self.currentIndex = previousIndex
            self.previousIndex = (playlist?.songsArray.count ?? 1) - 1
        }
        return playlist?.songsArray[currentIndex ?? 0]
    }
    
    func shufflePlaylist() {
        let songArray: [String] = playlist?.songsArray.shuffled() ?? []
        playlist?.songsArray = songArray
    }
    
    func setUpSubscrip() {
        self.playVM?.currentTimePublisher.sink(receiveValue: { [weak self] newValue in
            
        })
        .store(in: &subscribs)
        
        self.playVM?.isPlayingPublisher.sink { [weak self] newValue in
            //self?.state.isPlaying = newValue
            // MARK: - TODO: can phai nghien cuu lai logic truyen duration cho thang view vi dinh bug phat nhac
        }
        .store(in: &subscribs)
        
        self.playVM?.didFishedPlayPublisher.sink { [weak self] didFinish in
            if didFinish {
                if let urlString = self?.getNextSong() {
                    self?.playSong(urlString: urlString)
                }
            } else {
                // handle logic in here
            }
        }
        .store(in: &subscribs)
    }
    
}

// MARK: - EXTENSION

extension PlaylistManager {
    static func provide(_ playViewModel: PlayViewModel) {
        PlaylistManager.shared.playVM = playViewModel
    }
}
