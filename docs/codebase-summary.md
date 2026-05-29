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
- `ReorderPlaylistSongsUseCase` — Reorder songs within playlist via drag
- `ImportSongFromFilesUseCase` — Import audio files from iOS Files app
- `DeletePlaylistUseCase` — Delete playlist with cleanup
- `SmartPlaylistUseCase` — Filter songs by rules (artist/album/duration/dateAdded)
- `SaveSmartPlaylistUseCase` — Create & persist rule-based smart playlist

**Song Use Cases:**
- `FetchSongUseCase` — Retrieve all songs or by ID
- `AddSongUseCase` — Add new song with metadata extraction
- `UpdateSongUseCase` — Modify song metadata
- `DeleteSongUseCase` — Remove song (with playlist cleanup)

**Lyrics Use Cases:**
- `ParseLrcContentUseCase` — Parse .lrc file (NSRegularExpression, multi-timestamp)
- `FetchLyricsUseCase` — Retrieve synced lyrics for song

**Audio Use Cases:**
- `EQService` — Apply EQ presets/custom gains (3-band: 60Hz, 1kHz, 14kHz)

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
- `SongEntity` — Song file metadata storage (includes dateAdded)
- `SmartPlaylistEntity` — Smart playlist rules & state (id, name, rulesJSON, createdAt)

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
| **Library** | Song browser, search, smart playlists | LibaryView{State,Intent,VM,View} |
| **PlaylistDetail** | Playlist songs, edit, sort, reorder | PlaylistDetail{State,Intent,VM,View} |
| **ImportSong** | File import from Files app | ImportSong{State,Intent,VM,View} |
| **AddPlaylist** | Create new playlist | AddNewPlaylist{State,Intent,VM,View} |
| **SmartPlaylistEditor** | Create rule-based smart playlists | SmartPlaylistEditor{State,Intent,VM,View} |
| **Lyrics** | Display synced .lrc lyrics during playback | LyricsView |
| **Equalizer** | 3-band EQ with presets (Rock/Pop/Classical/Jazz/Custom) | Equalizer{State,Intent,VM,View} |
| **NowPlaying** | Full player screen with lyrics toggle | NowPlaying{State,Intent,VM,View} |

### 5. Services

**Audio Services:**
- `PlayerManager` — Audio playback control (play, pause, seek)
- `AudioEngineService` — AVAudioEngine + AVAudioPlayerNode for low-level audio processing
- `EQService` — Equalizer with 3 frequency bands & preset management (UserDefaults persisted)
- `NowPlayingInfoService` — Lock screen & control center metadata integration

**Data Services:**
- `WebServerGCDService` — WiFi file upload server
- `CoreDataManager` — Database operations (serial queue thread-safety)
- `ImageCacheManager` — Image loading & caching

**UI Services:**
- `PlayerMenuViewModel` / `TimerPickerViewModel` — Sleep timer UI
- `LyricsRepository` — Filesystem storage (Documents/Lyrics/{stem}.lrc)

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

## Recent Changes (Phases 02-04)

### Phase 02: Lyrics Support
- **LyricsLine entity** — Timestamp, text, raw content
- **ParseLrcContentUseCase** — NSRegularExpression parsing, multi-timestamp support, sorted by time
- **FetchLyricsUseCase** — Retrieve & cache synced lyrics
- **LyricsView** — ScrollViewReader auto-scroll, 3s pause on drag, "No lyrics" placeholder
- **NowPlayingFullPlayerView** — Lyrics toggle button (text.quote icon)
- **LyricsRepository** — Filesystem at Documents/Lyrics/{stem}.lrc
- **ImportSongFromFilesUseCase extended** — Save .lrc files alongside audio

### Phase 03: Smart Playlist
- **SmartPlaylistEntity** — CoreData persistence (id, name, rulesJSON, createdAt)
- **RuleField enum** — artist, album, duration, dateAdded
- **RuleOperator enum** — equals, contains, greaterThan, lessThan
- **SmartPlaylistRule & SmartPlaylist domains** — Business models
- **SmartPlaylistRepository** — CoreData + JSON-encoded rules
- **SmartPlaylistUseCase** — NSCompoundPredicate filtering
- **SaveSmartPlaylistUseCase** — Persist new smart playlists
- **SmartPlaylistEditor MVI** — Create & edit rules, live match count preview
- **LibaryView enhanced** — Smart playlists section with ⚡ prefix, FAB wand button
- **AppRoute.smartPlaylistEditor(UUID?)** — Navigation routing

### Phase 04: Equalizer + AVAudioEngine
- **AudioEngineService.swift rewritten** — AVAudioPlayer → AVAudioEngine + AVAudioPlayerNode + AVAudioUnitEQ
- **3-band EQ** — 60Hz (bass), 1kHz (mid), 14kHz (treble) with ±12 dB range
- **EQPreset enum** — Flat, BassBoost, Pop, Rock, Classical, Jazz, Custom
- **EQService (singleton)** — Preset & custom gain management, UserDefaults persistence
- **EqualizerView MVI** — Preset chip row, 3 vertical sliders (-12..+12 dB)
- **AudioEngineService features** — Seek via scheduleSegment + seekOffsetFrames, sample-time currentTime, interruption/route change handling
- **NowPlayingFullPlayerView** — Lyrics toggle integrated
- **Settings → General → Equalizer** — Route to EqualizerView
- **PlayerManager updated** — Uses AudioEngineProtocol (not concrete type)

## Audio Effects Chain

The playback graph runs through an `AVAudioEngine` with effect nodes attached up-front and toggled via `.bypass` (engine never stops → no audible pops):

