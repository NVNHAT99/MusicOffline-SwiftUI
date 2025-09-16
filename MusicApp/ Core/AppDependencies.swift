//
//  AppDependencies.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 9/15/25.
//

import Foundation
import UIKit
import SwiftUI

// MARK: - App Dependencies Container
class AppDependencies {

    // MARK: - Singleton Instance
    static let shared = AppDependencies()

    // MARK: - Services
    private let imageCacheManager: ImageCacheManager
    private let audioEngineService: AVAudioPlayerEngineService
    private let coreDataManager: CoreDataManager
    private let playlistEventCenter: PlaylistEventCenter
    private let webServerService: WebServerGCDService
    private let userDataDefault: UserDataDefault
    private let helper: Helper
    private let nowPlayingService: NowPlayingInfoServiceProtocol

    // MARK: - Initialization
    private init() {
        // Initialize core services
        self.imageCacheManager = ImageCacheFactory.createDefaultCache()
        self.audioEngineService = AVAudioPlayerEngineService.shared
        self.coreDataManager = CoreDataManager.shared
        self.playlistEventCenter = PlaylistEventCenter.shared
        self.webServerService = WebServerGCDService.shared
        self.userDataDefault = UserDataDefault.shared
        self.helper = Helper.shared
        self.nowPlayingService = NowPlayingInfoService.shared

        // Setup lifecycle observers
        setupLifecycleObservers()
        self.nowPlayingService.bind(to: makePlayerManager())
    }

    // MARK: - Factory Methods
    func makeImageCache() -> ImageCacheProtocol {
        return imageCacheManager
    }

    func makeAudioEngine() -> AVAudioPlayerEngineService {
        return audioEngineService
    }

    func makeCoreDataManager() -> CoreDataProtocol {
        return coreDataManager
    }

    func makePlaylistEventCenter() -> PlaylistEventCenter {
        return playlistEventCenter
    }

    func makeWebServerService() -> WebServerGCDServiceProtocol {
        return webServerService
    }

    func makeUserDataDefault() -> UserDataDefault {
        return userDataDefault
    }

    func makeHelper() -> Helper {
        return helper
    }
    
    func makeNowPlayingService() -> NowPlayingInfoServiceProtocol {
        return nowPlayingService
    }

    // MARK: - Repository Factory Methods
    func makeSongRepository() -> SongRepositoryProtocol {
        return SongRepository(coreData: makeCoreDataManager())
    }

    func makePlaylistRepository() -> PlaylistRepositoryProtocol {
        return PlaylistRepository(coreDataService: makeCoreDataManager())
    }

    func makeSongMetadataRepository() -> SongMetadataRepositoryProtocol {
        return SongMetadataRepository()
    }

    func makeAddPlaylistUseCase() -> AddPlaylistUseCaseProtocol {
        return AddPlaylistUseCase(repository: makePlaylistRepository())
    }

    func makeCompletedUploadSongUseCase() -> CompletedUploadSongUseCaseProtocol {
        return CompletedUploadSongUseCase(repository: makeSongRepository(), songMetadataRepository: makeSongMetadataRepository())
    }

    func makeFetchHomeDataUseCase() -> FetchHomeDataUseCaseProtocol {
        return FetchHomeDataUseCase(fetchSongUseCase: makeFetchSongUseCase(), fetchPlaylistUseCase: makeFetchPlaylistUseCase())
    }

    func makeAudioImageRepository() -> AudioImageRepositoryProtocol {
        return AudioImageRepositoryImpl(cache: makeImageCache())
    }

    // MARK: - Use Case Factory Methods
    func makeFetchSongUseCase() -> FetchSongUseCaseProtocol {
        return FetchSongUseCase(repository: makeSongRepository())
    }

    func makeFetchPlaylistUseCase() -> FetchPlaylistUseCaseProtocol {
        return FetchPlaylistUseCase(repository: makePlaylistRepository())
    }

