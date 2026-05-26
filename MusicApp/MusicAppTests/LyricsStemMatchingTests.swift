//
//  LyricsStemMatchingTests.swift
//  MusicAppTests
//
//  Covers LyricsRepository.normalize and NowPlayingViewModel.lyricsStem —
//  these two together are the load-bearing pieces that decide whether a
//  song's lyrics actually surface in the player.
//

import XCTest
@testable import MusicApp

final class LyricsStemMatchingTests: XCTestCase {

    // MARK: - normalize

    func test_normalize_lowercases() {
        XCTAssertEqual(LyricsRepository.normalize("MySong"), "mysong")
    }

    func test_normalize_stripsDiacritics_vietnamese() {
        // "Hạ Trắng" — common Vietnamese diacritics
        XCTAssertEqual(LyricsRepository.normalize("Hạ Trắng"), "hatrang")
    }

    func test_normalize_collapsesWhitespaceAndPunct() {
        XCTAssertEqual(LyricsRepository.normalize("my song"),  "mysong")
        XCTAssertEqual(LyricsRepository.normalize("my_song"),  "mysong")
        XCTAssertEqual(LyricsRepository.normalize("my-song"),  "mysong")
        XCTAssertEqual(LyricsRepository.normalize("my  song"), "mysong")
    }

    func test_normalize_mixedFormatting() {
        XCTAssertEqual(LyricsRepository.normalize("My_Song-Title"), "mysongtitle")
        XCTAssertEqual(LyricsRepository.normalize("MY SONG_TITLE"), "mysongtitle")
    }

    func test_normalize_emptyString() {
        XCTAssertEqual(LyricsRepository.normalize(""), "")
    }

    // MARK: - lyricsStem extraction

    func test_lyricsStem_nilOrEmpty() {
        XCTAssertNil(NowPlayingViewModel.lyricsStem(from: nil))
        XCTAssertNil(NowPlayingViewModel.lyricsStem(from: ""))
    }

    func test_lyricsStem_plainPath() {
        let stem = NowPlayingViewModel.lyricsStem(from: "/var/mobile/Documents/Music/My Song.mp3")
        XCTAssertEqual(stem, "My Song")
    }

    func test_lyricsStem_fileURL_percentEncoded() {
        // file:// URL with %20 must decode to "My Song" not "My%20Song".
        let stem = NowPlayingViewModel.lyricsStem(from: "file:///var/mobile/Documents/Music/My%20Song.mp3")
        XCTAssertEqual(stem, "My Song")
    }

    func test_lyricsStem_bareFilename() {
        let stem = NowPlayingViewModel.lyricsStem(from: "MySong.mp3")
        XCTAssertEqual(stem, "MySong")
    }

    // MARK: - End-to-end: save + fallback load

    func test_repository_loadsExactStem() throws {
        let repo = LyricsRepository()
        let stem = "TestSong_\(UUID().uuidString)"
        defer { repo.delete(stem: stem) }

        try repo.save(stem: stem, content: "[00:01.00]hello")
        XCTAssertNotNil(repo.load(stem: stem))
    }

    func test_repository_loadsViaNormalizedFallback() throws {
        let repo = LyricsRepository()
        let saved = "Song_\(UUID().uuidString)"
        defer { repo.delete(stem: saved) }

        try repo.save(stem: saved, content: "[00:01.00]hi")

        // Build a "user lookup" stem that differs in casing + separators only.
        let lookup = saved.uppercased().replacingOccurrences(of: "_", with: " ")
        XCTAssertNotEqual(saved, lookup, "test setup must produce a non-exact lookup string")
        XCTAssertNotNil(repo.load(stem: lookup), "normalized fallback should resolve casing/separator drift")
    }
}