```
playerNode → timePitch → reverb → eq(10-band) → mainMixer
```

| Service | Node(s) | Responsibility | Key File |
|---------|---------|----------------|----------|
| `AVAudioPlayerEngineService` | engine + `AVAudioPlayerNode` | Build/reconnect graph, load file, seek (scheduleSegment + frame offset), session/interruption/route handling | `Core/AudioEngineService.swift` |
| `EQService` | `AVAudioUnitEQ` (10 bands) | 6 presets + custom, per-band gain, bypass, UserDefaults persist, v1→v2 migration | `Data/Repositories/EQService.swift` |
| `AudioEffectsService` | `AVAudioUnitTimePitch` + `AVAudioUnitReverb` | Speed 0.5–2.0×, pitch ±12 st, reverb preset + wet/dry, auto-bypass when neutral | `Data/Repositories/AudioEffectsService.swift` |

**Entities:** `EQPreset` (ISO 10-band freqs [31…16k] Hz, 6 built-in + custom), `ReverbPreset` (Codable mirror of `AVAudioUnitReverbPreset`).

**EQ migration:** legacy 3-band (`eqGains`) is projected once onto the 10-band layout (`eqGainsV2`) then the legacy key is deleted — `EQService.migrateLegacyGainsIfNeeded`.

**User EQ presets:** `SaveUserEQPresetUseCase` / `LoadUserEQPresetsUseCase` / `DeleteUserEQPresetUseCase` + `UserEQPresetRepository` (`Domain/UseCases/Equalizer/`).

### Audio Editor (non-destructive export)
`Domain/UseCases/AudioEditor/`:
- `ScanWaveformUseCase` — downsampled peaks for the editor scrubber.
- `ComputeNormalizationGainUseCase` — **peak** normalization to 0.95 full-scale, gain clamped [0.5, 3.0], on a detached task.
- `ExportEditedAudioUseCase` — trim (AVMutableComposition) + fade in/out (volume ramps) + normalize (base volume) → **M4A (AAC)** in `Documents/Music/`; progress polling, background task, cancel/fail cleanup.

`AudioEditConfig` holds source URL, trim start/end, fade in/out, normalize flag, output title.

## Import Methods

All external-file routes funnel through one coordinator for consistent dedup/error/toast handling:

```
AirDrop / Open-in / Files-drop ─┐
URL download ───────────────────┼→ ExternalFileImportCoordinator → ImportSongFromFilesUseCase
Web Transfer (GCDWebServer) ────┘     (posts .externalImportFinished)
```

| Method | Entry point | Notes |
|--------|-------------|-------|
| AirDrop / Open-in / Share | `MusicApp.onOpenURL` → `coordinator.handle(openURL:)` | single file from iOS |
| Finder / Files.app drop | `scenePhase==.active` → `coordinator.scanDocumentsRootAndImport()` | scans Documents root, skips managed dirs (Music/Lyrics/Inbox), audio exts only |
| URL download | `DownloadAudioFromURLUseCase` (`Domain/UseCases/Import/`) | **HTTPS-only** sanitize, infers filename, `BackgroundDownloadService`, ingests via `AddSongUseCase`, cancellable |
| Web Transfer (WiFi) | GCDWebServer upload | existing transfer feature |
| Import Hub | `ImportHubView` (`Presentation/Feature/ImportHub/`) | one screen listing routes; reached from Library |

**Coordinator:** `Core/Application/ExternalFileImportCoordinator.swift` — `@MainActor`, `inFlight` guard against concurrent batches, emits `ExternalImportSummary(succeeded:failed:)`.

> Known gaps (see `plans/reports/qa-checklist-260529.md`): Import Hub "Pick from Files" posts `.openImportFromFiles` with no listener (dead action); first-launch routing to Hub is not implemented; Share Extension target add is deferred.

## Lyrics System

`.lrc` files live in `Documents/Lyrics/{stem}.lrc`. Lookup uses a fallback chain so user-friendly mismatches still resolve:

```
exact stem → case-insensitive → normalized (diacritics + [\s_-] collapsed)
```

`LyricsRepository.normalize` lowercases, strips diacritics, removes spaces/underscores/dashes. An in-memory normalized index maps key → on-disk stems; a key shared by 2+ files is treated as **ambiguous** and returns nil (user attaches manually) rather than loading the wrong file.

| Component | Responsibility | File |
|-----------|----------------|------|
| `LyricsRepository` | save/load/delete, normalized index, ambiguity guard | `Data/Repositories/LyricsRepository.swift` |
| `ParseLrcContentUseCase` | regex parse `[mm:ss.xx]` (multi-timestamp), sort by time → `[LyricsLine]` | `Domain/UseCases/Lyrics/` |
| `AttachLyricsToSongUseCase` | attach from file (security-scoped) or pasted text (empty guard), binds to exact stem | `Domain/UseCases/Lyrics/` |
| `RemoveLyricsUseCase` | delete by stem | `Domain/UseCases/Lyrics/` |
| `NowPlayingViewModel.lyricsStem(from:)` | extract decoded filename stem from path/file-URL | `Presentation/Feature/NowPlayingScreen/` |
| `NowPlayingStateReducer.activeLyricIndex(for:in:)` | current line for playhead (nil before first) | `Presentation/Feature/NowPlayingScreen/` |

**Tests:** `MusicAppTests/LyricsStemMatchingTests.swift` covers normalize (incl. Vietnamese "Hạ Trắng"), stem extraction (percent-encoded file URLs), and repository exact + normalized-fallback load.

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
