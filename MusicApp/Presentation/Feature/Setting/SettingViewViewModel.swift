//
//  SettingViewViewModel.swift
//  MusicApp
//
//  Created by Nhat on 9/25/23.
//  Refactored with Reducer pattern by Claude
//

import Foundation
import Combine
import SwiftUI

@MainActor
protocol SettingViewViewModelProtocol: ObservableObject {
    var state: SettingViewState { get }
    var pendingUploads: [String] { get set }
    func send(intent: SettingViewIntent)
    func isShowToastView() -> Binding<Bool>
}

/// SettingViewModel with Reducer pattern following EasyFax architecture
/// State updates are handled by the reducer, making state changes predictable and traceable
final class SettingViewViewModel: SettingViewViewModelProtocol {
    @Published private(set) var state: SettingViewState
    private var cancelBag: Set<AnyCancellable> = []

    // MARK: - Dependencies
    private let reducer: any SettingStateReducerProtocol
    let webUploaderUseCase: ManageWebUploaderUseCaseProtocol
    let uploadSongUseCase: UploadSongUseCaseProtocol
    let addSongUseCase: AddSongUseCaseProtocol
    private let deleteSongUseCase: DeleteSongUseCaseProtocol

    var pendingUploads: [String] = []

    // MARK: - Initialization
    init(
        state: SettingViewState = .init(),
        reducer: (any SettingStateReducerProtocol)? = nil,
        webUploaderUseCase: ManageWebUploaderUseCaseProtocol = ManageWebUploaderUseCase(),
        uploadSongUseCase: UploadSongUseCaseProtocol = UploadSongUseCase(),
        addSongUseCase: AddSongUseCaseProtocol = AddSongUseCase(),
        deleteSongUseCase: DeleteSongUseCaseProtocol = DeleteSongUseCase()
    ) {
        self.state = state
        self.reducer = reducer ?? SettingStateReducerImpl()
        self.webUploaderUseCase = webUploaderUseCase
        self.uploadSongUseCase = uploadSongUseCase
        self.addSongUseCase = addSongUseCase
        self.deleteSongUseCase = deleteSongUseCase

        // Populate app version from bundle
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        self.state.appVersion = "\(version) (\(build))"

        setupBindings()
    }

    // MARK: - Setup
    private func setupBindings() {
        // Web uploader state binding
        webUploaderUseCase.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .startSuccess(let ipAddress):
                    withAnimation {
                        self.state = self.reducer.reduce(self.state, with: .setServerOn(true, ipAddress: ipAddress))
                    }
                    Logger.info("Server started successfully at \(ipAddress)")

                case .stopSucesss:
                    withAnimation {
                        self.state = self.reducer.reduce(self.state, with: .setServerOn(false, ipAddress: nil))
                    }
                    Logger.info("Server stopped successfully")

                case .startFailed:
                    withAnimation {
                        self.state = self.reducer.reduce(self.state, with: .setShowToast(true, message: "Start server failed!"))
                    }
                    Logger.error("Failed to start server")

                case .stopFailed:
                    withAnimation {
                        self.state = self.reducer.reduce(self.state, with: .setShowToast(true, message: "Disconnect server failed!"))
                    }
                    Logger.error("Failed to stop server")

                case .alreadyRuning:
                    Logger.warning("Server already running")
                }
            }
            .store(in: &cancelBag)

        // Upload file binding
        uploadSongUseCase.uploadedFilePublisher
            .sink { [weak self] path in
                guard let self = self else { return }
                self.pendingUploads.append(path)
                Logger.debug("File uploaded: \(path)")
            }
            .store(in: &cancelBag)
    }

    // MARK: - Intent Handling
    func send(intent: SettingViewIntent) {
        Logger.debug("SettingViewModel.send() - Intent: \(intent)")

        switch intent {
        case .deleteAllSongs:
            state = reducer.reduce(state, with: .setShowDeleteConfirm(true))

        case .confirmDeleteAllSongs:
            deleteAllSongs()

        case .cancelDeleteAllSongs:
            state = reducer.reduce(state, with: .setShowDeleteConfirm(false))

        case .toggleServer:
            if state.isServerOn { stopServer() } else { startServer() }

        case .completedUploadSongs:
            handleCompletedUploads()

        case .rateApp:
            RateAppHelper.requestReview()

        case .shareApp:
            state = reducer.reduce(state, with: .setShowShareSheet(true))

        case .cancelShareSheet:
            state = reducer.reduce(state, with: .setShowShareSheet(false))

        case .openPrivacy:
            UIApplication.shared.open(SettingConstants.privacyURL)

        case .openTerms:
            UIApplication.shared.open(SettingConstants.termsURL)

        case .showLanguagePicker:
            Logger.debug("Language picker — will be wired in Phase 3")
        }
    }

    // MARK: - Private Methods
    private func startServer() {
        Logger.debug("Starting web server...")
        webUploaderUseCase.start()
    }

    private func stopServer() {
        Logger.debug("Stopping web server...")
        webUploaderUseCase.stop()
    }

    private func deleteAllSongs() {
        state = reducer.reduce(state, with: .setShowDeleteConfirm(false))
        Task {
            do {
                try await deleteSongUseCase.executeDeleteAll()
                await MainActor.run {
                    state = reducer.reduce(state, with: .setShowToast(true, message: "All songs deleted"))
                }
            } catch {
                Logger.error("Failed to delete all songs: \(error)")
                await MainActor.run {
                    state = reducer.reduce(state, with: .setShowToast(true, message: "Failed to delete songs"))
                }
            }
        }
    }

    private func handleCompletedUploads() {
        guard pendingUploads.count > 0 else { return }

        Task {
            Logger.info("Processing \(pendingUploads.count) uploaded files")

            do {
                try await addSongUseCase.executeList(from: pendingUploads)
                pendingUploads = []

                Logger.info("Successfully added all uploaded songs")
            } catch {
                Logger.error("Failed to add uploaded songs: \(error)")
            }
        }
    }

    // MARK: - Bindings
    func isShowToastView() -> Binding<Bool> {
        return .init {
            return self.state.isShowToastView
        } set: { newValue in
            if !newValue {
                // Use reducer to update state
                self.state = self.reducer.reduce(self.state, with: .setShowToast(false, message: ""))
            }
        }
    }
}
