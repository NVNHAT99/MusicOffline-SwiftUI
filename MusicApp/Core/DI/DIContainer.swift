//
//  DIContainer.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation
import SwiftUI

/// Dependency Injection Container following EasyFax pattern
/// Centralized container for all app dependencies
@MainActor
public final class DIContainer: ObservableObject {

    // MARK: - Properties
    public let appState: AppState
    public let useCases: UseCases
    public let services: Services

    // MARK: - Initialization
    public init(
        appState: AppState,
        useCases: UseCases,
        services: Services
    ) {
        self.appState = appState
        self.useCases = useCases
        self.services = services

        Logger.info("DIContainer initialized successfully")
    }
}

// MARK: - Services
extension DIContainer {

    public struct Services {
        // MARK: - Data Services
        let imageCacheManager: ImageCacheProtocol
        let coreDataManager: CoreDataProtocol
        let userDataDefault: UserDataDefault
        let helper: Helper

        // MARK: - Audio Services
        let audioEngineService: AVAudioPlayerEngineService
        let nowPlayingInfoService: NowPlayingInfoServiceProtocol

        // MARK: - Web Services
        let webServerService: WebServerGCDServiceProtocol

        // MARK: - Event Services
        let playlistEventCenter: PlaylistEventCenter

        // MARK: - Initialization
        init(
            imageCacheManager: ImageCacheProtocol,
            coreDataManager: CoreDataProtocol,
            userDataDefault: UserDataDefault,
            helper: Helper,
            audioEngineService: AVAudioPlayerEngineService,
            nowPlayingInfoService: NowPlayingInfoServiceProtocol,
            webServerService: WebServerGCDServiceProtocol,
            playlistEventCenter: PlaylistEventCenter
        ) {
            self.imageCacheManager = imageCacheManager
            self.coreDataManager = coreDataManager
            self.userDataDefault = userDataDefault
            self.helper = helper
            self.audioEngineService = audioEngineService
            self.nowPlayingInfoService = nowPlayingInfoService
            self.webServerService = webServerService
            self.playlistEventCenter = playlistEventCenter
        }

        /// Default initializer using singletons (for transition period)
        public static func createDefault() -> Services {
            return Services(
                imageCacheManager: ImageCacheFactory.createDefaultCache(),
                coreDataManager: CoreDataManager.shared,
                userDataDefault: UserDataDefault.shared,
                helper: Helper.shared,
                audioEngineService: AVAudioPlayerEngineService.shared,
                nowPlayingInfoService: NowPlayingInfoService.shared,
                webServerService: WebServerGCDService.shared,
                playlistEventCenter: PlaylistEventCenter.shared
            )
        }
    }
}

// UseCases extracted to DIContainer+UseCases.swift

// MARK: - Preview Helper
extension DIContainer {
    /// Convenience container for SwiftUI previews using real local services
    static var preview: DIContainer {
        let coreData = CoreDataManager.shared
        let webServer = WebServerGCDService.shared
        let songRepo = SongRepository(coreData: coreData)
        let playlistRepo = PlaylistRepository(coreDataService: coreData)
        let metaRepo = SongMetadataRepository()
        return DIContainer(
            appState: AppState.shared,
            useCases: DIContainer.UseCases.create(
                songRepository: songRepo,
                playlistRepository: playlistRepo,
                songMetadataRepository: metaRepo,
                webServerService: webServer,
                coreDataManager: coreData
            ),
            services: DIContainer.Services.createDefault()
        )
    }
}

// MARK: - SwiftUI Environment Key
struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer? = nil
}

extension EnvironmentValues {
    var diContainer: DIContainer? {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
