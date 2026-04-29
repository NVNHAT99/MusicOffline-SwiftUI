//
//  AudioEngineService.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/26/25.
//

import Foundation
import AVFoundation
import Combine

enum AudioEngineEvent {
    case finished(Bool)
}

protocol AudioEngineProtocol: AnyObject {
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var currentURL: URL? { get }
    var eventPublisher: AnyPublisher<AudioEngineEvent, Never> { get }

    func configureSessionIfNeeded() throws
    func load(url: URL) throws
    func play()
    func pause()
    func stop()
    func seek(to duration: Double)
}


final class AVAudioPlayerEngineService: NSObject, AudioEngineProtocol {
    
    static let shared = AVAudioPlayerEngineService()
    private override init() {
        super .init()
        do {
            try configureSessionIfNeeded()
        } catch {
            print(error)
        }
    }

    private var player: AVAudioPlayer?
    private(set) var currentURL: URL?

    // MARK: - Combine
    private let eventSubject = PassthroughSubject<AudioEngineEvent, Never>()
    var eventPublisher: AnyPublisher<AudioEngineEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    var isPlaying: Bool { player?.isPlaying ?? false }
    var currentTime: TimeInterval { player?.currentTime ?? 0 }
    
    func configureSessionIfNeeded() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true, options: [])
    }
    
    func load(url: URL) throws {
        guard url.isFileURL else {
            throw NSError(domain: "AudioEngine", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "URL must be a file URL"])
        }
        currentURL = url
        player = try AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        player?.prepareToPlay()
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func stop() {
        player?.stop()
        player?.currentTime = 0
    }
    
    func seek(to duration: Double) {
        guard let player else { return }
        
        // Clamp để tránh crash khi duration vượt ngoài range
        let clampedTime = max(0, min(duration, player.duration))
        player.currentTime = clampedTime
        
        // Nếu đang play thì tiếp tục play từ chỗ mới
        if isPlaying {
            player.play()
        }
    }
}

extension AVAudioPlayerEngineService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        eventSubject.send(.finished(flag))
    }
}
