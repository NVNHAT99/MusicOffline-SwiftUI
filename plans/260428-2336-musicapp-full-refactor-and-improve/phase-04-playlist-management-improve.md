# Phase 04 - Improve Playlist Management (CRUD + Import)

**Priority:** P1 | **Status:** ✅ Complete | **Depends on:** Phase 03 complete  
**⚠️ Clear context before starting this phase**

## Context Links
- Current: `MusicApp/Domain/UseCases/Playlist/` (4 use cases)
- Current: `MusicApp/Data/Repositories/PlaylistRepository.swift`
- Current: `MusicApp/Presentation/Feature/AddNewsPlaylist/`
- Current: `MusicApp/Presentation/Feature/AddNewSongs/EditPlaylistView.swift`
- Current: `MusicApp/Presentation/Feature/PlaylistDetail/`
- Current: `MusicApp/Domain/Entities/Playlist.swift`

## Overview

Improve playlist management quality: better CRUD algorithms, batch operations, import songs from device (Files app), duplicate detection, reorder tracks, and robust error handling.

**Current gaps identified:**
- `PlaylistRepository.fetchAllPlayList()` sorts by name only — no sort-by-date, sort-by-count options
- `AddNewPlaylistViewModel` validates name server-side but no client-side length/trim validation
- `EditPlaylistViewModel.savePlaylist()` replaces entire songIDs array — no diff/delta update
- No ability to import songs from iOS Files app (UIDocumentPickerViewController)
- No drag-to-reorder song order within playlist
- `PlaylistDetailViewModel` fetches songs by ID array but doesn't preserve order from `playlist.songIDs`
- No bulk delete (delete multiple songs at once)
- No duplicate song detection when adding to playlist

## Requirements

### Functional
1. **Playlist CRUD**
   - Create: trim name, validate 1-50 chars, check duplicate names before saving
   - Edit name: same validation as create
   - Delete: confirm dialog before delete
   - Sort playlists: by name A-Z, date created, song count

2. **Song management within playlist**
   - Add songs: select from library (already exists via EditPlaylistView)
   - Remove songs: swipe-to-delete per song (already exists partially)
   - Reorder songs: drag-to-reorder (new)
   - Preserve song order: `playlist.songIDs` order = display order
   - Bulk delete: multi-select then delete

3. **Import songs**
   - Import from Files app via `UIDocumentPickerViewController`
   - Support formats: mp3, m4a, wav, flac, aac, ogg
   - Show import progress
   - Detect and skip duplicate files (by filename hash)
   - Move file to app Documents directory

4. **Error handling**
   - Playlist name already exists → show inline error (not just toast)
   - Import failed → specific error message per file
   - CoreData save failure → retry option

### Non-functional
- Import runs on background thread, UI updates on main thread
- Song order preserved across app restarts (CoreData)

## Architecture

### New/modified components

```
Domain/UseCases/Playlist/
├── ReorderPlaylistSongsUseCase.swift     # NEW: reorder songs in playlist
├── ImportSongFromFilesUseCase.swift      # NEW: UIDocumentPicker + file copy + CoreData

Domain/UseCases/Playlist/
├── AddPlaylistUseCase.swift              # MODIFY: add name validation + trim
├── UpdatePlaylistUseCase.swift           # MODIFY: delta update instead of full replace

Data/Repositories/
├── PlaylistRepository.swift             # MODIFY: add sort options, reorder method

Presentation/Feature/PlaylistDetail/
├── PlaylistDetailState.swift            # MODIFY: add sortOption, isReordering states
├── PlaylistDetailIntent.swift           # MODIFY: add reorderSongs, bulkDelete intents
├── PlaylistDetailViewModel.swift        # MODIFY: handle new intents
├── PlaylistDetailView.swift             # MODIFY: add drag handle, sort menu

Presentation/Feature/AddNewsPlaylist/
├── AddNewPlaylistState.swift            # MODIFY: add nameError field
├── AddNewPlaylistViewmodel.swift        # MODIFY: client-side validation

Presentation/Feature/ImportSong/          # NEW feature
├── ImportSongState.swift
├── ImportSongIntent.swift
├── ImportSongViewModel.swift
├── ImportSongView.swift
```

