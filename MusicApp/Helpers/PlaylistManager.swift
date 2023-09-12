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
    private var currentIndex: Int?
    private var playVM: PlayViewModel?
    private var subscribs: Set<AnyCancellable> = []
    private(set) var stateRepeat: StateRepeat = .nomal
    private var currentSongInfo: SongInfo?
    private var timerTurnOff: Timer?
    
    static let shared: PlaylistManager = PlaylistManager()
    
    // MARK: - Passthrought Subjec
    let isPlayingPublisher = PassthroughSubject<Bool, Never>()
    let currentTimePublisher = PassthroughSubject<Double, Never>()
    let prepareNewSongPublisher = PassthroughSubject<SongInfo?, Never>()
    let stateRepeatPublisher = PassthroughSubject<StateRepeat, Never>()
    private init() {
        // o day can phai load lai data cua user truoc khi app duoc day xuong background
        // cac thuoc tinh can load nhu thoi gian phat cua bai hat truoc khi hat
        // trang thai lap lai playlist
        // co the luu tru playlistID va load lai khi mo app len
        
    }
    
    func updatePlaylist(playlist: Playlist?, currentIndex: Int) {
        if playlist?.wrappedId != self.playlist?.wrappedId {
            self.playlist = playlist
        }
        self.currentIndex = currentIndex
    }
    
    func playSong(urlString: String) {
        guard let playVM = playVM, let url = URL(string: urlString) else { return }
        prepearNewSong(urlString: urlString)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            playVM.prepareAudioToPlay(fileURL: url)
            playVM.playAudio()
        }
    }
    
    func playSong() {
        playVM?.playAudio()
    }
    
    func pause() {
        playVM?.pauseAudio()
    }
    
    func isPlaying() -> Bool {
        return playVM?.isPlaying() ?? false
    }
    
    func getStateRepeat() -> StateRepeat {
        return stateRepeat
    }
    
    func getCurrentTimePlay() -> Double {
        return playVM?.currentTimePlay() ?? 0
    }
    
    func playNextSong() {
        if let urlString = self.getNextSong() {
            self.playSong(urlString: urlString)
        }
    }
    
    func playPreviousSong() {
        if let urlString = self.getPreiviousSong() {
            self.playSong(urlString: urlString)
        }
    }
    
    func changeStateRepeat(state: StateRepeat) {
        switch state {
        case .shuffle:
            shufflePlaylist()
        default:
            break
        }
        playVM?.changeStateOfRepeat(state: state)
    }
    
    func setupTurnOff(time: Double) {
        timerTurnOff = Timer.scheduledTimer(withTimeInterval: time, repeats: false, block: { _ in
            self.pause()
        })
    }
    
    func getNextSong() -> String? {
        guard let currentIndex = currentIndex else { return nil}
        
        if currentIndex == (playlist?.songsArray.count ?? 1) - 1 {
            self.currentIndex = 0
        } else {
            self.currentIndex = currentIndex + 1
        }
        return playlist?.songsArray[self.currentIndex ?? 0]
    }
    
    func getPreiviousSong() -> String? {
        guard let currentIndex = currentIndex else { return nil }
        if currentIndex == 0 {
            self.currentIndex = (playlist?.songsArray.count ?? 0) - 1
        } else {
            self.currentIndex = currentIndex - 1
        }
        return playlist?.songsArray[self.currentIndex ?? 0]
    }
    
    func shufflePlaylist() {
        let songArray: [String] = playlist?.songsArray.shuffled() ?? []
        let newCurrentIndex = songArray.firstIndex(where: {$0 == playlist?.songsArray[currentIndex ?? 0]})
        playlist?.songsArray = songArray
        self.currentIndex = newCurrentIndex
    }
    
    func prepearNewSong(urlString: String) {
        Task {
            do {
                let songInfo = try await DocumentFileManager.shared.loadMetadata(url: URL(string: urlString)!)
                self.currentSongInfo = songInfo
                prepareNewSongPublisher.send(songInfo)
            } catch {
                print(error)
            }
        }
    }
    
    func getCurrentSongInfo() -> SongInfo? {
        return currentSongInfo
    }
    
    func setUpSubscrib() {
        // cho nay can thay doi lai gia tri cho state mac dinh cua playVM
        self.playVM?.currentTimePublisher.sink(receiveValue: { [weak self] newValue in
            self?.currentTimePublisher.send(newValue)
        })
        .store(in: &subscribs)
        
        self.playVM?.isPlayingPublisher.sink { [weak self] newValue in
            self?.isPlayingPublisher.send(newValue)
        }
        .store(in: &subscribs)
        
        self.playVM?.didFishedPlayPublisher.sink { [weak self] didFinish in
            if didFinish {
                self?.playNextSong()
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

// MARK: - TODO: can phai xu ly logic khi bac lai playlist binh thuong
// cach don gian nhat la luu tru mot mang array shuffle playlist tu sau do handle lai logic return nextsong vaf previous song
