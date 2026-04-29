# Codebase Summary

MusicOffline-SwiftUI is a modern, offline music player built with SwiftUI and Clean Architecture. This document provides a high-level overview of the project structure, core components, and architectural patterns.

## Project Overview

**Purpose:** Local music storage, playback, and playlist management on iOS devices.

**Tech Stack:** SwiftUI, CoreData, AVFoundation, Combine, GCDWebServer

**Min iOS:** 15.0+ | **Min Xcode:** 13.0+ | **Swift:** 5.5+

## Architecture Pattern

The project follows **Clean Architecture + MVVM** with unidirectional data flow:

```
Presentation ←→ Domain ←→ Data
(Views/VMs)    (UseCases)  (Repositories)
```

Each feature follows **MVI (Model-View-Intent)** pattern:
- **State:** Immutable UI state
- **Intent:** User actions
- **ViewModel:** Business logic + state management
- **Reducer:** State transitions

## Directory Structure

```
MusicApp/
├── Core/                    # Services & dependency injection
│   ├── DI/                  # DIContainer, AppEnvironment
│   ├── Player/              # PlayerManager, audio engine
│   ├── Router/              # Navigation routing
│   ├── Application/         # App launch & lifecycle
│   └── ImageCache/          # Image caching service
├── Domain/                  # Business logic (pure Swift, no iOS deps)
│   ├── Entities/            # Song, Playlist, Album, etc.
│   ├── UseCases/            # Business logic orchestration
│   │   ├── Playlist/        # Playlist CRUD + import/reorder
│   │   ├── SongUseCases/    # Song CRUD operations
│   │   └── Home/            # Home screen data fetching
│   └── Repositories/        # Protocol contracts (no implementation)
├── Data/                    # Data persistence layer
│   ├── Repositories/        # Repository implementations
│   ├── CoreData/            # Entity models & mappers
│   └── Mappers/             # Domain ↔ Entity mapping
├── Presentation/            # UI layer
│   ├── Feature/             # Feature modules (HomeView, PlaylistDetail, etc.)
│   │   ├── PlaylistDetail/  # Playlist viewing & management MVI
│   │   ├── ImportSong/      # Song import feature MVI
│   │   └── ...
│   ├── Model/               # UI-specific models (SongModel, etc.)
│   └── Feature/App/         # App initialization
├── Commons/                 # Shared utilities
│   ├── CustomViews/         # Reusable UI components
│   ├── Extension/           # Foundation extensions
│   ├── Modifiers/           # SwiftUI modifiers
│   ├── Router/              # Navigation protocols
│   └── Logger/              # Logging system
└── DesignSystem/            # Design tokens & theme
    ├── AppColor.swift
    ├── AppFont.swift
    └── DesignToken.swift
```

## Core Components

### 1. Dependency Injection (DIContainer)

Centralized service container manages all dependencies:

**Key Files:**
- `Core/DI/DIContainer.swift` — Main container
- `Core/DI/DIContainer+UseCases.swift` — Use case wiring
- `Core/DI/AppEnvironment.swift` — Global environment setup

**Wired Dependencies:**
- Song use cases (Fetch, Add, Update, Delete)
- Playlist use cases (Fetch, Add, Update, Delete, Reorder, Import)
- Player services (PlayerManager, AVFoundation)
- Repositories (Song, Playlist, Metadata, Image)
- Web server (file uploads)

### 2. Domain Layer

**Entities:**
- `Song` — Audio file metadata (title, artist, duration, file path)
- `Playlist` — Container with name, song IDs, creation date
- `Album` — Album grouping metadata
- `AudioImage` — Album artwork data

**Use Cases:**
Each use case encapsulates a single business operation:

**Playlist Use Cases:**
- `FetchPlaylistUseCase` — List all playlists, with sort options (name, date, count)
- `AddPlaylistUseCase` — Create playlist with validation (name 1-50 chars, trim, uniqueness check)
- `UpdatePlaylistUseCase` — Modify playlist song list
- `ReorderPlaylistSongsUseCase` — NEW: Reorder songs within playlist via drag
- `ImportSongFromFilesUseCase` — NEW: Import audio files from iOS Files app
- `DeletePlaylistUseCase` — Delete playlist with cleanup

**Song Use Cases:**
- `FetchSongUseCase` — Retrieve all songs or by ID
- `AddSongUseCase` — Add new song with metadata extraction
- `UpdateSongUseCase` — Modify song metadata
- `DeleteSongUseCase` — Remove song (with playlist cleanup)

### 3. Data Layer

**Repositories (Implementation):**
- `PlaylistRepository` — CoreData CRUD + sort/reorder ops
- `SongRepository` — Song storage & retrieval
- `SongMetadataRepository` — Metadata extraction from audio files
- `AudioImageRepository` — Album artwork caching

**Sort Options:**
```swift
enum PlaylistSortOption {
    case nameAscending
    case dateCreated
    case songCount
}
```

**CoreData Entities:**
- `PlaylistEntity` — Playlist storage
- `SongEntity` — Song file metadata storage

