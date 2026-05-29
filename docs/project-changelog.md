# Project Changelog

All significant changes to MusicOffline-SwiftUI are documented here.

## [2.1.0] - UI/UX Design-System Overhaul - 2026-05-29

### Summary
Replaced the flat dark-grey-only look with a dynamic, artwork-driven color system + tasteful motion across the whole app. Now Playing extracts a per-song color from album art (gradient background + accent), and every screen gains token-based colors/fonts, press feedback, haptics, and entrance animations. Build + contrast unit tests pass. Plan: `plans/260529-1530-ui-design-system-overhaul/`. See `docs/design-guidelines.md`.

### Added
- **Color token layer** — `AppColorTheme` (Environment-carried), semantic `Color` tokens (primaryText/secondaryText/mutedText/accentPrimary coral #FF6B6B/separator).
- **Artwork color engine** — `ArtworkColorExtractor` (CIAreaAverage on downscaled art), `PaletteProvider` (per-song NSCache, off-main-thread), `ContrastGuard` (WCAG AA legibility), `AppColorTheme.dynamic(from:)`. Now Playing full/mini player themed per song.
- **Motion system** — `MotionToken` spring presets, `Haptics` (`.sensoryFeedback`), `.pressScale()`, `.entrance(index:)`, `.dynamicBackground()` modifiers. All honor Reduce Motion.
- **Dynamic Type** — `AppFont` migrated to relative text styles (scales with system text size).
- `MusicAppTests/ArtworkColorThemeTests` — 7 tests asserting WCAG contrast guarantee.

### Changed
- Tab bar: active tab now coral accent + filled SF Symbol + scale + selection haptic (was plain white).
- Restyled all screens + shared components (SongItemView, nav bar, slider, toast) to tokens + press/haptics/entrance.
- Now Playing full player split into 5 focused subviews (all <200 LOC).

### Removed
- 3 orphaned/dead files: `Commons/Tabars/CustomTabBar.swift`, `Commons/CustomViews/CustomTabar.swift`, `Commons/SongItemView.swift`.

## [2.0.0] - Audio Editing + Import Expansion - 2026-05-29

### Summary
Fixed the lyrics matching pipeline, expanded the 3-band EQ to a 10-band parametric EQ (with migration), added speed/pitch/reverb effects, a non-destructive audio editor, and four new ways to import music. Build and unit tests pass. Plan: `plans/260526-audio-editing-and-import-expansion/`.

### Added

**Lyrics pipeline (P00):**
- `LyricsRepository.normalize` + in-memory normalized index — lookup fallback chain (exact → case-insensitive → diacritics/`[\s_-]`-collapsed), with ambiguity guard returning nil when 2+ files share a key.
- `AttachLyricsToSongUseCase` (file via security-scoped resource + pasted-text with empty guard), `RemoveLyricsUseCase`.
- `NowPlayingViewModel.lyricsStem(from:)` decodes percent-encoded file URLs; `NowPlayingStateReducer.activeLyricIndex(for:in:)`.
- `MusicAppTests/LyricsStemMatchingTests` — normalize (incl. Vietnamese), stem extraction, repo exact + fallback load.

**10-band parametric EQ (P01):**
- `EQPreset` — ISO freqs [31, 62, 125, 250, 500, 1k, 2k, 4k, 8k, 16k] Hz, 6 built-in presets + custom.
- `EQService` rebuilt for 10 bands (lowShelf/parametric/highShelf), per-band gain, bypass, persistence.
- **v1 → v2 migration:** legacy 3-band `eqGains` projected once onto the 10-band layout, legacy key removed.
- User EQ presets: `SaveUserEQPresetUseCase` / `LoadUserEQPresetsUseCase` / `DeleteUserEQPresetUseCase` + `UserEQPresetRepository`.

**Audio effects (P02):**
- `AudioEffectsService` — `AVAudioUnitTimePitch` (speed 0.5–2.0×, pitch ±12 st as cents) + `AVAudioUnitReverb` (preset + wet/dry), auto-bypass when neutral.
- `ReverbPreset` (Codable mirror of `AVAudioUnitReverbPreset`).
- Engine graph extended to `player → timePitch → reverb → eq → mainMixer`, reconnected with file-native format on load.

**Audio editor export (P03):**
- `AudioEditConfig`, `ScanWaveformUseCase`, `ComputeNormalizationGainUseCase` (peak → 0.95 FS, clamp [0.5, 3.0]).
- `ExportEditedAudioUseCase` — trim (composition) + fade in/out (volume ramps) + normalize → **M4A/AAC** in `Documents/Music/`; background task, progress polling, cancel/fail cleanup.
- AudioEditor feature MVI (View/State/Intent/Action/Reducer/ViewModel + Views).

**Import expansion (P05–P07):**
- `ExternalFileImportCoordinator` (`@MainActor`) — single funnel for AirDrop/Open-in/Files-drop, posts `.externalImportFinished`.
- `MusicApp.onOpenURL` → coordinator; scene-active Documents-root scan (skips Music/Lyrics/Inbox).
- `DownloadAudioFromURLUseCase` — HTTPS-only, filename inference, background download, cancellable, auto-ingest via `AddSongUseCase`.
- `ImportHubView` — one-screen list of import routes, reached from Library.

### Changed
- EQ persistence keys: `eqGains` (v1) → `eqGainsV2` (v2, length-10).

### Deferred
- **Share Extension (P04)** — code artifact prepared; Xcode target add (pbxproj surgery) pending. AirDrop/Open-in already functional via `onOpenURL`.

### Known Issues
- Import Hub "Pick from Files" posts `.openImportFromFiles` with no listener (dead action).
- First-launch routing to Import Hub not implemented (Hub reachable only from Library).
- URL download rejects HTTP (HTTPS-only) — archive.org HTTP direct links will be rejected.

See `plans/reports/qa-checklist-260529.md` for the full QA matrix.

## [Phase 05] - 2026-04-29

### Summary
Added 4 major features: iCloud Drive support, lyrics display with LRC parser, rule-based smart playlists, and 3-band equalizer with AVAudioEngine migration.

### Added

**Phase 01 - iCloud Drive Verification:**
- iCloud capability + entitlements configuration
- NSFileCoordinator integration for placeholder file downloads
- iCloud Documents support in Info.plist

**Phase 02 - Lyrics Support (.lrc files):**
- `LyricsLine` entity (timestamp, text)
- `LyricsRepository` — filesystem-based storage under `Documents/Lyrics/`
- `ParseLrcContentUseCase` — Parse [mm:ss.xx] format, handle metadata tags
- `FetchLyricsUseCase` — Load + parse .lrc files by song filename stem
- `LyricsView` — Auto-scrolling synchronized lyrics display with `ScrollViewReader`
- NowPlayingState extensions: `lyrics`, `activeLyricIndex`, `showLyrics`
- Extended `ImportSongFromFilesUseCase` to handle .lrc file routing
- Lyrics toggle button in NowPlayingFullPlayerView

**Phase 03 - Smart Playlist (Rule-Based):**
- `SmartPlaylist` entity with UUID, name, rules, createdAt
- `SmartPlaylistRule` entity — Field/Operator/Value triplet (artist/album/duration/dateAdded)
- `SmartPlaylistRepository` — CRUD with JSON encoding for rules
- `SmartPlaylistUseCase` — Build NSCompoundPredicate from rules, execute fetch
- `SaveSmartPlaylistUseCase` — Persist to CoreData
- SmartPlaylistEditor MVI (6 files: View, State, Intent, Action, Reducer, ViewModel)
- Live preview: song count as user edits rules
- Library UI updated: SmartPlaylist section with ⚡ icon
- CoreData migration: additive SmartPlaylistEntity (lightweight)

**Phase 04 - Equalizer + AVAudioEngine Migration:**
- `EQPreset` enum — 6 presets (Flat, Bass Boost, Pop, Rock, Classical, Jazz) with gain tables
- `EQServiceProtocol` + `EQService` — Manages AVAudioUnitEQ (3 parametric bands at 60Hz/1kHz/14kHz)
- `AVAudioPlayerEngineService` **complete rewrite** — Migrated from AVAudioPlayer to AVAudioEngine
  - AVAudioPlayerNode + AVAudioUnitEQ graph
  - Seek via `scheduleSegment()` with frame offset tracking
  - Sample-time math for currentTime calculation
  - Interruption + route-change handling
  - Background audio session management
  - NowPlayingInfo integration preserved
- EqualizerView MVI (6 files) — 3 vertical sliders (-12dB..+12dB), preset chip row
- Preset + custom gains persist to UserDefaults
- Immediate EQ application mid-playback (no glitch)
- AppRoute extended: `.equalizer`
- SettingView row added for Equalizer access

### Modified

**ImportSongFromFilesUseCase** (`Domain/UseCases/Playlist/ImportSongFromFilesUseCase.swift`)
- Extended to detect .lrc extension and route to LyricsRepository

**NowPlayingFullPlayerView** (`Presentation/Feature/NowPlaying/NowPlayingFullPlayerView.swift`)
- Added lyrics toggle button + conditional LyricsView rendering

**NowPlayingState/Intent/Action/Reducer** (`Presentation/Feature/NowPlaying/State/`)
- Added `lyrics: [LyricsLine]`, `activeLyricIndex: Int?`, `showLyrics: Bool`
- Added intents: `toggleLyrics`, `lyricsLoaded`
- Added actions + reducer cases for active index computation

**LibraryView** (`Presentation/Feature/Library/LibraryView.swift`)
- Added smart playlist section rendering with ⚡ icon separator

**SettingView** (`Presentation/Feature/Setting/SettingView.swift`)
- Added Equalizer row in General settings section

**DIContainer+UseCases** (`DI/DIContainer+UseCases.swift`)
- Registered LyricsRepository, FetchLyricsUseCase, ParseLrcContentUseCase
- Registered SmartPlaylistRepository, SmartPlaylistUseCase, SaveSmartPlaylistUseCase
- Registered EQService singleton
- Updated ViewFactory with SmartPlaylistEditorView, EqualizerView

**DIContainer+ViewFactory** (`DI/DIContainer+ViewFactory.swift`)
- Added factory methods for SmartPlaylistEditor (init + edit modes)
- Added factory methods for Equalizer

**AppRoute** (`Navigation/AppRoute.swift`)
- Added `.smartPlaylistEditor(SmartPlaylist?)` — Create/edit smart playlists
- Added `.equalizer` — Access EQ settings

### Breaking Changes
None. All changes backward compatible.

**Migration Notes:**
- CoreData: SmartPlaylistEntity added (lightweight migration, no Song schema changes)
- UserDefaults: EQ preset + gains auto-initialized to Flat on first launch
- ImportSongFromFilesUseCase now accepts .lrc in addition to audio formats

### Bug Fixes
- None specific to new features (all greenfield)

### Tests
- Unit tests for ParseLrcContentUseCase: single timestamp, multi-timestamp, metadata skip, malformed tolerance
- Unit tests for SmartPlaylistUseCase: predicate builder (operator × field combinations)
- Integration tests for LyricsRepository: save/load roundtrip, UTF-8 fallback
- Integration tests for SmartPlaylistRepository: encode/decode rules JSON
- Manual test matrix for AVAudioEngine: seek, pause/resume, interruption, route change, background

### Performance Notes
- Lyrics: O(n) parse, active-line search via binary search in reducer
- Smart Playlist: NSCompoundPredicate evaluated lazily on view (no background indexing)
- EQ: Zero-latency parameter updates (immediate AVAudioUnitEQ node changes)
- Seek: < 100ms target precision via frame offset tracking

### Known Limitations
- Lyrics: Filename stem matching (no manual link editor yet)
- Smart Playlist: AND-only rule combination (OR deferred to Phase 7+)
- EQ: Local playback only; AirPlay EQ support deferred
- iCloud: User-initiated import only (no background sync)

### Security Considerations
- Lyrics: Files stored in app sandbox (Documents/Lyrics/)
- Smart Playlist: Predicates use parameterized %@ binding (no injection risk)
- iCloud: NSFileCoordinator + security-scoped resource access

---

## [Phase 04] - 2026-04-29

### Summary
Improved playlist management with advanced CRUD operations, drag-to-reorder, song import from Files app, and enhanced sorting options.

### Added

**New Use Cases:**
- `ReorderPlaylistSongsUseCase` — Reorder songs within playlist via drag & drop
  - Accepts playlistId and ordered song IDs array
  - Publishes update event via PlaylistEventCenter
  - File: `Domain/UseCases/Playlist/ReorderPlaylistSongsUseCase.swift`

- `ImportSongFromFilesUseCase` — Import audio files from iOS Files app
  - Supports formats: mp3, m4a, wav, flac, aac, ogg
  - Duplicate detection by filename hash
  - File copy to app Documents/Music/
  - Metadata extraction via AVAsset
  - Progress tracking for multi-file imports
  - File: `Domain/UseCases/Playlist/ImportSongFromFilesUseCase.swift`

**New Feature Module:**
- `ImportSong` MVI feature
  - State: Import progress, results list, error messages
  - Intent: selectFiles(urls), retryImport(indices)
  - ViewModel: Orchestrates ImportSongFromFilesUseCase
  - View: UIDocumentPickerViewController wrapper + results display
  - Files: `Presentation/Feature/ImportSong/{State,Intent,ViewModel,View}.swift`

**New Repository Methods:**
- `PlaylistRepository.updateSongOrder(playlistId: UUID, orderedSongIDs: [UUID])` async throws
  - Updates playlist.songUUIDs array directly
  - Preserves order across app restarts via CoreData

**New State Properties (PlaylistDetail):**
- `PlaylistDetailState.sortOption: PlaylistSortOption` — Sort menu selection
- `PlaylistDetailState.isEditMode: Bool` — Edit/select mode toggle
- `PlaylistDetailState.selectedSongIDs: Set<UUID>` — Multi-select tracking

**New Intents (PlaylistDetail):**
- `PlaylistDetailIntent.reorderSongs(from: IndexSet, to: Int)` — Drag reorder
- `PlaylistDetailIntent.toggleEditMode` — Enter/exit edit mode
- `PlaylistDetailIntent.toggleSongSelection(id: UUID)` — Checkbox selection
- `PlaylistDetailIntent.bulkDelete` — Delete selected songs
- `PlaylistDetailIntent.setSortOption(PlaylistSortOption)` — Sort menu

### Modified

**AddPlaylistUseCase** (`Domain/UseCases/Playlist/AddPlaylistUseCase.swift`)
- Added name validation: trim whitespace
- Added length constraint: 1-50 characters (was unlimited)
- Added uniqueness check before CoreData save (case-insensitive)
- Throws `AddPlaylistError.nameTooLong` for names > 50 chars
- Throws `AddPlaylistError.playListNameExtisted` for duplicates

**PlaylistRepository** (`Data/Repositories/PlaylistRepository.swift`)
- Enhanced `fetchAllPlayList()` to accept `sortBy: PlaylistSortOption` parameter
  - `.nameAscending` — Sort A-Z by playlist name
  - `.dateCreated` — Sort by creation date (newest first)
  - `.songCount` — Sort by number of songs (most first)
- Added `updateSongOrder()` method for drag-to-reorder operations
- Default sort: `.nameAscending` (backward compatible)

**PlaylistDetailView** (`Presentation/Feature/PlaylistDetail/PlaylistDetailView.swift`)
- Added drag-to-reorder via `.onMove()` modifier on song list
- Added sort menu button to toolbar (name, date, count)
- Added edit mode toggle button
- Added multi-select checkboxes in edit mode
- Added bulk delete button (visible in edit mode)

**PlaylistDetailViewModel** (`Presentation/Feature/PlaylistDetail/PlaylistDetailViewModel.swift`)
- Wired new use cases: ReorderPlaylistSongsUseCase, ImportSongFromFilesUseCase
- Handle `.reorderSongs` intent → update order → publish event
- Handle `.toggleEditMode` intent → toggle isEditMode state
- Handle `.toggleSongSelection` intent → manage selectedSongIDs set
- Handle `.bulkDelete` intent → delete selected songs
- Handle `.setSortOption` intent → re-fetch with sort applied

**DIContainer** (`Core/DI/DIContainer+UseCases.swift`)
- Wired `ReorderPlaylistSongsUseCase` into UseCases struct
- Wired `ImportSongFromFilesUseCase` into UseCases struct
- Both use cases initialized with playlist repository reference

### Breaking Changes
None. All changes are backward compatible.

**Migration Notes:**
- PlaylistRepository.fetchAllPlayList() now requires sort option (defaults to .nameAscending)
- Existing playlists automatically gain createdAt timestamp on first fetch

### Bug Fixes
- Fixed playlist song order not persisting after app restart (now uses songUUIDs array)
- Fixed duplicate playlist names not preventing creation (added uniqueness check)

### Tests
- Unit tests for AddPlaylistUseCase validation rules
- Unit tests for ReorderPlaylistSongsUseCase event publishing
- Unit tests for ImportSongFromFilesUseCase duplicate detection
- UI tests for drag-to-reorder gesture
- UI tests for file import flow

### Performance Notes
- Import: Background thread operations, main thread UI updates
- Reorder: In-memory array sort + CoreData save (< 100ms for typical playlists)
- Sort: CoreData fetch with appropriate predicates + in-memory secondary sort for song count

### Known Limitations
- Import: UIDocumentPickerViewController not available in preview (test on simulator/device)
- Reorder: Song order display depends on ListRowInsets ordering (verified stable)
- Sort: Song count sort is approximate (based on current songUUIDs count, not historical)

---

## [Phase 03] - 2026-04-28

### Summary
Split large files, improved modularization, reduced file complexity.

### Changes
- Split AddNewPlaylistView into separate files (State, Intent, ViewModel, View)
- Split PlaylistDetailView: separated song list from playlist info
- Split LibraryView: separated view models for search, filtering
- Split NowPlayingView: separated full player from mini player

**Result:** Max file size reduced from 500+ LOC to ~200 LOC per file.

---

## [Phase 02] - 2026-04-27

### Summary
Refactored file structure, separated concerns by domain layer.

### Changes
- Created `Domain/` layer with Use Cases, Entities, Repositories
- Created `Data/` layer with Repositories, CoreData mappers
- Moved repositories from flat structure to feature-organized structure
- Established clear dependency flow: Presentation → Domain → Data

---

## [Phase 01] - 2026-04-26

### Summary
Refactored DI architecture, removed AppDependencies singleton.

### Changes
- Replaced `AppDependencies` singleton with `DIContainer`
- Implemented environment-based dependency injection (@Environment)
- Added `AppEnvironment` for bootstrap configuration
- All use cases now protocol-based for testability

**Impact:** Improved testability, removed singleton anti-pattern.

---

## Initial Release - 2025-02-21

### Features
- Full music player (play, pause, seek, skip)
- Library browsing & search
- Playlist management (create, add songs, delete)
- WiFi file upload via web interface
- Album artwork display
- Sleep timer
- Background playback
- Lock screen & control center integration

### Architecture
- Clean Architecture + MVVM
- MVI pattern for feature state management
- CoreData persistence
- Protocol-oriented design

### Dependencies
- SwiftUI (native)
- CoreData (native)
- AVFoundation (native)
- GCDWebServer (~> 3.0)

### Build Info
- Min iOS: 15.0
- Min Xcode: 13.0
- Swift: 5.5+

---

## Version History

| Version | Phase | Date | Status |
|---------|-------|------|--------|
| 1.4.0 | Phase 05 (iCloud + Lyrics + Smart Playlist + EQ) | 2026-04-29 | ✅ Complete |
| 1.3.0 | Phase 04 (Playlist Management) | 2026-04-29 | ✅ Complete |
| 1.2.0 | Phase 03 (Modularization) | 2026-04-28 | ✅ Complete |
| 1.1.0 | Phase 02 (File Structure) | 2026-04-27 | ✅ Complete |
| 1.0.0 | Phase 01 (DI Architecture) | 2026-04-26 | ✅ Complete |
| 0.1.0 | Initial | 2025-02-21 | ✅ Complete |

---

## Deprecations

None currently.

## Security Updates

### Phase 04
- Import: File validation before copy (format check)
- Import: Sandbox enforcement (Files app picker, not arbitrary access)

---

## Roadmap Milestones

- **Phase 06 (Planned):** Playback flow improvements (queue, shuffle algorithm, repeat modes)
- **Phase 07 (Planned):** Feature brainstorm & prioritization
- **Phase 08 (Planned):** Backup & restore (iCloud metadata sync, encrypted local backups)

See `docs/development-roadmap.md` for detailed roadmap.

---

## How to Contribute

1. Create feature branch from `Master`
2. Implement feature following architecture guidelines in `docs/code-standards.md`
3. Write tests for business logic
4. Update this changelog under "Unreleased" section
5. Create PR with test coverage summary

---

## Notes for Maintainers

- **Breaking changes** require version bump (1.x → 2.0)
- **New features** require minor version bump (1.2 → 1.3)
- **Bug fixes** require patch version bump (1.2.1 → 1.2.2)
- All changes should be backward compatible when possible
- Document migrations for CoreData schema changes

---

---

**Last Updated:** 2026-04-29 by project-manager
**Next Phase:** Phase 06 (Playback Flow Improvements)
**Target:** 2026-05-13
