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

// MARK: - UseCases
extension DIContainer {

    public struct UseCases {
        // MARK: - Song UseCases
        let fetchSongUseCase: FetchSongUseCaseProtocol
        let addSongUseCase: AddSongUseCaseProtocol
        let updateSongUseCase: UpdateSongUseCaseProtocol
        let deleteSongUseCase: DeleteSongUseCaseProtocol
        let songMetadataRepository: SongMetadataRepositoryProtocol
        let completedUploadSongUseCase: CompletedUploadSongUseCaseProtocol

        // MARK: - Playlist UseCases
        let fetchPlaylistUseCase: FetchPlaylistUseCaseProtocol
        let addPlaylistUseCase: AddPlaylistUseCaseProtocol
        let updatePlaylistUseCase: UpdatePlaylistUseCaseProtocol
        let deletePlaylistUseCase: DeletetPlaylistUseCaseProtocol

        // MARK: - Composite UseCases
        let fetchHomeDataUseCase: FetchHomeDataUseCaseProtocol
        let transferUseCase: TransferUseCaseProtocol

        // MARK: - Upload UseCases
        let uploadSongUseCase: UploadSongUseCaseProtocol
        let manageWebUploaderUseCase: ManageWebUploaderUseCaseProtocol

        // MARK: - Initialization
        init(
            fetchSongUseCase: FetchSongUseCaseProtocol,
            addSongUseCase: AddSongUseCaseProtocol,
            updateSongUseCase: UpdateSongUseCaseProtocol,
            deleteSongUseCase: DeleteSongUseCaseProtocol,
            songMetadataRepository: SongMetadataRepositoryProtocol,
            completedUploadSongUseCase: CompletedUploadSongUseCaseProtocol,
            fetchPlaylistUseCase: FetchPlaylistUseCaseProtocol,
            addPlaylistUseCase: AddPlaylistUseCaseProtocol,
            updatePlaylistUseCase: UpdatePlaylistUseCaseProtocol,
            deletePlaylistUseCase: DeletetPlaylistUseCaseProtocol,
            fetchHomeDataUseCase: FetchHomeDataUseCaseProtocol,
            transferUseCase: TransferUseCaseProtocol,
            uploadSongUseCase: UploadSongUseCaseProtocol,
            manageWebUploaderUseCase: ManageWebUploaderUseCaseProtocol
        ) {
            self.fetchSongUseCase = fetchSongUseCase
            self.addSongUseCase = addSongUseCase
            self.updateSongUseCase = updateSongUseCase
            self.deleteSongUseCase = deleteSongUseCase
            self.songMetadataRepository = songMetadataRepository
            self.completedUploadSongUseCase = completedUploadSongUseCase
            self.fetchPlaylistUseCase = fetchPlaylistUseCase
            self.addPlaylistUseCase = addPlaylistUseCase
            self.updatePlaylistUseCase = updatePlaylistUseCase
            self.deletePlaylistUseCase = deletePlaylistUseCase
            self.fetchHomeDataUseCase = fetchHomeDataUseCase
            self.transferUseCase = transferUseCase
            self.uploadSongUseCase = uploadSongUseCase
            self.manageWebUploaderUseCase = manageWebUploaderUseCase
        }

        /// Create UseCases from repositories (default implementation)
        static func create(
            songRepository: SongRepositoryProtocol,
            playlistRepository: PlaylistRepositoryProtocol,
            songMetadataRepository: SongMetadataRepositoryProtocol,
            webServerService: WebServerGCDServiceProtocol,
            coreDataManager: CoreDataProtocol
        ) -> UseCases {
            // Song UseCases
            let fetchSongUseCase = FetchSongUseCase(repository: songRepository)
            let addSongUseCase = AddSongUseCase(repository: songRepository)
            let updateSongUseCase = UpdateSongUseCase(songRepository: songRepository)
            let deleteSongUseCase = DeleteSongUseCase(repository: songRepository)
            let completedUploadSongUseCase = CompletedUploadSongUseCase(
                repository: songRepository,
                songMetadataRepository: songMetadataRepository
            )

            // Playlist UseCases
            let fetchPlaylistUseCase = FetchPlaylistUseCase(repository: playlistRepository)
            let addPlaylistUseCase = AddPlaylistUseCase(repository: playlistRepository)
            let updatePlaylistUseCase = UpdatePlaylistUseCase(repository: playlistRepository)
            let deletePlaylistUseCase = DeletetPlaylistUseCase(repository: playlistRepository)

            // Composite UseCases
            let fetchHomeDataUseCase = FetchHomeDataUseCase(
                fetchSongUseCase: fetchSongUseCase,
                fetchPlaylistUseCase: fetchPlaylistUseCase
            )

            let transferUseCase = TransferUseCase(
                addSongUseCase: addSongUseCase,
                updateSongUseCase: updateSongUseCase,
                deleteSongUseCase: deleteSongUseCase,
                coreDataService: coreDataManager,
                repository: playlistRepository
            )

            // Upload UseCases
            let uploadSongUseCase = UploadSongUseCase(service: webServerService)
            let manageWebUploaderUseCase = ManageWebUploaderUseCase(service: webServerService)

            return UseCases(
                fetchSongUseCase: fetchSongUseCase,
                addSongUseCase: addSongUseCase,
                updateSongUseCase: updateSongUseCase,
                deleteSongUseCase: deleteSongUseCase,
                songMetadataRepository: songMetadataRepository,
                completedUploadSongUseCase: completedUploadSongUseCase,
                fetchPlaylistUseCase: fetchPlaylistUseCase,
                addPlaylistUseCase: addPlaylistUseCase,
                updatePlaylistUseCase: updatePlaylistUseCase,
                deletePlaylistUseCase: deletePlaylistUseCase,
                fetchHomeDataUseCase: fetchHomeDataUseCase,
                transferUseCase: transferUseCase,
                uploadSongUseCase: uploadSongUseCase,
                manageWebUploaderUseCase: manageWebUploaderUseCase
            )
        }
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
