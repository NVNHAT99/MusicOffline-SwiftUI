import Foundation
import AVFoundation
import Combine

enum AudioEngineEvent {
    case finished(Bool)
}

protocol AudioEngineProtocol: AnyObject {
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var currentURL: URL? { get }
    var eventPublisher: AnyPublisher<AudioEngineEvent, Never> { get }

    func configureSessionIfNeeded() throws
    func load(url: URL) throws
    func play()
    func pause()
    func stop()
    func seek(to duration: Double)
}

final class AVAudioPlayerEngineService: AudioEngineProtocol {

    static let shared = AVAudioPlayerEngineService(
        eqService: EQService.shared,
        effectsService: AudioEffectsService.shared
    )

    private let engine      = AVAudioEngine()
    private let playerNode  = AVAudioPlayerNode()
    private let eqService: EQServiceProtocol
    private let effectsService: AudioEffectsServiceProtocol

    private var audioFile: AVAudioFile?
    private(set) var currentURL: URL?

    // Frame tracking for seek
    private var seekOffsetFrames: AVAudioFramePosition = 0
    private var sampleRate: Double = 44100

    // Bumped on every (re)schedule (load/seek). A segment's completion callback
    // only counts as a real end-of-track if no newer segment was scheduled after
    // it — this distinguishes a natural finish from a seek/new-song interruption
    // without relying on playerNode.isPlaying (which races at completion time).
    private var scheduleGeneration: Int = 0

    // True only while playback was suspended by a system interruption that the
    // engine itself paused (phone call, another app's audio). Auto-resume on
    // interruption-ended is gated on this so a USER pause (Control Center /
    // in-app) is never auto-resumed — which previously flipped the CC button
    // pause→play→pause and made resume impossible.
    private var wasInterruptedWhilePlaying = false

    private let eventSubject = PassthroughSubject<AudioEngineEvent, Never>()
    var eventPublisher: AnyPublisher<AudioEngineEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    var isPlaying: Bool { playerNode.isPlaying }

    var currentTime: TimeInterval {
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
            return Double(seekOffsetFrames) / sampleRate
        }
        return Double(seekOffsetFrames + playerTime.sampleTime) / sampleRate
    }

    var duration: TimeInterval {
        guard let file = audioFile else { return 0 }
        return Double(file.length) / file.processingFormat.sampleRate
    }

    init(eqService: EQServiceProtocol, effectsService: AudioEffectsServiceProtocol) {
        self.eqService = eqService
        self.effectsService = effectsService
        buildGraph()
        observeNotifications()
        do { try configureSessionIfNeeded() } catch { Logger.error("AudioSession setup failed: \(error)") }
    }

    // MARK: - Graph

    /// Chain: player → timePitch → reverb → eq → mainMixer.
    /// Effects nodes are attached up-front; runtime toggling uses `.bypass`
    /// so the engine never has to stop (avoids audible pops).
    private func buildGraph() {
        engine.attach(playerNode)
        engine.attach(effectsService.timePitchNode)
        engine.attach(effectsService.reverbNode)
        engine.attach(eqService.eqNode)

        engine.connect(playerNode,                  to: effectsService.timePitchNode, format: nil)
        engine.connect(effectsService.timePitchNode, to: effectsService.reverbNode,   format: nil)
        engine.connect(effectsService.reverbNode,    to: eqService.eqNode,            format: nil)
        engine.connect(eqService.eqNode,             to: engine.mainMixerNode,        format: nil)
    }

    private func startEngineIfNeeded() throws {
        guard !engine.isRunning else {
            return
        }
        try engine.start()
    }

    // MARK: - Protocol

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
        playerNode.stop()
        let file = try AVAudioFile(forReading: url)
        audioFile       = file
        currentURL      = url
        sampleRate      = file.processingFormat.sampleRate
        seekOffsetFrames = 0

        // Reconnect the whole chain with the file's native format to avoid SRC artifacts.
        engine.disconnectNodeInput(eqService.eqNode)
        engine.disconnectNodeInput(effectsService.reverbNode)
        engine.disconnectNodeInput(effectsService.timePitchNode)
        engine.disconnectNodeOutput(playerNode)

        let fmt = file.processingFormat
        engine.connect(playerNode,                  to: effectsService.timePitchNode, format: fmt)
        engine.connect(effectsService.timePitchNode, to: effectsService.reverbNode,   format: fmt)
        engine.connect(effectsService.reverbNode,    to: eqService.eqNode,            format: fmt)
        engine.connect(eqService.eqNode,             to: engine.mainMixerNode,        format: fmt)

        try startEngineIfNeeded()
        scheduleFile(from: 0)
    }

    func play() {
        guard audioFile != nil else { return }
        do {
            // Re-assert the audio session; iOS may have deactivated it while the
            // app was backgrounded, which makes playerNode.play() a silent no-op.
            try configureSessionIfNeeded()
        } catch {
            Logger.error("Audio session reactivate failed: \(error)")
        }
        do {
            try startEngineIfNeeded()
        } catch {
            Logger.error("Audio engine start failed: \(error)")
        }
        playerNode.play()
    }

    func pause() {
        playerNode.pause()
    }

    func stop() {
        playerNode.stop()
        seekOffsetFrames = 0
    }

    func seek(to time: Double) {
        guard let file = audioFile else { return }
        let wasPlaying = isPlaying
        playerNode.stop()

        let targetFrame = AVAudioFramePosition(time * sampleRate)
        let clampedFrame = max(0, min(targetFrame, file.length - 1))
        seekOffsetFrames = clampedFrame
        scheduleFile(from: clampedFrame)

        if wasPlaying {
            playerNode.play()
        }
    }

    // MARK: - Helpers

    private func scheduleFile(from startFrame: AVAudioFramePosition) {
        guard let file = audioFile else { return }
        let remaining = AVAudioFrameCount(file.length - startFrame)
        guard remaining > 0 else { return }

        scheduleGeneration += 1
        let generation = scheduleGeneration
        playerNode.scheduleSegment(
            file,
            startingFrame: startFrame,
            frameCount: remaining,
            at: nil,
            completionCallbackType: .dataPlayedBack
        ) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                // Only a genuine end-of-track: no newer segment scheduled since
                // (a seek or new song bumps the generation). Avoids the
                // playerNode.isPlaying race that could drop the finish event.
                guard self.scheduleGeneration == generation else { return }
                self.eventSubject.send(.finished(true))
            }
        }
    }

    // MARK: - Notifications

    private func observeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaServicesReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            // Remember whether WE were actually playing so we only auto-resume
            // an interruption we caused — never a user-initiated pause.
            wasInterruptedWhilePlaying = playerNode.isPlaying
            pause()
        case .ended:
            let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            // Only resume if the system says so AND the interruption is what
            // paused us. A Control Center / in-app user pause leaves
            // wasInterruptedWhilePlaying == false, so it stays paused.
            if options.contains(.shouldResume), wasInterruptedWhilePlaying {
                try? configureSessionIfNeeded()
                play()
            }
            wasInterruptedWhilePlaying = false
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .oldDeviceUnavailable {
            pause()
            eventSubject.send(.finished(false))
        }
    }

    @objc private func handleMediaServicesReset(_ notification: Notification) {
        engine.stop()
        buildGraph()
        try? configureSessionIfNeeded()
        if let url = currentURL {
            try? load(url: url)
        }
    }
}
