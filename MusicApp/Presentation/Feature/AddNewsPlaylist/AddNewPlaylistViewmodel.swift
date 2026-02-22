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

    // MARK: - Properties
    @Published private(set) var state: AddNewPlaylistState
    private let reducer: any AddNewPlaylistStateReducerProtocol
    private let addPlaylistUseCase: AddPlaylistUseCaseProtocol

    // MARK: - Init
    init(
        state: AddNewPlaylistState = .init(),
        reducer: any AddNewPlaylistStateReducerProtocol = AddNewPlaylistStateReducerImpl(),
        addPlaylistUseCase: AddPlaylistUseCaseProtocol = AddPlaylistUseCase()
    ) {
        self.state = state
        self.reducer = reducer
        self.addPlaylistUseCase = addPlaylistUseCase
    }

    // MARK: - Intent Handler
    func send(intent: AddNewPlaylistIntent) {
        switch intent {
        case .addNewLibary(let onCompleted):
            addNewPlaylist(onCompleted: onCompleted)
        }
    }

    // MARK: - Private Methods
    private func addNewPlaylist(onCompleted: @escaping () -> Void) {
        Task {
            do {
                try await addPlaylistUseCase.execute(with: state.playlistName)
                await MainActor.run {
                    state = reducer.reduce(state, with: .setCompletedAddPlaylist(true))
                    onCompleted()
                }
            } catch {
                if let error = error as? AddPlaylistError {
                    await MainActor.run {
                        switch error {
                        case .playListNameExtisted:
                            state = reducer.reduce(state, with: .setShowToast(true, message: "This playlist already exists. Please choose a different name."))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Bindings
    func bindingName() -> Binding<String> {
        return .init { [weak self] in
            guard let self = self else { return String.empty }
            return self.state.playlistName
        } set: { [weak self] newValue in
            guard let self = self else { return }
            Task { @MainActor in
                self.state = self.reducer.reduce(self.state, with: .setPlaylistName(newValue))
            }
        }
    }

    func bindingHeightOfKeyBoard() -> Binding<CGFloat> {
        return .init { [weak self] in
            guard let self = self else { return 0 }
            return self.state.heightOfKeyboard
        } set: { [weak self] newValue in
            guard let self = self else { return }
            Task { @MainActor in
                self.state = self.reducer.reduce(self.state, with: .setHeightOfKeyboard(newValue))
            }
        }
    }

    var bindingShowToastView: Binding<Bool> {
        .init(get: {
            return self.state.isShowToastView
        }, set: { newValue in
            self.state = self.reducer.reduce(self.state, with: .setShowToast(newValue, message: self.state.toastViewMessage))
        })
    }
}
