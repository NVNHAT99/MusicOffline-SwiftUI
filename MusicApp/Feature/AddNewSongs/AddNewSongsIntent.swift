//
//  AddNewSongsIntent.swift
//  MusicApp
//
//  Created by Nhat on 9/21/23.
//

import Foundation

enum AddNewSongsIntent {
    case loadListSong
    case toggleSelectedAt(index: Int)
    case addToPlaylist(onCompleted: (Result<Bool, Error>) -> Void)
}
