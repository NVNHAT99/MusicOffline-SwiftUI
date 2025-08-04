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
    private var updateURLSongPaths: [String : String] = [:]
    private var deletedSongPaths: [String] = []
    
    init(state: TransferViewState = .init(),
         webUploaderUseCase: ManageWebUploaderUseCaseProtocol = ManageWebUploaderUseCase(),
         uploadSongUseCase: UploadSongUseCaseProtocol = UploadSongUseCase(),
         addSongUseCase: AddSongUseCaseProtocol = AddSongUseCase()) {
        self.state = state
        self.webUploaderUseCase = webUploaderUseCase
        self.uploadSongUseCase = uploadSongUseCase
        self.addSongUseCase = addSongUseCase
        bindViewModel()
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
        
        uploadSongUseCase.deletedFilePublisher
            .sink { path in
                // TODO: Missing case in here
                // have to case here, user deleted file just upload an this file don't save to core data
                self.addSongPaths.removeAll(where: { $0 == path })
                
                // case old file and have record in core data
                // case if file have move and then deleted, should check and remove from upate path and update to remove path
                // case if file just have been remove -> add remove path
            }
            .store(in: &cancelBag)
        
        uploadSongUseCase.updatePathFilePublisher
            .sink { [weak self] (oldPath, newPath) in
                guard let self = self else {
                    return
                }
                // Case if add paths now container for old path, -> update to save to core data
                if let indexOldPath = self.addSongPaths.firstIndex(where: { $0 == oldPath }) {
                    self.addSongPaths[indexOldPath] = newPath
                } else {
                    // otherwise add to update path to update song in core data
                    // but in here we have two case
                    // case 1: this path is move second time
                    if let key = self.updateURLSongPaths.first(where: { $0.value == oldPath })?.key {
                        if newPath == key {
                            // this case for user move file form a -> b but finally file move back to a, so we need to remove this file to do not update to core data song entity
                            updateURLSongPaths.removeValue(forKey: key)
                        } else {
                            // case new path for upate ( a-> b -> save to dictionary -> and then move to c )
                            updateURLSongPaths[key] = newPath
                        }
                    } else {
                        // this first time this file have been move
                        updateURLSongPaths[oldPath] = newPath
                    }
                }
            }
            .store(in: &cancelBag)
    }
    
    func send(_ intent: TransferViewIntent) {
        switch intent {
        case .toggleServer:
            if self.state.isServerOn {
                webUploaderUseCase.stop()
            } else {
                webUploaderUseCase.start()
            }
        case .handleBackAction(let navigationHandler):
            if !self.addSongPaths.isEmpty || !self.updateURLSongPaths.isEmpty {
                DispatchQueue.main.async {
                    var newState = self.state
                    newState.isShowToastView = true
                    newState.messageToastView = "You need to save all changes before going back to the home screen!"
                    self.state = newState
                }
            } else {
                webUploaderUseCase.stop()
                Task {
                    await MainActor.run {
                        navigationHandler.dismissView()
                    }
                }
            }
        case .completedUploadSongs:
            // TODO: need handle case change url file path
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
    
    func isShowToastView() -> Binding<Bool> {
        return .init {
            return self.state.isShowToastView
        } set: { newValue in
            self.state.isShowToastView = newValue
        }

    }
}
