//
//  RecentSongsManager.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 9/3/25.
//

import Foundation

// MARK: - UserDefaults Keys
private extension UserDefaults {
    static let recentSongsKey = "recentSongs"
    static let currentPlaylistKey = "currentPlaylistID"
    static let recentPlaylistsKey = "recentPlaylists"
}

// MARK: - Recent Song Item
struct RecentSongItem: Codable, Equatable, Identifiable {
    let song: SongModel
    let playlistId: String?
    
    var id: String { song.id.uuidString }
}

// MARK: - Recent Songs & Playlists Manager
struct RecentSongsManager {
    // MARK: - Recent Songs
    static func add(_ song: SongModel, in playlistId: String?) {
        var items = fetchRecentSongs()

        // Xóa nếu đã có để tránh trùng lặp
        items.removeAll { $0.song.id == song.id }

        // Thêm lên đầu
        let newItem = RecentSongItem(song: song, playlistId: playlistId)
        items.insert(newItem, at: 0)

        // Giữ tối đa 5 phần tử
        if items.count > 5 {
            items = Array(items.prefix(5))
        }

        saveRecentSongs(items)
    }

    static func fetchRecentSongs() -> [RecentSongItem] {
        guard let data = UserDefaults.standard.data(forKey: UserDefaults.recentSongsKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([RecentSongItem].self, from: data)
        } catch {
            print("Decode recent songs error: \(error)")
            return []
        }
    }
    
    static func removePlaylist(id playlistId: String) {
        // 1. Xoá các bài hát thuộc playlist này khỏi recent songs
        var songs = fetchRecentSongs()
        songs.removeAll { $0.playlistId == playlistId }
        saveRecentSongs(songs)

        // 2. Xoá playlist khỏi recent playlists
        var playlists = fetchRecentPlaylists()
        playlists.removeAll { $0 == playlistId }
        saveRecentPlaylists(playlists)

        // 3. Nếu currentPlaylist đang play là playlist này thì clear luôn
        if fetchCurrentPlaylist() == playlistId {
            clearCurrentPlaylist()
        }
    }

    static func clearRecentSongs() {
        UserDefaults.standard.removeObject(forKey: UserDefaults.recentSongsKey)
    }

    private static func saveRecentSongs(_ songs: [RecentSongItem]) {
        do {
            let data = try JSONEncoder().encode(songs)
            UserDefaults.standard.set(data, forKey: UserDefaults.recentSongsKey)
        } catch {
            print("Encode recent songs error: \(error)")
        }
    }

    // MARK: - Current Playlist
    static func saveCurrentPlaylist(id: String) {
        UserDefaults.standard.set(id, forKey: UserDefaults.currentPlaylistKey)
    }

    static func fetchCurrentPlaylist() -> String? {
        UserDefaults.standard.string(forKey: UserDefaults.currentPlaylistKey)
    }

    static func clearCurrentPlaylist() {
        UserDefaults.standard.removeObject(forKey: UserDefaults.currentPlaylistKey)
    }

    // MARK: - Recent Playlists
    static func addRecentPlaylist(id: String) {
        var playlists = fetchRecentPlaylists()
        playlists.removeAll { $0 == id }
        playlists.insert(id, at: 0)
        if playlists.count > 5 {
            playlists = Array(playlists.prefix(5))
        }
        saveRecentPlaylists(playlists)
    }

    static func fetchRecentPlaylists() -> [String] {
        UserDefaults.standard.stringArray(forKey: UserDefaults.recentPlaylistsKey) ?? []
    }

    static func clearRecentPlaylists() {
        UserDefaults.standard.removeObject(forKey: UserDefaults.recentPlaylistsKey)
    }

    private static func saveRecentPlaylists(_ playlists: [String]) {
        UserDefaults.standard.set(playlists, forKey: UserDefaults.recentPlaylistsKey)
    }
}
