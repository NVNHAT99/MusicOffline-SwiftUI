//
//  PlaylistManager.swift
//  MusicApp
//
//  Created by Nhat on 9/5/23.
//

import Foundation
import Combine
import CoreData

final class PlaylistManager: ObservableObject {
    // MARK: - PROPERTIES
    private var playlist: Playlist?
    private var currentIndex: Int?
    private var playVM: PlayViewModel?
    private var subscribs: Set<AnyCancellable> = []
    private(set) var stateRepeat: StateRepeat = .nomal
    private var currentSongInfo: SongInfo?
    private var timerTurnOff: Timer?
    private var playlistShuffle: Playlist?
    
    static let shared: PlaylistManager = PlaylistManager()
    
    // MARK: - Passthrought Subjec
    let isPlayingPublisher = PassthroughSubject<Bool, Never>()
    let isPlayAudioFailed = PassthroughSubject<Bool, Never>()
    let currentTimePublisher = PassthroughSubject<Double, Never>()
    let prepareNewSongPublisher = PassthroughSubject<SongInfo?, Never>()
    let stateRepeatPublisher = PassthroughSubject<StateRepeat, Never>()
    private init() {
        loadLastUserData()
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
        isPlayingPublisher.send(false)
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
        } else {
            returnEmptySong()
        }
    }
    
    func playPreviousSong() {
        if let urlString = self.getPreiviousSong() {
            self.playSong(urlString: urlString)
        } else {
            returnEmptySong()
        }
    }
    
    func changeStateRepeat(state: StateRepeat) {
        switch state {
        case .shuffle:
            shufflePlaylist()
        default:
            break
        }
        self.stateRepeat = state
        playVM?.changeStateOfRepeat(state: state)
    }
    
    func setupTurnOff(time: Double) {
        timerTurnOff = Timer.scheduledTimer(withTimeInterval: time, repeats: false, block: { _ in
            self.pause()
        })
    }
    
    func changeCurrentTimePlay(newTime: Double) {
        playVM?.changeCurrentTimePlay(newTime: newTime)
    }
    
    func getNextSong() -> String? {
        guard let currentIndex = currentIndex, (playlist?.songsArray.count ?? 0) > 0 else { return nil}
        
        if currentIndex == (playlist?.songsArray.count ?? 1) - 1 {
            self.currentIndex = 0
        } else {
            self.currentIndex = currentIndex + 1
        }
        
        return stateRepeat == .shuffle ? playlistShuffle?.songsArray[self.currentIndex ?? 0] : playlist?.songsArray[self.currentIndex ?? 0]
    }
    
    func getPreiviousSong() -> String? {
        guard let currentIndex = currentIndex, (playlist?.songsArray.count ?? 0) > 0 else { return nil }
        if currentIndex == 0 {
            self.currentIndex = (playlist?.songsArray.count ?? 0) - 1
        } else {
            self.currentIndex = currentIndex - 1
        }
        return stateRepeat == .shuffle ? playlistShuffle?.songsArray[self.currentIndex ?? 0] : playlist?.songsArray[self.currentIndex ?? 0]
    }
    
    func shufflePlaylist() {
        let songArray: [String] = playlist?.songsArray.shuffled() ?? []
        let newCurrentIndex = songArray.firstIndex(where: {$0 == playlist?.songsArray[currentIndex ?? 0]})
        self.playlistShuffle = playlist
        self.playlistShuffle?.songsArray = songArray
        self.currentIndex = newCurrentIndex
    }
    
    func updateAffterDeletePlaylist(playlist: Playlist?) {
        if playlist?.id == self.playlist?.id {
            self.playlist = nil
        }
    }
    
    func getCurrentSongInfo() -> SongInfo? {
        if currentSongInfo == nil {
            returnEmptySong()
        }
        
        return currentSongInfo
    }
    
    func setUpSubscrib() {
        let currentTimePlay = UserDefaults.standard.double(forKey: "currentTimePlay")
        if let urlString = playlist?.songsArray[self.currentIndex ?? 0], let url = URL(string: urlString) {
            prepearNewSong(urlString: urlString)
            playVM?.prepareAudioToPlay(fileURL: url)
            changeCurrentTimePlay(newTime: currentTimePlay)
            
        }
        self.playVM?.changeStateOfRepeat(state: stateRepeat)
        self.playVM?.currentTimePublisher.sink(receiveValue: { [weak self] newValue in
            self?.currentTimePublisher.send(newValue)
        })
        .store(in: &subscribs)
        
        // MARK: - TODO: can handle logic neu nhu chi lap lai het mot playlist thi dung
        self.playVM?.didFishedPlayPublisher.sink { [weak self] didFinish in
            if didFinish {
                self?.playNextSong()
            }
        }
        .store(in: &subscribs)
    }
    
    private func prepearNewSong(urlString: String) {
        Task {
            do {
                let songInfo = try await DocumentFileManager.shared.loadMetadata(stringURL: urlString)
                self.currentSongInfo = songInfo
                prepareNewSongPublisher.send(songInfo)
                currentTimePublisher.send(0)
            } catch {
                print(error)
            }
        }
    }
    
    private func returnEmptySong() {
        playVM?.pauseAudio()
        prepearNewSong(urlString: String.empty)
        isPlayingPublisher.send(false)
        isPlayAudioFailed.send(true)
    }
    
    private  func loadLastStateRepeat() {
        if let data = UserDefaults.standard.string(forKey: "stateRepeat") {
            switch data {
            case StateRepeat.nomal.rawValue:
                stateRepeat = .nomal
            case StateRepeat.repeatOne.rawValue:
                stateRepeat = .repeatOne
            case StateRepeat.shuffle.rawValue:
                stateRepeat = .shuffle
            default:
                stateRepeat = .nomal
            }
        }
    }
    
    private func loadLastInfoPlaylist() {
        if let wrapId = UserDefaults.standard.string(forKey: "playlistId") {
            do {
                let fetchRequest: NSFetchRequest<Playlist> = Playlist.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", wrapId)
                fetchRequest.fetchLimit = 1
                let context = PersistenceController.shared.viewContext
                let results = try context.fetch(fetchRequest)
                
                if let playlist = results.first {
                    self.playlist = playlist
                } else {
                    // Playlist not found
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func loadLastCurrentIndex() {
        if let currentURL = UserDefaults.standard.string(forKey: "currentURL") {
            self.currentIndex = playlist?.songsArray.firstIndex(where: {$0 == currentURL})
        }
    }
    
    private func loadLastUserData() {
        loadLastStateRepeat()
        loadLastInfoPlaylist()
        loadLastCurrentIndex()
        if stateRepeat == .shuffle {
            shufflePlaylist()
        }
    }
    
    func saveLastdataUser() {
        if let currentIndex = currentIndex {
            UserDefaults.standard.set(playlist?.songsArray[currentIndex], forKey: "currentURL")
        }
        UserDefaults.standard.set(getCurrentTimePlay(), forKey: "currentTimePlay")
        UserDefaults.standard.set(playlist?.wrappedId, forKey: "playlistId")
        UserDefaults.standard.set(stateRepeat.rawValue, forKey: "stateRepeat")
    }
    
    func getPlaylist() -> Playlist? {
        return playlist
    }
    
    func sendCurrentStatePlay() {
        isPlayingPublisher.send(playVM?.isPlaying() ?? false)
    }
}

// MARK: - EXTENSION

extension PlaylistManager {
    static func provide(_ playViewModel: PlayViewModel) {
        PlaylistManager.shared.playVM = playViewModel
    }
}