### 4. Presentation Layer

**Feature Modules (MVI Pattern):**

Each feature directory contains:
- `{Feature}State.swift` — Immutable state struct
- `{Feature}Intent.swift` — User action enum
- `{Feature}ViewModel.swift` — State management
- `{Feature}StateReducer.swift` — Intent → State transitions
- `{Feature}View.swift` — SwiftUI view

**Key Features:**

| Feature | Purpose | MVI Files |
|---------|---------|-----------|
| **Home** | Dashboard, recent playlists | HomeView{State,Intent,VM,View} |
| **Library** | Song browser, search | LibaryView{State,Intent,VM,View} |
| **PlaylistDetail** | Playlist songs, edit, sort, reorder | PlaylistDetail{State,Intent,VM,View} |
| **ImportSong** | NEW: File import from Files app | ImportSong{State,Intent,VM,View} |
| **AddPlaylist** | Create new playlist | AddNewPlaylist{State,Intent,VM,View} |
| **NowPlaying** | Full player screen | NowPlaying{State,Intent,VM,View} |

### 5. Services

**Core Services:**
- `PlayerManager` — Audio playback control (play, pause, seek)
- `WebServerGCDService` — WiFi file upload server
- `CoreDataManager` — Database operations
- `ImageCacheManager` — Image loading & caching
- `PlayerMenuViewModel` / `TimerPickerViewModel` — Sleep timer UI

## Data Flow

### Unidirectional Flow

```
User Action (View) 
→ Intent (ViewModel)
→ Reducer (handle intent, fetch data from use case)
→ New State (ViewModel)
→ View Re-render (display new state)
```

### Example: Reorder Songs in Playlist

1. User drags song in PlaylistDetailView → fires `.reorderSongs(from:to:)` intent
2. PlaylistDetailViewModel receives intent → calls ReorderPlaylistSongsUseCase
3. Use case calls PlaylistRepository.updateSongOrder(playlistId, orderedSongIDs)
4. CoreData updates playlist.songUUIDs array
5. PlaylistEventCenter publishes .updated(playlistId) notification
6. ViewModel updates state → View re-renders with new order

### Example: Import Songs from Files

1. User taps Import → ImportSongView presents UIDocumentPickerViewController
2. User selects audio files → IntentIntent.selectFiles(urls) fires
3. ImportSongViewModel calls ImportSongFromFilesUseCase.execute(urls)
4. Use case:
   - Checks for duplicates (filename hash)
   - Copies files to Documents/Music/
   - Extracts metadata via AVAsset
   - Adds to CoreData via AddSongUseCase
   - Publishes progress updates
5. View shows success/failure per file

## Key Patterns & Conventions

### Protocol-Oriented Design
All external dependencies are abstractions:
```swift
protocol SongRepositoryProtocol { ... }
protocol PlaylistRepositoryProtocol { ... }
protocol AddPlaylistUseCaseProtocol { ... }
```

### Event Publishing
`PlaylistEventCenter` broadcasts playlist changes:
```swift
PlaylistEventCenter.shared.subject.send(.updated(playlistId))
PlaylistEventCenter.shared.subject.send(.deleted(playlistId))
```

### State Reducers
Centralized state mutations:
```swift
// PlaylistDetailStateReducer.swift
static func reduce(state: inout PlaylistDetailState, 
                   action: PlaylistDetailAction) {
    switch action {
    case .reorderSongs(let orderedIDs):
        // Update state
    case .setSortOption(let option):
        state.sortOption = option
    }
}
```

### Validation
Client-side validation in use cases:
```swift
// AddPlaylistUseCase
let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
guard !trimmed.isEmpty else { throw AddPlaylistError.nameEmpty }
guard trimmed.count <= 50 else { throw AddPlaylistError.nameTooLong }
```

## Recent Changes (Phase 04)

**New Features:**
- Reorder songs within playlist via drag & drop
- Import audio files from iOS Files app
- Playlist sort options (name, date created, song count)

**Enhancements:**
- AddPlaylistUseCase: Client-side validation (trim, 1-50 chars, uniqueness check)
- PlaylistRepository: Sort by date, by count
- PlaylistDetail: Edit mode, multi-select, sort menu

**New Code:**
- `ReorderPlaylistSongsUseCase` — Reorder implementation
- `ImportSongFromFilesUseCase` — File import logic
- `ImportSong/` feature module — New MVI feature
- Enhanced `PlaylistDetailState/Intent/ViewModel/View`

## Testing Strategy

- Unit tests for use cases, repositories, view models
- UI tests for critical user flows (create playlist, import songs, reorder)
- No external network calls (all local file operations)

## Build & Run

```bash
pod install
open MusicApp.xcworkspace
# Select simulator/device, press Cmd+R
```

**Common Issues:**
- Pod cache: `rm -rf Pods && pod install`
- Build cache: `Cmd+Shift+K` then rebuild
- CoreData: Simulator reset clears app data; use device for persistence testing

## Next Steps

See development roadmap in `docs/development-roadmap.md` for planned features and phases.
