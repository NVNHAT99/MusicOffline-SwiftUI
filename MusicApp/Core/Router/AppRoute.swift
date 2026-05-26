//
//  AppRoute.swift
//  MusicApp
//
//  Created by Claude
//

import Foundation

/// Application routes following EasyFax pattern
/// Type-safe navigation using enum-based routes
public enum AppRoute: Routable {

    // MARK: - Tab Routes
    case home
    case library
    case transfer
    case setting

    // MARK: - Detail Routes
    case playlistDetail(id: UUID)
    case nowPlaying
    case addNewPlaylist
    case editPlaylist(playlistId: UUID)

    // MARK: - Timer Routes (from MainTabRoute)
    case timerPicker
    case timerMenuSheet

    // MARK: - Transfer Routes (from SettingRoute)
    case transferAudio

    // MARK: - Smart Playlist
    case smartPlaylistEditor(UUID?)

    // MARK: - Equalizer
    case equalizer

    // MARK: - Audio Editor
    case audioEditor(sourceURL: URL, title: String)

    // MARK: - URL Download
    case urlDownload

    // MARK: - Import Hub
    case importHub

    // MARK: - Presentation Style
    public var presentationStyle: PresentationStyle {
        switch self {
        case .home, .library, .transfer:
            return .navigationLink

        case .setting:
            return .fullScreen

        case .playlistDetail, .editPlaylist:
            return .fullScreen

        case .addNewPlaylist:
            return .fullScreen

        case .nowPlaying:
            return .fullScreen

        case .timerPicker:
            return .fullScreen

        case .timerMenuSheet:
            return .sheet

        case .transferAudio:
            return .fullScreen

        case .smartPlaylistEditor:
            return .fullScreen

        case .equalizer:
            return .fullScreen

        case .audioEditor:
            return .fullScreen

        case .urlDownload:
            return .sheet

        case .importHub:
            return .sheet
        }
    }

    // MARK: - Identifiable
    public var id: String {
        switch self {
        case .home:
            return "home"
        case .library:
            return "library"
        case .transfer:
            return "transfer"
        case .setting:
            return "setting"
        case .playlistDetail(let id):
            return "playlistDetail-\(id.uuidString)"
        case .nowPlaying:
            return "nowPlaying"
        case .addNewPlaylist:
            return "addNewPlaylist"
        case .editPlaylist(let id):
            return "editPlaylist-\(id.uuidString)"
        case .timerPicker:
            return "timerPicker"
        case .timerMenuSheet:
            return "timerMenuSheet"
        case .transferAudio:
            return "transferAudio"
        case .smartPlaylistEditor(let id):
            return "smartPlaylistEditor-\(id?.uuidString ?? "new")"
        case .equalizer:
            return "equalizer"
        case .audioEditor(let url, _):
            return "audioEditor-\(url.lastPathComponent)"
        case .urlDownload:
            return "urlDownload"
        case .importHub:
            return "importHub"
        }
    }
}
