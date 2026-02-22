//
//  DIContainer+ViewFactory.swift
//  MusicApp
//
//  Created by Claude
//

import SwiftUI

// MARK: - ViewFactory Implementation
extension DIContainer: ViewFactory {

    @MainActor
    @ViewBuilder
    public func view(for route: any Routable, router: any BaseRouterProtocol) -> some View {
        switch route {
        case let appRoute as AppRoute:
            handleAppRoute(appRoute, router)
        default:
            EmptyView()
        }
    }

    @MainActor
    @ViewBuilder
    private func handleAppRoute(_ route: AppRoute, _ router: any BaseRouterProtocol) -> some View {
        switch route {
        // Tab routes
        case .home:
            makeHomeView(router: router)

        case .library:
            makeLibraryView(router: router)

        case .transfer:
            makeTransferView(router: router)

        case .setting:
            makeSettingView(router: router)

        // Detail routes
        case .playlistDetail(let id):
            makePlaylistDetailView(id: id, router: router)

        case .nowPlaying:
            makeNowPlayingView(router: router)

        case .addNewPlaylist:
            makeAddNewPlaylistView(router: router)

        // Modal routes
        case .editPlaylist(let playlistId):
            makeEditPlaylistView(playlistId: playlistId, router: router)

        // Timer routes
        case .timerPicker:
            makeTimerPickerView(router: router)

        case .timerMenuSheet:
            makeTimerMenuSheetView(router: router)

        // Transfer routes
        case .transferAudio:
            makeTransferAudioView(router: router)
        }
    }
}

// MARK: - View Factory Methods
extension DIContainer {

    // MARK: - Tab Views
    @MainActor
    private func makeHomeView(router: any BaseRouterProtocol) -> some View {
        let viewModel = makeHomeViewModel()
        return HomeView(viewModel: viewModel, onPlaylistTap: { _ in })
            .environmentObject(router as? Router<AppRoute> ?? appRouter(for: router))
    }

    @MainActor
    private func makeLibraryView(router: any BaseRouterProtocol) -> some View {
        let viewModel = makeLibaryViewViewModel()
        return LibaryView(handler: viewModel)
            .environmentObject(router as? Router<AppRoute> ?? appRouter(for: router))
    }

    @MainActor
    private func makeTransferView(router: any BaseRouterProtocol) -> some View {
        let viewModel = makeTransferViewModel()
        return TransferView(viewModel: viewModel, navigationHandler: appRouter(for: router))
            .environmentObject(router as? Router<AppRoute> ?? appRouter(for: router))
    }

    @MainActor
    private func makeSettingView(router: any BaseRouterProtocol) -> some View {
        let viewModel = makeSettingViewModel()
        return SettingView(viewModel: viewModel)
            .environmentObject(router as? Router<AppRoute> ?? appRouter(for: router))
    }

    // MARK: - Detail Views
    @MainActor
    private func makePlaylistDetailView(id: UUID, router: any BaseRouterProtocol) -> some View {
        // TODO: Fetch playlist by ID
        let viewModel = makePlaylistDetailViewModel(playlist: nil)
        return PlaylistDetailView(viewModel: viewModel, router: appRouter(for: router))
            .environmentObject(router as? Router<AppRoute> ?? appRouter(for: router))
    }

    @MainActor
    private func makeNowPlayingView(router: any BaseRouterProtocol) -> some View {
        let viewModel = makeNowPlayingViewModel()
        return NowPlayingView(isExpanded: .constant(false), viewModel: viewModel)
            .environmentObject(router as? Router<AppRoute> ?? appRouter(for: router))
    }

    @MainActor
    private func makeAddNewPlaylistView(router: any BaseRouterProtocol) -> some View {
        let viewModel = makeAddNewPlaylistViewModel()
        return AddNewPlayListView(viewmodel: viewModel, router: appRouter(for: router))
            .environmentObject(router as? Router<AppRoute> ?? appRouter(for: router))
    }

    @MainActor
    private func makeEditPlaylistView(playlistId: UUID, router: any BaseRouterProtocol) -> some View {
        // TODO: Implement with proper data
        EmptyView()
            .environmentObject(router as? Router<AppRoute> ?? appRouter(for: router))
    }

