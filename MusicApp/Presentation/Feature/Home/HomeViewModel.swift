//
//  HomeViewModel.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/28/25.
//

import SwiftUI

final class HomeViewModel: ObservableObject {
    private let getSongUseCase: GetSongUseCaseProtocol
    
    init(getSongUseCase: GetSongUseCaseProtocol = GetSongUseCase()) {
        self.getSongUseCase = getSongUseCase
    }
    
    func fetchSongs() {
        Task {
            do {
                let result = try await getSongUseCase.excuteGetAll()
                print("da call thanh cong")
            } catch {
                print("da xuat hien error")
            }
        }
    }
}
