//
//  AddNewlibaryViewmodel.swift
//  MusicApp
//
//  Created by Nhat on 10/7/23.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
protocol AddNewPlaylistViewModelProtocol: ObservableObject {
    var state: AddNewPlaylistState { get }
    func send(intent: AddNewPlaylistIntent)
    func bindingName() -> Binding<String>
    func bindingHeightOfKeyBoard() -> Binding<CGFloat>
    var bindingShowToastView: Binding<Bool> { get }
}

final class AddNewPlaylistViewModel: AddNewPlaylistViewModelProtocol {

    // MARK: - properties
    @Published private(set) var state: AddNewPlaylistState
    private let addPlaylistUseCase: AddPlaylistUseCaseProtocol
    
    init(state: AddNewPlaylistState = .init(),
         addPlaylistUseCase: AddPlaylistUseCaseProtocol = AddPlaylistUseCase()) {
        self.state = state
        self.addPlaylistUseCase = addPlaylistUseCase
    }
    
    func send(intent: AddNewPlaylistIntent) {
        switch intent {
        case .addNewLibary(let onCompleted):
            addNewPlaylist(onCompleted: onCompleted)
        }
    }
    
    private func addNewPlaylist(onCompleted: @escaping () -> Void) {
        Task {
            do {
                try await addPlaylistUseCase.execute(with: self.state.playlistName)
                await MainActor.run {
                    onCompleted()
                }
            } catch {
                if let error = error as? AddPlaylistError {
                    // TODO: handle error here
                    await MainActor.run {
                        var newState = self.state
                        newState.isShowToastView = true
                        switch error {
                        case .playListNameExtisted:
                            newState.toastViewMessage = "This playlist already exists. Please choose a different name."
                        }
                        self.state = newState
                    }
                }
            }
        }
    }
    
    func bindingName() -> Binding<String> {
        return .init { [weak self] in
            guard let self = self else { return String.empty}
            return self.state.playlistName
        } set: { [weak self] newValue in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.state.playlistName = newValue
            }
        }
    }
    
    func bindingHeightOfKeyBoard() -> Binding<CGFloat> {
        return .init { [weak self] in
            guard let self = self else { return 0}
            return self.state.heightOfKeyboard
        } set: { [weak self] newValue in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.state.heightOfKeyboard = newValue
            }
        }
    }
    
    var bindingShowToastView: Binding<Bool> {
        .init(get: {
            return self.state.isShowToastView
        }, set: { newValue in
            return self.state.isShowToastView = newValue
        })
    }
}