    // MARK: - Timer Views
    @MainActor
    private func makeTimerPickerView(router: any BaseRouterProtocol) -> some View {
        let viewModel = TimerPickerViewModel()
        // Setup callbacks for NowPlayingViewModel integration
        viewModel.onSave = { hours, minutes, seconds in
            // Will be connected to NowPlayingViewModel
            Logger.debug("Timer saved: \(hours)h \(minutes)m \(seconds)s")
        }
        viewModel.onBack = {
            (router as? Router<AppRoute>)?.dismiss()
        }

        return TimerPickerView(viewModel: viewModel)
    }

    @MainActor
    private func makeTimerMenuSheetView(router: any BaseRouterProtocol) -> some View {
        let viewModel = TimerMenuViewModel()
        let appRouter = router as? Router<AppRoute>

        // Setup callbacks
        viewModel.onCancelSleepTime = {
            Logger.debug("Cancel sleep time")
            appRouter?.dismiss()
            // TODO: Connect to NowPlayingViewModel
        }

        viewModel.onNavigateToPicker = {
            appRouter?.dismiss()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
                appRouter?.route(to: .timerPicker)
            }
        }

        return SetupTimerSheetView(viewModel: viewModel)
    }

    // MARK: - Transfer Audio View
    @MainActor
    private func makeTransferAudioView(router: any BaseRouterProtocol) -> some View {
        let viewModel = makeTransferViewModel()
        return TransferView(viewModel: viewModel, navigationHandler: appRouter(for: router))
    }

    // MARK: - Helper
    @MainActor
    private func appRouter(for router: any BaseRouterProtocol) -> Router<AppRoute> {
        // Cast or get router from DIContainer
        return Router<AppRoute>()
    }
}

// MARK: - ViewModel Factory Methods (from AppDependencies)
extension DIContainer {

    // MARK: - Home
    @MainActor
    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(
            fetchPlaylistUseCase: useCases.fetchPlaylistUseCase,
            playerManager: PlayerManager.shared
        )
    }

    // MARK: - Library
    @MainActor
    func makeLibaryViewViewModel() -> LibaryViewViewModel {
        return LibaryViewViewModel(
            fetchPlaylistaUseCase: useCases.fetchPlaylistUseCase,
            deletePlaylistUseCase: useCases.deletePlaylistUseCase
        )
    }

    // MARK: - Transfer
    @MainActor
    func makeTransferViewModel() -> TransferViewModel {
        return TransferViewModel(
            uploadSongUseCase: useCases.uploadSongUseCase,
            transferUseCase: useCases.transferUseCase
        )
    }

    // MARK: - Setting
    @MainActor
    func makeSettingViewModel() -> SettingViewViewModel {
        return SettingViewViewModel(
            state: .init(),
            webUploaderUseCase: useCases.manageWebUploaderUseCase,
            uploadSongUseCase: useCases.uploadSongUseCase,
            addSongUseCase: useCases.addSongUseCase
        )
    }

    // MARK: - Playlist Detail
    @MainActor
    func makePlaylistDetailViewModel(playlist: Playlist?) -> PlaylistDetailViewModel {
        return PlaylistDetailViewModel(
            playlist: playlist,
            fetchSongUseCase: useCases.fetchSongUseCase,
            fetchPlaylistUseCase: useCases.fetchPlaylistUseCase
        )
    }

    // MARK: - Now Playing
    @MainActor
    func makeNowPlayingViewModel() -> NowPlayingViewModel {
        return NowPlayingViewModel(
            playerManager: PlayerManager.shared
        )
    }

    // MARK: - Add New Playlist
    @MainActor
    func makeAddNewPlaylistViewModel() -> AddNewPlaylistViewModel {
        return AddNewPlaylistViewModel(
            addPlaylistUseCase: useCases.addPlaylistUseCase
        )
    }
}

// MARK: - Player Manager Factory
extension DIContainer {
    func makePlayerManager() -> PlayerManager {
        return PlayerManager.shared
    }
}
