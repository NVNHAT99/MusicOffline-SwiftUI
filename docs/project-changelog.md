# Project Changelog

All significant changes to MusicOffline-SwiftUI are documented here.

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
| 1.3.0 | Phase 04 | 2026-04-29 | ✅ Complete |
| 1.2.0 | Phase 03 | 2026-04-28 | ✅ Complete |
| 1.1.0 | Phase 02 | 2026-04-27 | ✅ Complete |
| 1.0.0 | Phase 01 | 2026-04-26 | ✅ Complete |
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

- **Phase 05 (Planned):** Playback flow improvements (queue, shuffle algorithm, repeat modes)
- **Phase 06 (Planned):** Feature brainstorm & prioritization

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

**Last Updated:** 2026-04-29 by docs-manager
