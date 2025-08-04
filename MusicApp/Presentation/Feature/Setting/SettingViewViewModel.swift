//
//  SettingViewViewModel.swift
//  MusicApp
//
//  Created by Nhat on 9/25/23.
//

import Foundation
import Combine
import SwiftUI

final class SettingViewViewModel: ObservableObject {
    @Published private(set) var state: SettingViewState
    private var cancelBag: Set<AnyCancellable> = []
    let webUploaderUseCase: ManageWebUploaderUseCaseProtocol = ManageWebUploaderUseCase()
    let uploadSongUseCase: UploadSongUseCaseProtocol = UploadSongUseCase()
    let addSongUseCase: AddSongUseCaseProtocol = AddSongUseCase()
    
    var pendingUploads: [String] = []
    
    init(state: SettingViewState = .init()) {
        self.state = state
        
        webUploaderUseCase.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                
                guard let self = self else {
                    return
                }
                
                switch result {
                case .startSuccess(let ipAddress):
                    withAnimation {
                        var coppyState = self.state
                        coppyState.ipAdress = ipAddress
                        coppyState.isServerOn = true
                        self.state = coppyState
                    }
                case .stopSucesss:
                    withAnimation {
                        self.state.isServerOn = false
                    }
                case .startFailed:
                    withAnimation {
                        var coppyState = self.state
                        coppyState.isShowToastView = true
                        coppyState.messageToastView = "Start server is failed!"
                        self.state = coppyState
                    }
                case .stopFailed:
                    var coppyState = self.state
                    coppyState.isShowToastView = true
                    coppyState.messageToastView = "Disconnect server is failed!"
                    self.state = coppyState
                case .alreadyRuning:
                    break
                }
            }
            .store(in: &cancelBag)
        
        uploadSongUseCase.uploadedFilePublisher
            .sink { [weak self] path in
                guard let self = self else {
                    return
                }
                
                self.pendingUploads.append(path)
            }
            .store(in: &cancelBag)
    }
    
    func send(intent: SettingViewIntent) {
        switch intent {
        case .deleteAllSongs:
            deleteAllSongs()
        case .toggleServer:
            if state.isServerOn {
                stopServer()
            } else {
                startServer()
            }
        case .completedUploadSongs:
            if self.pendingUploads.count > 0 {
                Task {
                    do {
                        try await self.addSongUseCase.excuteList(from: self.pendingUploads)
                        self.pendingUploads = []
                    } catch {
                        print("add tat ca bai hat that bai: \(error)")
                    }
                }
            }
        }
    }
    
    private func startServer() {
        webUploaderUseCase.start()
    }
    
    private func deleteAllSongs() {
        
//        DocumentFileManager.shared.removeAllFile { [weak self] result in
//            guard let self = self else {
//                return
//            }
//            var copyState = self.state
//            switch result {
//            case .success:
//                copyState.messageToastView = "Deleted All Songs Success!"
//                copyState.isShowToastView = true
//            case .failure:
//                copyState.messageToastView = "Deleted All Songs Failed!"
//                copyState.isShowToastView = true
//            }
//            
//            DispatchQueue.main.async {
//                withAnimation {
//                    self.state = copyState
//                }
//            }
//        }
    }
    
    private func stopServer() {
        webUploaderUseCase.stop()
    }
    
    func isShowToastView() -> Binding<Bool> {
        return .init {
            return self.state.isShowToastView
        } set: { newValue in
            DispatchQueue.main.async {
                self.state.isShowToastView = false
            }
        }
    }
}
