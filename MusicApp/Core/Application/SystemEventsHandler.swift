//
//  SystemEventsHandler.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Protocol defining system events handling
public protocol SystemEventsHandler {
    func sceneDidBecomeActive()
    func sceneWillResignActive()
    func sceneDidEnterBackground()
    func sceneWillEnterForeground()
}

/// Real implementation of SystemEventsHandler
public final class RealSystemEventsHandler: SystemEventsHandler {
    private let webServerService: WebServerGCDServiceProtocol
    private let imageCacheManager: ImageCacheProtocol

    init(
        webServerService: WebServerGCDServiceProtocol,
        imageCacheManager: ImageCacheProtocol
    ) {
        self.webServerService = webServerService
        self.imageCacheManager = imageCacheManager
    }

    public func sceneDidBecomeActive() {
        Logger.debug("Scene did become active", module: "SystemEvents")

        Task { @MainActor in
            // Prepare resources
        }
    }

    public func sceneWillResignActive() {
        Logger.debug("Scene will resign active", module: "SystemEvents")

        // Stop the unauthenticated upload server as soon as the app stops being
        // active (control center, incoming call, app switcher) — not only when
        // it is fully backgrounded — so it never lingers on Wi-Fi unattended.
        webServerService.stopWebUploader()
    }

    public func sceneDidEnterBackground() {
        Logger.debug("Scene did enter background", module: "SystemEvents")

        // Stop web server when app goes to background
        webServerService.stopWebUploader()

        // Clear memory cache
        imageCacheManager.clearMemory()

        Logger.info("Background optimizations completed")
    }

    public func sceneWillEnterForeground() {
        Logger.debug("Scene will enter foreground", module: "SystemEvents")

        Task { @MainActor in
            // Prepare resources for foreground
        }
    }
}

