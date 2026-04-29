//
//  TransferViewModel.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/2/25.
//
import Foundation
import Combine
import SwiftUI

@MainActor
protocol TransferViewModelProtocol: ObservableObject {
    var state: TransferViewState { get }
    func send(_ intent: TransferViewIntent)
    func isShowToastView() -> Binding<Bool>
    func isShowUnSaveDialog() -> Binding<Bool>
}

final class TransferViewModel: TransferViewModelProtocol {

    @Published private(set) var state: TransferViewState
    private let reducer: any TransferStateReducerProtocol
    private var cancelBag: Set<AnyCancellable> = []
    private var isNeedDissmis: Bool = false
    private let webUploaderUseCase: ManageWebUploaderUseCaseProtocol
    private let uploadSongUseCase: UploadSongUseCaseProtocol
    private let transferUseCase: TransferUseCaseProtocol

    init(
        state: TransferViewState = .init(),
        reducer: any TransferStateReducerProtocol = TransferStateReducerImpl(),
        webUploaderUseCase: ManageWebUploaderUseCaseProtocol = ManageWebUploaderUseCase(),
        uploadSongUseCase: UploadSongUseCaseProtocol = UploadSongUseCase(),
        transferUseCase: TransferUseCaseProtocol = TransferUseCase()
    ) {
        self.state = state
        self.reducer = reducer
        self.webUploaderUseCase = webUploaderUseCase
        self.uploadSongUseCase = uploadSongUseCase
        self.transferUseCase = transferUseCase
        bindViewModel()
    }

    private func bindViewModel() {

        // Track uploaded files
        uploadSongUseCase.uploadedFilePublisher
            .sink { [weak self] path in
                Task {
                    try await self?.transferUseCase.executeAdd(by: path)
                }
            }
            .store(in: &cancelBag)

        // Handle web uploader state changes
        webUploaderUseCase.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.handleWebUploaderState(result)
            }
            .store(in: &cancelBag)

        // Track deleted files
        uploadSongUseCase.deletedFilePublisher
            .sink { [weak self] path in
                guard let self = self else { return }
                Task {
                    try await self.transferUseCase.executeDelete(from: path)
                }
            }
            .store(in: &cancelBag)

        // Track updated file paths
        uploadSongUseCase.updatePathFilePublisher
            .sink { [weak self] (oldPath, newPath) in
                Task {
                    try await self?.transferUseCase.executeUpdate(from: oldPath, to: newPath)
                }
            }
            .store(in: &cancelBag)
    }

    private func handleWebUploaderState(_ result: WebLoaderResult) {
        switch result {
        case .startSuccess(ipAddress: let ipAddress):
            withAnimation {
                state = reducer.reduce(state, with: .setServerOn(true, ipAddress: ipAddress))
            }
        case .stopSucesss:
            withAnimation {
                state = reducer.reduce(state, with: .setServerOn(false, ipAddress: nil))
            }
        case .startFailed:
            state = reducer.reduce(state, with: .setShowToast(true, message: "Start server failed"))
        case .stopFailed:
            state = reducer.reduce(state, with: .setShowToast(true, message: "Stop server failed"))
        case .alreadyRuning:
            // TODO: Handle already running
            break
        }
    }

    func isShowToastView() -> Binding<Bool> {
        return .init {
            return self.state.isShowToastView
        } set: { newValue in
            self.state = self.reducer.reduce(self.state, with: .setShowToast(newValue, message: self.state.messageToastView))
        }
    }

    func isShowUnSaveDialog() -> Binding<Bool> {
        return .init {
            return self.state.isShowForceSaveDialog
        } set: { newValue in
            self.state = self.reducer.reduce(self.state, with: .setShowForceSaveDialog(newValue))
        }
    }

    private func handleBackActionWithPendingChanges() async {
        await MainActor.run {
            self.state = self.reducer.reduce(self.state, with: .setShowForceSaveDialog(true))
        }
    }

    func send(_ intent: TransferViewIntent) {
        switch intent {
        case .toggleServer:
            if state.isServerOn {
                webUploaderUseCase.stop()
            } else {
                webUploaderUseCase.start()
            }

        case .handleBackAction(let navigationHandler):
            if transferUseCase.isAllTaskDone() {
                webUploaderUseCase.stop()
                Task {
                    await MainActor.run {
                        navigationHandler.dismiss()
                    }
                }
            } else {
                Task {
                    await MainActor.run {
                        state = reducer.reduce(state, with: .setShowLoading(false))
                        state = reducer.reduce(state, with: .setShowToast(true, message: "Your changes are still being saved. Please wait a moment."))
                    }
                }
            }
        case .copyIPAdress:
            UIPasteboard.general.string = state.ipAdress
            state = reducer.reduce(state, with: .setShowToast(true, message: "URL copied to clipboard"))
        }
    }
}
