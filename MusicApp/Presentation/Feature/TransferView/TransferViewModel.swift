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
    
    let webUploaderUseCase: ManageWebUploaderUseCaseProtocol
    let uploadSongUseCase: UploadSongUseCaseProtocol
    let addSongUseCase: AddSongUseCaseProtocol
    private var addSongPaths: [String] = []
    
    init(state: TransferViewState = .init(),
         webUploaderUseCase: ManageWebUploaderUseCaseProtocol = ManageWebUploaderUseCase(),
         uploadSongUseCase: UploadSongUseCaseProtocol = UploadSongUseCase(),
         addSongUseCase: AddSongUseCaseProtocol = AddSongUseCase()) {
        self.state = state
        self.webUploaderUseCase = webUploaderUseCase
        self.uploadSongUseCase = uploadSongUseCase
        self.addSongUseCase = addSongUseCase
    }
    
    private func bindViewModel() {
        uploadSongUseCase.uploadedFilePublisher
            .sink { [weak self] path in
                guard let self = self else {
                    return
                }
                
                self.addSongPaths.append(path)
            }
            .store(in: &cancelBag)
        
        webUploaderUseCase.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                
                guard let self = self else {
                    return
                }
                
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
                    // show error
                    break
                case .stopFailed:
                    // show error
                    break
                case .alreadyRuning:
                    // break
                    break
                }
            }.store(in: &cancelBag)
    }
    
    func send(_ intent: TransferViewIntent) {
        switch intent {
        case .toggleServer:
            if self.state.isServerOn {
                webUploaderUseCase.stop()
            } else {
                webUploaderUseCase.start()
            }
        case .handleBacAction:
            // TODO: if user don't save songs, save all those file path to user default to save when user restart app
            webUploaderUseCase.stop()
        case .completedUploadSongs:
            self.state.showLoading = true
            Task {
                do {
                    try await self.addSongUseCase.excuteList(from: self.addSongPaths)
                    await MainActor.run {
                        self.state.showLoading = false
                    }
                } catch {
                    // TODO: need show error here
                    await MainActor.run {
                        self.state.showLoading = false
                    }
                }
                
            }
        case .copyIPAdress:
            UIPasteboard.general.string = self.state.ipAdress
        }
    }
}