### Import flow
```
User taps Import → UIDocumentPickerViewController presents →
User selects files → ImportSongUseCase.execute(urls) →
  1. Hash check against existing songs
  2. Copy file to Documents/Music/
  3. Extract metadata (AVAsset)
  4. Save to CoreData
  5. Publish progress updates
→ Show success/failure per file
```

### Reorder flow
```
PlaylistDetailView.List with .onMove modifier →
PlaylistDetailIntent.reorderSongs(from: IndexSet, to: Int) →
ViewModel → ReorderPlaylistSongsUseCase →
PlaylistRepository.updateSongOrder(playlistId, orderedSongIDs) →
CoreData save
```

## Related Code Files

**Create:**
- `MusicApp/Domain/UseCases/Playlist/ReorderPlaylistSongsUseCase.swift`
- `MusicApp/Domain/UseCases/Playlist/ImportSongFromFilesUseCase.swift` (or add to `TransferUseCase`)
- `MusicApp/Presentation/Feature/ImportSong/` — 4 MVI files

**Modify:**
- `MusicApp/Domain/UseCases/Playlist/AddPlaylistUseCase.swift` — name validation
- `MusicApp/Domain/UseCases/Playlist/UpdatePlaylistUseCase.swift` — delta update
- `MusicApp/Data/Repositories/PlaylistRepository.swift` — sort + reorder
- `MusicApp/Domain/Repositories/PlaylistRepositoryProtocol.swift` — new method signatures
- `MusicApp/Presentation/Feature/PlaylistDetail/` — all 5 MVI files
- `MusicApp/Presentation/Feature/AddNewsPlaylist/` — state + viewmodel
- `MusicApp/Core/DI/DIContainer.swift` — add new use cases
- `MusicApp/Core/DI/AppEnvironment.swift` — wire new use cases in bootstrap

## Implementation Steps

1. **Add `updateSongOrder` to `PlaylistRepositoryProtocol` and `PlaylistRepository`**

2. **Create `ReorderPlaylistSongsUseCase`**

3. **Create `ImportSongFromFilesUseCase`**: handles UIDocumentPicker result URLs → copy → metadata → CoreData

4. **Improve `AddPlaylistUseCase`**: trim whitespace, validate length 1-50, check uniqueness before CoreData write

5. **Improve `PlaylistDetailState`**: add `sortOption`, `isEditMode: Bool`, `selectedSongIDs: Set<UUID>`

6. **Improve `PlaylistDetailIntent`**: add `.reorderSongs(IndexSet, Int)`, `.toggleEditMode`, `.bulkDelete`

7. **Update `PlaylistDetailView`**: add `List { }.onMove { }` for reorder, `.toolbar` edit button, sort menu

8. **Create `ImportSongView`**: button triggers `UIDocumentPickerViewController` via `UIViewControllerRepresentable`

9. **Wire into DIContainer** — add new use cases to `UseCases` struct

10. **Update `AppRoute`**: add `.importSong` route if needed

11. **Build + test all playlist flows**

## Todo List
- [x] Add `updateSongOrder` to PlaylistRepository + Protocol
- [x] Create `ReorderPlaylistSongsUseCase`
- [x] Create `ImportSongFromFilesUseCase`
- [x] Improve `AddPlaylistUseCase` — validation + uniqueness check
- [x] Update `PlaylistDetailState` — add sort, edit mode, selection
- [x] Update `PlaylistDetailIntent` — reorder, bulkDelete, editMode intents
- [x] Update `PlaylistDetailViewModel` — handle new intents
- [x] Update `PlaylistDetailView` — drag reorder + edit mode + sort menu
- [x] Create `ImportSongView` — UIDocumentPickerViewController wrapper
- [x] Wire new use cases into DIContainer
- [x] Verify: create/edit/delete/reorder/import all work
- [x] Build verify

## Success Criteria
- Create playlist with validation (empty name, duplicate name shown as error)
- Drag songs to reorder within playlist; order persists after app restart
- Import mp3/m4a from Files app → appears in library
- Delete playlist shows confirmation
- Build clean

## Risk Assessment
- **Medium** — `UIDocumentPickerViewController` in SwiftUI requires `UIViewControllerRepresentable` wrapper; file copy permissions need careful handling
- **Low** — Reorder via `.onMove` is straightforward SwiftUI
- **Mitigation**: Test file import on physical device, not just simulator

## Security Considerations
- Imported files stored in app's Documents sandbox (not accessible outside app without Files app)
- No network calls — all local file operations