    func makeUpdatePlaylistUseCase() -> UpdatePlaylistUseCaseProtocol {
        return UpdatePlaylistUseCase(repository: makePlaylistRepository())
    }

    func makeDeletePlaylistUseCase() -> DeletetPlaylistUseCaseProtocol {
        return DeletetPlaylistUseCase(repository: makePlaylistRepository())
    }

    func makeDeleteSongUseCase() -> DeleteSongUseCaseProtocol {
        return DeleteSongUseCase(repository: makeSongRepository())
    }

    func makeAddSongUseCase() -> AddSongUseCaseProtocol {
        return AddSongUseCase(repository: makeSongRepository())
    }

    func makeUpdateSongUseCase() -> UpdateSongUseCaseProtocol {
        return UpdateSongUseCase(songRepository: makeSongRepository())
    }

    func makeTransferUseCase() -> TransferUseCaseProtocol {
        return TransferUseCase(
            addSongUseCase: makeAddSongUseCase(),
            updateSongUseCase: makeUpdateSongUseCase(),
            deleteSongUseCase: makeDeleteSongUseCase(),
            coreDataService: makeCoreDataManager(),
            repository: makePlaylistRepository()
        )
    }

    func makeManageWebUploaderUseCase() -> ManageWebUploaderUseCaseProtocol {
        return ManageWebUploaderUseCase(service: makeWebServerService())
    }

    func makeUploadSongUseCase() -> UploadSongUseCaseProtocol {
        return UploadSongUseCase(service: makeWebServerService())
    }

    // MARK: - Service Factory Methods
    func makePlayerManager() -> PlayerManager {
        return PlayerManager.shared
    }

    // MARK: - Cleanup
    func cleanup() {
//        // Clean up all managed resources
//        Task {
//            await imageCacheManager.clearAll()
//            audioEngineService.cleanup()
//            coreDataManager.cleanup()
//            webServerService.stopWebUploader()
//        }
    }

    // MARK: - Private Methods
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidEnterBackground()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillEnterForeground()
        }
    }

    private func handleMemoryWarning() {
        print("🗑️ Memory warning received in AppDependencies")
        Task {
            await imageCacheManager.clearMemory()
        }
    }

    func handleAppDidEnterBackground() {
        print("📱 App entered background, optimizing resources")
        Task {
            await imageCacheManager.clearMemory()
            // Add other background optimizations here
        }
    }

    func handleAppWillEnterForeground() {
        print("📱 App will enter foreground, preparing resources")
        // Add any foreground preparation here
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Convenience Extensions
extension AppDependencies {

    // MARK: - View Model Factory Methods
    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(
            playerManager: makePlayerManager()
        )
    }

    func makePlaylistDetailViewModel() -> PlaylistDetailViewModel {
        return PlaylistDetailViewModel(
            playlist: nil,
            fetchSongUseCase: makeFetchSongUseCase(),
            fetchPlaylistUseCase: makeFetchPlaylistUseCase()
        )
    }

    @MainActor
    func makeNowPlayingViewModel() -> NowPlayingViewModel {
        return NowPlayingViewModel(
            playerManager: makePlayerManager()
        )
    }

    func makeMainTabViewModel() -> MainTabViewVM {
        return MainTabViewVM(
            playerManager: makePlayerManager()
        )
    }

    func makeTransferViewModel() -> TransferViewModel {
        return TransferViewModel(
            uploadSongUseCase: makeUploadSongUseCase(),
            transferUseCase: makeTransferUseCase()
        )
    }

    @MainActor
    func makeLibaryViewViewModel() -> LibaryViewViewModel {
        return LibaryViewViewModel(
            fetchPlaylistaUseCase: makeFetchPlaylistUseCase(),
            deletePlaylistUseCase: makeDeletePlaylistUseCase()
        )
    }

    func makeSettingViewViewModel() -> SettingViewViewModel {
        return SettingViewViewModel()
    }
}

// MARK: - SwiftUI Environment Key
struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue = AppDependencies.shared
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
