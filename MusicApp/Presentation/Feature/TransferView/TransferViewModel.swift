//
//  TransferViewModel.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/2/25.
//
import Foundation
import Combine
import SwiftUI

final class TransferViewModel: ObservableObject {
    
    @Published private(set) var state: TransferViewState
    private var cancelBag: Set<AnyCancellable> = []
    
    private let webUploaderUseCase: ManageWebUploaderUseCaseProtocol
    private let uploadSongUseCase: UploadSongUseCaseProtocol
    private let transferUseCase: TransferUseCaseProtocol
    
    init(state: TransferViewState = .init(),
         webUploaderUseCase: ManageWebUploaderUseCaseProtocol = ManageWebUploaderUseCase(),
         uploadSongUseCase: UploadSongUseCaseProtocol = UploadSongUseCase(),
         transferUseCase: TransferUseCaseProtocol = TransferUseCase()) {
        self.state = state
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
                Task {
                    try await self?.transferUseCase.executeDelete(from: path)
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
                var newState = self.state
                newState.ipAdress = ipAddress
                newState.isServerOn = true
                self.state = newState
            }
        case .stopSucesss:
            withAnimation {
                var newState = self.state
                newState.ipAdress = nil
                newState.isServerOn = false
                self.state = newState
            }
        case .startFailed:
            var newState = self.state
            newState.isShowToastView = true
            newState.messageToastView = "Start server failed"
            self.state = newState
        case .stopFailed:
            var newState = self.state
            newState.isShowToastView = true
            newState.messageToastView = "Stop server failed"
            self.state = newState
        case .alreadyRuning:
            // TODO: Handle already running
            break
        }
    }
    
    func isShowToastView() -> Binding<Bool> {
        return .init {
            return self.state.isShowToastView
        } set: { newValue in
            self.state.isShowToastView = newValue
        }
        
    }
    
    func isShowUnSaveDialog() -> Binding<Bool> {
        return .init {
            return self.state.isShowForceSaveDialog
        } set: { newValue in
            self.state.isShowForceSaveDialog = newValue
        }
        
    }
    
    private func handleBackActionWithPendingChanges() async {
        await MainActor.run {
            self.state.isShowForceSaveDialog = true
        }
    }

    private func handleBackActionWithoutPendingChanges(_ navigationHandler: NavigationActionHandler) {
        webUploaderUseCase.stop()
        Task {
            await MainActor.run {
                navigationHandler.dismissView()
            }
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
                Task {
                    // TODO: need clear transfer context here
                    await MainActor.run {
                        navigationHandler.dismissView()
                    }
                }
            } else {
                Task {
                    await MainActor.run {
                        var newStatte = self.state
                        newStatte.showLoading = false
                        newStatte.isShowToastView = true
                        newStatte.messageToastView = "Your changes are still being saved. Please wait a moment."
                        self.state = newStatte
                    }
                }
            }
        case .copyIPAdress:
            UIPasteboard.general.string = state.ipAdress
        }
    }
}
