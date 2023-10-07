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
    init(state: SettingViewState = .init()) {
        self.state = state
        
        WebServerWrapper.shared.webLoaderResult.sink { result in
            switch result {
            case .success(let newResult):
                switch newResult {
                case .startSuccess(ipAddress: let ipAddress):
                    DispatchQueue.main.async {
                        withAnimation {
                            var coppyState = self.state
                            coppyState.ipAdress = ipAddress
                            coppyState.isServerOn = true
                            self.state = coppyState
                        }
                        
                    }
                case .stopSucesss:
                    DispatchQueue.main.async {
                        withAnimation {
                            self.state.isServerOn = false
                        }
                    }
                }
            case .failure(let error):
                switch error {
                case .startFailed:
                    DispatchQueue.main.async {
                        withAnimation {
                            var coppyState = self.state
                            coppyState.isShowToastView = true
                            coppyState.messageToastView = "Start server is failed!"
                            self.state = coppyState
                        }
                        
                    }
                case .stopFailed:
                    withAnimation {
                        var coppyState = self.state
                        coppyState.isShowToastView = true
                        coppyState.messageToastView = "Disconnect server is failed!"
                        self.state = coppyState
                    }
                }
            }
        }.store(in: &cancelBag)
        
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
        }
    }
    
    private func startServer() {
        WebServerWrapper.shared.startWebUploader()
    }
    
    private func deleteAllSongs() {
        DocumentFileManager.shared.removeAllFile { result in
            var copyState = self.state
            switch result {
            case .success:
                copyState.messageToastView = "Deleted All Songs Success!"
                copyState.isShowToastView = true
            case .failure:
                copyState.messageToastView = "Deleted All Songs Failed!"
                copyState.isShowToastView = true
            }
            DispatchQueue.main.async {
                withAnimation {
                    self.state = copyState
                }
            }
        }
    }
    
    private func stopServer() {
        WebServerWrapper.shared.stopWebUploader()
    }
    
    func isShowToastView() -> Binding<Bool> {
        return .init {
            return self.state.isShowToastView
        } set: { newValue in
            self.state.isShowToastView = false
        }

    }
}
