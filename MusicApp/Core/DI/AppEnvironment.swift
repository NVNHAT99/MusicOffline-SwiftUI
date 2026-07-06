//
//  AppEnvironment.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation
import SwiftUI

/// App Environment following EasyFax pattern
/// Central container for all app dependencies and services
@MainActor
public final class AppEnvironment: ObservableObject {

    // MARK: - Properties
    public let diContainer: DIContainer
    public let systemEventsHandler: SystemEventsHandler
    public let appRouter: Router<AppRoute>

    // MARK: - Initialization
    public init(
        diContainer: DIContainer,
        systemEventsHandler: SystemEventsHandler,
        appRouter: Router<AppRoute>
    ) {
        self.diContainer = diContainer
        self.systemEventsHandler = systemEventsHandler
        self.appRouter = appRouter

        Logger.info("AppEnvironment initialized successfully")
    }

    // MARK: - Scene Phase Handling
    // App-open interstitial + Mobile Ads SDK start live in AppDelegate
    // (UIApplication.didBecomeActiveNotification), mirroring EZTranslate.
    public func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            Logger.info("📱 App entering background")
            systemEventsHandler.sceneDidEnterBackground()

        case .inactive:
            Logger.info("📱 App inactive")

        case .active:
            Logger.info("🚀 App becoming active")
            systemEventsHandler.sceneDidBecomeActive()

        @unknown default:
            Logger.warning("Unknown scene phase: \(phase)")
        }
    }
}

// MARK: - Bootstrap
extension AppEnvironment {

    /// Bootstrap the app environment with all dependencies
    /// This creates the entire object graph for the application
    public static func bootstrap() -> AppEnvironment {
        Logger.info("🚀 Bootstrapping AppEnvironment...")

        // 1. Create Services
        let services = DIContainer.Services.createDefault()
        Logger.debug("✅ Services created")

        // 2. Create Repositories
        let songRepository = SongRepository(coreData: services.coreDataManager)
        let playlistRepository = PlaylistRepository(coreDataService: services.coreDataManager)
        let songMetadataRepository = SongMetadataRepository()
        Logger.debug("✅ Repositories created")

        // 3. Create UseCases
        let useCases = DIContainer.UseCases.create(
            songRepository: songRepository,
            playlistRepository: playlistRepository,
            songMetadataRepository: songMetadataRepository,
            webServerService: services.webServerService,
            coreDataManager: services.coreDataManager
        )
        Logger.debug("✅ UseCases created")

        // 4. Create AppState
        let appState = AppState.shared
        Logger.debug("✅ AppState created")

        // 5. Create DIContainer
        let diContainer = DIContainer(
            appState: appState,
            useCases: useCases,
            services: services
        )
        Logger.debug("✅ DIContainer created")

        // 6. Create Router with DIContainer as factory
        let appRouter = Router<AppRoute>()
        appRouter.factory = diContainer
        Logger.debug("✅ Router created")

        // 7. Create SystemEventsHandler
        let systemEventsHandler = RealSystemEventsHandler(
            webServerService: services.webServerService,
            imageCacheManager: services.imageCacheManager
        )
        Logger.debug("✅ SystemEventsHandler created")

        // 8. Bind NowPlayingInfoService to PlayerManager
        services.nowPlayingInfoService.bind(to: PlayerManager.shared)
        Logger.debug("✅ NowPlayingInfoService bound to PlayerManager")

        // 9. Create AppEnvironment
        let environment = AppEnvironment(
            diContainer: diContainer,
            systemEventsHandler: systemEventsHandler,
            appRouter: appRouter
        )

        Logger.info("✨ AppEnvironment bootstrap completed successfully")

        // 9. Configure IAP + sync entitlement (fire-and-forget)
        Task { @MainActor in
            await IAPService.shared.configure()
        }

        // 10. Setup initial state
        Task { @MainActor in
            // Simulate initial loading check
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            appState.setLoading(false)
        }

        return environment
    }
}

// MARK: - Logger Extension for Module Support
extension Logger {
    static func debug(_ message: String, module: String) {
        debug("[\(module)] \(message)")
    }
}

// MARK: - SwiftUI Environment Key
struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment? = nil
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment? {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
