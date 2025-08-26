//
//  SelectedSong.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/26/25.
//

import Foundation

struct SelectedSong: Identifiable, Equatable {
    let id = UUID()
    let song: SongModel
    var isSelected: Bool
    
    var songUUIDString: String {
        song.id.uuidString
    }
}
