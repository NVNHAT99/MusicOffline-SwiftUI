//
//  GCDTimerService.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/26/25.
//

import Foundation

protocol TimerServiceProtocol: AnyObject {
    func schedule(after seconds: TimeInterval, _ block: @escaping () -> Void)
    func cancel()
}

final class GCDTimerService: TimerServiceProtocol {
    private var timer: DispatchSourceTimer?

    func schedule(after seconds: TimeInterval, _ block: @escaping () -> Void) {
        cancel()
        let t = DispatchSource.makeTimerSource()
        t.schedule(deadline: .now() + seconds)
        t.setEventHandler(handler: block)
        t.resume()
        timer = t
    }

    func cancel() {
        timer?.cancel()
        timer = nil
    }
}

