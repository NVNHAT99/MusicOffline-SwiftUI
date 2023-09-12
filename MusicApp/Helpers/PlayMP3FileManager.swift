//
//  PlayMP3FileManager.swift
//  MusicApp
//
//  Created by Nhat on 8/22/23.
//

import Foundation
import AVFoundation
import Combine

class PlayViewModel: NSObject, ObservableObject {
    // MARK: - PROPERTIES WRAPPER
    // o day can mot cai bien luu lai
    var stateRepeat: StateRepeat = .nomal
    // MARK: - PROPERTIES
    let currentTimePublisher = PassthroughSubject<Double, Never>()
    let isPlayingPublisher = PassthroughSubject<Bool, Never>()
    let didFishedPlayPublisher = PassthroughSubject<Bool, Never>()
    var timer: Timer?
    
    private var audioPlayer: AVAudioPlayer?
    
    override init() {
        super.init()
        configureAudioSession()
    }
    
    func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error configuring audio session: \(error)")
        }
    }
    
    func prepareAudioToPlay(fileURL: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            switch stateRepeat {
            case .nomal:
                audioPlayer?.numberOfLoops = 0
            case .repeatOne:
                audioPlayer?.numberOfLoops = -1
            case .shuffle:
                audioPlayer?.numberOfLoops = 0
            }
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error playing audio file \(error)")
        }
        
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else {
                return
            }
            currentTimePublisher.send(self.audioPlayer?.currentTime ?? 0)
        }
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
        timer?.invalidate()
        isPlayingPublisher.send(false)
    }
    
    func playAudio() {
        audioPlayer?.play()
        startTimer()
        isPlayingPublisher.send(true)
    }
    
    func isPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    func currentTimePlay() -> Double {
        return audioPlayer?.currentTime ?? 0
    }
    
    func changeStateOfRepeat(state: StateRepeat) {
        switch state {
        case .nomal, .shuffle:
            audioPlayer?.numberOfLoops = 0
        case .repeatOne:
            audioPlayer?.numberOfLoops = -1
        }
        stateRepeat = state
    }
    
    func duration() -> Double {
//        let formatter = DateComponentsFormatter()
//        formatter.allowedUnits = [.minute, .second]
//        formatter.unitsStyle = .positional
        return Double(audioPlayer?.duration ?? 0)
    }
}

extension PlayViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        timer?.invalidate()
        didFishedPlayPublisher.send(true)
    }
    
}


// MARK: - TODO: hay khoi tao mot class quan ly danh sach bai hat dang choi hien tai rieng biet so voi class playViewModel
