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
    let webUploaderUseCase: ManageWebUploaderUseCaseProtocol = ManageWebUploaderUseCase()
    let uploadSongUseCase: UploadSongUseCaseProtocol = UploadSongUseCase()
    let addSongUseCase: AddSongUseCaseProtocol = AddSongUseCase()
    
    init(state: TransferViewState = .init()) {
        self.state = state
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
        case .completedUploadSongs:
            break
        }
    }
}
