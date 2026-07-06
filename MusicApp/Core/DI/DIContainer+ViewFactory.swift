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

        // Smart Playlist
        case .smartPlaylistEditor(let id):
            makeSmartPlaylistEditorView(playlistId: id, router: router)

        // Equalizer
        case .equalizer:
            makeEqualizerView(router: router)

        // Audio Editor
        case .audioEditor(let sourceURL, let title):
            makeAudioEditorView(sourceURL: sourceURL, title: title)

        // URL Download
        case .urlDownload:
            UrlDownloadView()

        // Import Hub
        case .importHub:
            ImportHubView()

        // Paywall
        case .paywall:
            PaywallView()
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
        // Pass a stub playlist with just the ID — ViewModel fetches full data in loadPlaylist()
        let stub = Playlist(id: id, name: "", songIDs: [])
        let viewModel = makePlaylistDetailViewModel(playlist: stub)
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
        let viewModel = makeEditPlaylistViewModel(playlistId: playlistId)
        return EditPlaylistView(
            viewModel: viewModel,
            router: appRouter(for: router),
            isEditCompleted: .constant(false)
        )
        .environmentObject(appRouter(for: router))
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
            Task { await PlayerManager.shared.cancelScheduleStop() }
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

    // MARK: - Equalizer
    @MainActor
    private func makeEqualizerView(router: any BaseRouterProtocol) -> some View {
        let viewModel = EqualizerViewModel()
        return EqualizerView(viewModel: viewModel)
    }

    // MARK: - Audio Editor
    @MainActor
    private func makeAudioEditorView(sourceURL: URL, title: String) -> some View {
        let viewModel = AudioEditorViewModel(sourceURL: sourceURL, originalTitle: title)
        return AudioEditorView(viewModel: viewModel)
    }

    // MARK: - Smart Playlist Editor
    @MainActor
    private func makeSmartPlaylistEditorView(playlistId: UUID?, router: any BaseRouterProtocol) -> some View {
        let playlist: SmartPlaylist? = playlistId.flatMap { id in
            try? useCases.saveSmartPlaylistUseCase.fetchAll().first(where: { $0.id == id })
        }
        let viewModel = makeSmartPlaylistEditorViewModel(playlist: playlist)
        return SmartPlaylistEditorView(viewModel: viewModel)
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
        return (router as? Router<AppRoute>) ?? Router<AppRoute>()
    }
}

// MARK: - ViewModel Factory Methods
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
            deletePlaylistUseCase: useCases.deletePlaylistUseCase,
            saveSmartPlaylistUseCase: useCases.saveSmartPlaylistUseCase
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
            addSongUseCase: useCases.addSongUseCase,
            deleteSongUseCase: useCases.deleteSongUseCase
        )
    }

    // MARK: - Playlist Detail
    @MainActor
    func makePlaylistDetailViewModel(playlist: Playlist?) -> PlaylistDetailViewModel {
        return PlaylistDetailViewModel(
            playlist: playlist,
            fetchSongUseCase: useCases.fetchSongUseCase,
            fetchPlaylistUseCase: useCases.fetchPlaylistUseCase,
            updatePlaylistUseCase: useCases.updatePlaylistUseCase,
            reorderSongsUseCase: useCases.reorderPlaylistSongsUseCase
        )
    }

    @MainActor
    func makeImportSongViewModel() -> ImportSongViewModel {
        return ImportSongViewModel(importUseCase: useCases.importSongFromFilesUseCase)
    }

    // MARK: - Now Playing
    @MainActor
    func makeNowPlayingViewModel() -> NowPlayingViewModel {
        // Share one LyricsRepository across all three lyrics use cases so the in-memory
        // normalized-stem index stays consistent across the Import flow and the NowPlaying
        // Attach/Paste/Remove flow. Without this, each use case rebuilds its own index at
        // init time and a .lrc added by one flow is invisible to the others until app restart.
        let lyricsRepo = useCases.lyricsRepository
        return NowPlayingViewModel(
            playerManager: PlayerManager.shared,
            fetchLyricsUseCase: useCases.fetchLyricsUseCase,
            attachLyricsUseCase: AttachLyricsToSongUseCase(repository: lyricsRepo),
            removeLyricsUseCase: RemoveLyricsUseCase(repository: lyricsRepo)
        )
    }

    // MARK: - Add New Playlist
    @MainActor
    func makeAddNewPlaylistViewModel() -> AddNewPlaylistViewModel {
        return AddNewPlaylistViewModel(
            addPlaylistUseCase: useCases.addPlaylistUseCase
        )
    }

    // MARK: - Smart Playlist Editor
    @MainActor
    func makeSmartPlaylistEditorViewModel(playlist: SmartPlaylist? = nil) -> SmartPlaylistEditorViewModel {
        return SmartPlaylistEditorViewModel(
            playlist: playlist,
            saveUseCase: useCases.saveSmartPlaylistUseCase,
            matchUseCase: useCases.smartPlaylistUseCase
        )
    }

    // MARK: - Edit Playlist
    @MainActor
    func makeEditPlaylistViewModel(playlistId: UUID, currentSongIDs: [UUID] = []) -> EditPlaylistViewModel {
        return EditPlaylistViewModel(
            currenSongIDs: currentSongIDs,
            playlistID: playlistId,
            updatePlaylistUseCase: useCases.updatePlaylistUseCase,
            fetchSongUseCase: useCases.fetchSongUseCase
        )
    }
}

// MARK: - Player Manager Factory
extension DIContainer {
    func makePlayerManager() -> PlayerManager {
        return PlayerManager.shared
    }
}
