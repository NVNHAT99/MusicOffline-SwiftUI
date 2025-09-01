//
//  ProgressTimerService.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/29/25.
//

import Foundation
import Combine

protocol ProgressTimerServiceProtocol {
    var tickPublisher: AnyPublisher<TimeInterval, Never> { get }
    func start(interval: TimeInterval, from startValue: TimeInterval)
    func pause()
    func resume()
    func stop()
    func seek(to value: TimeInterval)
}

final class ProgressTimerService: ProgressTimerServiceProtocol {
    private var cancellable: AnyCancellable?
    private let tickSubject = PassthroughSubject<TimeInterval, Never>()
    var tickPublisher: AnyPublisher<TimeInterval, Never> {
        tickSubject.eraseToAnyPublisher()
    }

    private var elapsed: TimeInterval = 0
    private var interval: TimeInterval = 1.0
    private var isRunning = false

    // MARK: - Public API

    func start(interval: TimeInterval = 1.0, from startValue: TimeInterval = 0) {
        stop()
        self.interval = interval
        self.elapsed = startValue
        startTimer()
    }

    func pause() {
        guard isRunning else { return }
        cancellable?.cancel()
        cancellable = nil
        isRunning = false
    }

    func resume() {
        guard !isRunning else { return }
        startTimer()
    }

    func stop() {
        cancellable?.cancel()
        cancellable = nil
        elapsed = 0
        isRunning = false
    }

    func seek(to value: TimeInterval) {
        elapsed = value
        tickSubject.send(elapsed) // báo ngay giá trị mới
    }

    // MARK: - Private

    private func startTimer() {
        cancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsed += self.interval
                self.tickSubject.send(self.elapsed)
            }
        isRunning = true
    }
}
