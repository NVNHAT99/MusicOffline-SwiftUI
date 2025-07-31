//
//  HomeViewModel.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/28/25.
//

import SwiftUI

final class HomeViewModel: ObservableObject {
    private let getAllSongUseCase: GetAllSongUseCaseProtocol
    
    init(getAllSongUseCase: GetAllSongUseCaseProtocol = GetAllSongUseCase()) {
        self.getAllSongUseCase = getAllSongUseCase
    }
    
    func fetchSongs() {
        Task {
            do {
                let result = try await getAllSongUseCase.excute()
                print("da call thanh cong")
            } catch {
                print("da xuat hien error")
            }
        }
    }
}
