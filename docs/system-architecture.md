# System Architecture

Comprehensive architecture documentation for MusicOffline-SwiftUI.

## Architectural Layers

### Clean Architecture Model

```
┌─────────────────────────────────────────┐
│   PRESENTATION LAYER (SwiftUI Views)    │
│   Views, ViewModels, State Management   │
└──────────────────┬──────────────────────┘
                   │ Depends on
┌──────────────────▼──────────────────────┐
│   DOMAIN LAYER (Business Logic)         │
│   Use Cases, Entities, Repositories     │
└──────────────────┬──────────────────────┘
                   │ Depends on
┌──────────────────▼──────────────────────┐
│   DATA LAYER (Persistence)              │
│   CoreData, File System, Repositories   │
└─────────────────────────────────────────┘
```

**Dependency Direction:** Outer layers depend on inner layers. Inner layers are independent of outer layers.

### 1. Presentation Layer

**Location:** `MusicApp/Presentation/`

**Responsibility:** UI rendering, user interaction handling, state management.

**Components:**

| Component | Type | Purpose |
|-----------|------|---------|
| `Feature/{Name}/` | Directory | Feature module (MVI pattern) |
| `{Feature}State` | Struct | Immutable state representation |
| `{Feature}Intent` | Enum | User action types |
| `{Feature}ViewModel` | Class | State management + intent handling |
| `{Feature}StateReducer` | Struct | Intent → State transitions |
| `{Feature}View` | SwiftUI | UI component |

**MVI Pattern (Model-View-Intent):**

```
┌─────────────┐    Intent    ┌───────────────┐    Update State
│    View     │─────────────→│  ViewModel    │──────────────────┐
│             │              │               │                   │
└─────────────┘              └───────────────┘                   │
      ▲                                                          │
      │                                                          │
      └──────────────────────────────────────────────────────────┘
                   Publish State
```

**State Management:**
- ViewState is immutable (value type, @Published)
- ViewModel receives Intent → queries use cases → publishes new state
- View listens to @Published state → re-renders
- Reducer handles pure state transitions

**Example Feature: PlaylistDetail**

```swift
// State (immutable)
struct PlaylistDetailState {
    var isLoading: Bool = true
    var songs: [SongModel] = []
    var sortOption: PlaylistSortOption = .nameAscending
    var isEditMode: Bool = false
    var selectedSongIDs: Set<UUID> = []
}

// Intent (user actions)
enum PlaylistDetailIntent {
    case loadPlaylist
    case reorderSongs(from: IndexSet, to: Int)
    case toggleEditMode
    case toggleSongSelection(id: UUID)
    case bulkDelete
    case setSortOption(PlaylistSortOption)
}

// ViewModel (orchestration)
class PlaylistDetailViewModel: ObservableObject {
    @Published var state = PlaylistDetailState()
    
    func send(_ intent: PlaylistDetailIntent) {
        Task {
            let action = await handle(intent)
            // Update state via reducer
        }
    }
}
```

**Available Features:**
- Home — Dashboard with recent playlists
- Library — Song browser, search, smart playlists
- PlaylistDetail — Playlist songs + management
- ImportSong — File import from Files app
- NowPlayingScreen — Full player with lyrics + EQ
- AddPlaylist — Create new playlist
- SmartPlaylistEditor — Rule-based playlist creation
- Lyrics — Synced .lrc display (scroll-follow, drag-pause)
- Equalizer — 3-band EQ with presets
- TransferView — Web upload interface

### 2. Domain Layer

**Location:** `MusicApp/Domain/`

**Responsibility:** Pure business logic, independent of framework.

**Components:**

| Path | Purpose |
|------|---------|
| `Entities/` | Business models (Song, Playlist, Album) |
| `UseCases/` | Business operations (CRUD, import, reorder) |
| `Repositories/` | Protocol contracts (no implementation) |

**Use Case Signature:**

```swift
protocol {Name}UseCaseProtocol {
    func execute(...) async throws -> Result
}

final class {Name}UseCase: {Name}UseCaseProtocol {
    private let repository: RepositoryProtocol
    
    func execute(...) async throws -> Result {
        // Orchestrate domain logic
        // May call multiple repositories
        // Throws domain-level errors
    }
}
```

**Use Case Organization:**

```
Domain/UseCases/
├── Playlist/
│   ├── FetchPlaylistUseCase        # List all playlists
│   ├── AddPlaylistUseCase          # Create + validate
│   ├── UpdatePlaylistUseCase       # Modify songs list
│   ├── ReorderPlaylistSongsUseCase # Drag reorder
│   ├── ImportSongFromFilesUseCase  # File import + .lrc support
│   └── DeletePlaylistUseCase       # Remove playlist
├── SmartPlaylist/
│   ├── SmartPlaylistUseCase        # Filter by rules
│   └── SaveSmartPlaylistUseCase    # Persist smart playlists
├── Lyrics/
│   ├── ParseLrcContentUseCase      # Parse .lrc files (regex)
│   └── FetchLyricsUseCase          # Retrieve synced lyrics
├── SongUseCases/
│   ├── FetchSongUseCase            # Get all/by ID
│   ├── AddSongUseCase              # Add + metadata extract
│   ├── UpdateSongUseCase           # Modify metadata
│   └── DeleteSongUseCase           # Remove song
└── Home/
    └── FetchHomeDataUseCase        # Dashboard data fetch
```

**Error Handling:**

Each use case defines domain-specific errors:

```swift
enum AddPlaylistError: Error {
    case playListNameExtisted
    case nameEmpty
    case nameTooLong
}

enum ImportSongError: Error {
    case unsupportedFormat(String)
    case fileCopyFailed(String, Error)
}
```

**Repository Protocols (No Implementation):**

```swift
protocol PlaylistRepositoryProtocol {
    func fetchAllPlayList(sortBy: PlaylistSortOption) async throws -> [Playlist]
    func updateSongOrder(playlistId: UUID, orderedSongIDs: [UUID]) async throws
    func addPlaylist(with: Playlist) async throws
    // ... other methods
}
```

### 3. Data Layer

**Location:** `MusicApp/Data/`

**Responsibility:** Data persistence, external service calls, entity mapping.

**Components:**

| Path | Purpose |
|------|---------|
| `Repositories/` | Repository implementations |
| `CoreData/` | Entity models, CoreData setup |
| `Mappers/` | Domain ↔ Entity mapping |

**Repository Implementation:**

```swift
final class PlaylistRepository: PlaylistRepositoryProtocol {
    private let coreDataService: CoreDataProtocol
    
    func fetchAllPlayList(sortBy: PlaylistSortOption) async throws -> [Playlist] {
        // 1. Create fetch request
        let fetchRequest: NSFetchRequest<PlaylistEntity> = ...
        
        // 2. Configure sorting per option
        switch sortBy {
        case .nameAscending:
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        case .dateCreated:
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        case .songCount:
            // Sort by count in memory
        }
        
        // 3. Execute on CoreData queue
        return try await coreDataService.performWithSerialQueue { context in
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap(PlaylistEntityMapper.mapToPlayList(_:))
        }
    }
}
```

**Entity Mapping:**

```swift
struct PlaylistEntityMapper {
    static func mapToPlayList(_ entity: PlaylistEntity) -> Playlist {
        Playlist(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            songIDs: entity.songUUIDs,
            createdAt: entity.createdAt ?? Date()
        )
    }
    
    static func makePlaylistEntity(_ domain: Playlist, 
                                   context: NSManagedObjectContext) -> PlaylistEntity {
        let entity = PlaylistEntity(context: context)
        entity.id = domain.id
        entity.name = domain.name
        entity.songUUIDs = domain.songIDs
        entity.createdAt = domain.createdAt
        return entity
    }
}
```

**CoreData Setup:**

```
Data/CoreData/
├── PlaylistEntity+CoreDataClass.swift     # Entity definition
├── PlaylistEntity+CoreDataProperties.swift # Properties
├── SongEntity+CoreDataClass.swift
└── SongEntity+CoreDataProperties.swift
```

## New Features (Phases 02-04)

### Phase 02: Lyrics Support

**Files Created:**
- `Domain/Entities/LyricsLine.swift` — timestamp, text, raw content
- `Domain/Repositories/LyricsRepositoryProtocol.swift`
- `Domain/UseCases/Lyrics/ParseLrcContentUseCase.swift` — NSRegularExpression, multi-timestamp
- `Domain/UseCases/Lyrics/FetchLyricsUseCase.swift` — Retrieve & cache
- `Data/Repositories/LyricsRepository.swift` — Filesystem (Documents/Lyrics/{stem}.lrc)
- `Presentation/Feature/Lyrics/LyricsView.swift` — ScrollViewReader auto-scroll
- `Presentation/Feature/NowPlayingFullPlayerView` — Lyrics toggle button

**Architecture:**

```
Playback event fires (currentTime updated)
  ↓
FetchLyricsUseCase.execute(songId)
  ↓
LyricsRepository reads Documents/Lyrics/{stem}.lrc
  ↓
ParseLrcContentUseCase parses timestamps & text
  ↓
LyricsView auto-scrolls to current line
  ↓
User drags → 3s pause on scroll interaction
```

**.lrc Format:**
```
[00:12.00] Intro text
[00:12.00][00:20.00] Multi-timestamp support
[00:30.50] Next line
```

**Features:**
- ScrollViewReader auto-follows current time
- 3-second pause when user manually scrolls
- "No lyrics" placeholder if file missing
- Integrated in NowPlayingFullPlayerView via lyrics toggle (text.quote icon)
- ImportSongFromFilesUseCase saves .lrc alongside audio

---

### Phase 03: Smart Playlist

**Files Created:**
- `Domain/Entities/SmartPlaylist.swift` — RuleField, RuleOperator, SmartPlaylistRule
- `Domain/Repositories/SmartPlaylistRepositoryProtocol.swift`
- `Data/CoreData/SmartPlaylistEntity.swift` — id, name, rulesJSON, createdAt
- `Data/Repositories/SmartPlaylistRepository.swift` — CoreData + JSON rules
- `Domain/UseCases/SmartPlaylist/SmartPlaylistUseCase.swift` — NSCompoundPredicate filtering
- `Domain/UseCases/SmartPlaylist/SaveSmartPlaylistUseCase.swift` — Create & persist
- `Presentation/Feature/SmartPlaylistEditor/` — MVI (State, Intent, ViewModel, View)
- `Data/CoreData/SongEntity` — Added dateAdded property

**Rule Model:**

```swift
enum RuleField {
    case artist
    case album
    case duration
    case dateAdded
}

enum RuleOperator {
    case equals
    case contains
    case greaterThan
    case lessThan
}

struct SmartPlaylistRule {
    var field: RuleField
    var op: RuleOperator
    var value: String // or Date/TimeInterval
}
```

**Architecture:**

```
SmartPlaylistEditor displays rule editor
  ↓
User adds rules (artist/album/duration/dateAdded)
  ↓
SmartPlaylistEditorIntent.savePlaylist(rules: [SmartPlaylistRule])
  ↓
SaveSmartPlaylistUseCase.execute(name, rules)
  ↓
SmartPlaylistRepository saves to CoreData
  ↓
LibaryView updates with new smart playlist (⚡ prefix)
  ↓
On fetch: SmartPlaylistUseCase builds NSCompoundPredicate
  ↓
SongRepository filters matches
```

**Features:**
- Live match count preview in editor
- ⚡ prefix in LibaryView smart playlists section
- FAB wand button (🪄) to create new smart playlist
- AppRoute.smartPlaylistEditor(UUID?) for navigation

---

### Phase 04: Equalizer + AVAudioEngine

**Files Created/Modified:**
- `Core/AudioEngineService.swift` — **Rewritten** (AVAudioPlayer → AVAudioEngine + AVAudioPlayerNode)
- `Domain/Services/EQServiceProtocol.swift`
- `Data/Services/EQService.swift` — Singleton, 3-band EQ, UserDefaults persistence
- `Presentation/Feature/Equalizer/` — MVI (State, Intent, ViewModel, View)

**Audio Graph:**

```
AVAudioEngine
  ├─ AVAudioPlayerNode (playback with current scheduling)
  ├─ AVAudioUnitEQ (3-band: 60Hz bass, 1kHz mid, 14kHz treble)
  └─ AVAudioOutputNode (device speaker/headphones)

Seek:
  ├─ scheduleSegment(audioFile, startTime: samplerTime)
  ├─ seekOffsetFrames tracking
  └─ currentTime = nodeTime + offset frames → seconds

Interruptions:
  ├─ AVAudioSession.interruptionNotification
  ├─ Route change handling
  └─ mediaServicesResetNotification recovery
```

**EQ Architecture:**

```
EQPreset enum
  ├─ Flat (0, 0, 0 dB)
  ├─ BassBoost (+6, 0, -3 dB)
  ├─ Pop (+2, +4, -1 dB)
  ├─ Rock (+3, +1, +2 dB)
  ├─ Classical (-1, -2, +3 dB)
  ├─ Jazz (+2, +3, +1 dB)
  └─ Custom (user-defined)

EqualizerView
  ├─ Preset chip row (selectable)
  ├─ 3 vertical sliders (-12..+12 dB)
  └─ Live preview with AudioEngineService

EQService (Singleton)
  ├─ Apply gains to AVAudioUnitEQ
  ├─ Persist UserDefaults (lastPreset, customGains)
  └─ Restore on app launch
```

**Settings Integration:**
- Settings → General → "Equalizer" row
- Navigates to EqualizerView via AppRoute.equalizer
- DIContainer wired with EQService

**PlayerManager Updates:**
- Uses AudioEngineProtocol (not concrete AudioEngineService type)
- Dependency injection ensures testability

## Dependency Injection

**Location:** `Core/DI/`

**Container Setup:**

```swift
final class DIContainer {
    var useCases: UseCases
    var repositories: Repositories
    var services: Services
    
    static func bootstrap() -> DIContainer {
        let coreDataManager = CoreDataManager.shared
        let songRepository = SongRepository(coreDataManager: coreDataManager)
        let playlistRepository = PlaylistRepository(coreDataManager: coreDataManager)
        
        let useCases = UseCases.create(
            songRepository: songRepository,
            playlistRepository: playlistRepository,
            ...
        )
        
        return DIContainer(
            useCases: useCases,
            repositories: ...,
            services: ...
        )
    }
}
```

**Use Case Wiring (Phases 02-04):**

```swift
// DIContainer+UseCases.swift
let lyrics = (
    parse: ParseLrcContentUseCase(),
    fetch: FetchLyricsUseCase(repository: lyricsRepository)
)
let smartPlaylist = (
    fetch: SmartPlaylistUseCase(repository: smartPlaylistRepository),
    save: SaveSmartPlaylistUseCase(repository: smartPlaylistRepository)
)
let eqService = EQService()

return UseCases(
    ...
    lyricsUseCases: lyrics,
    smartPlaylistUseCases: smartPlaylist,
    eqService: eqService,
    ...
)
```

**Access in ViewModels:**

```swift
@Environment(\.container) var container

func fetchPlaylists() {
    let playlists = try await container.useCases.fetchPlaylistUseCase.execute()
}
```

## Networking & Services

### Web Server (File Upload)

**Service:** `WebServerGCDService`
- Handles WiFi file uploads
- Uses GCDWebServer framework
- Runs on device background

**Flow:**
1. User starts web server in Settings
2. Displays device IP & port
3. Computer connects to `http://{ip}:{port}`
4. Upload files through web UI
5. Files saved to app Documents via `DocumentFileManager`

### Audio Engine (AVAudioEngine graph)

Playback runs through an `AVAudioEngine` graph, not a plain `AVPlayer`. Effect nodes are attached up-front and toggled with `.bypass` so the engine never stops at runtime (avoids audible pops):

```
playerNode → AVAudioUnitTimePitch → AVAudioUnitReverb → AVAudioUnitEQ(10-band) → mainMixer
```

**Service:** `PlayerManager`
- Depends on `AudioEngineProtocol` (not a concrete type)
- Playback control (play, pause, seek, skip), shuffle & repeat, background playback

**Service:** `AVAudioPlayerEngineService` (`Core/AudioEngineService.swift`)
- Owns the engine + `AVAudioPlayerNode`; builds the graph and **reconnects the whole chain with the file's native format on each `load`** to avoid sample-rate-conversion artifacts.
- Seek via `scheduleSegment(startingFrame:)` + `seekOffsetFrames`; `currentTime` derived from `playerTime` sample-time.
- Handles `AVAudioSession` `.playback`, interruption (pause/resume on `.shouldResume`), route change (pause on old-device-unavailable), and media-services-reset (rebuild graph + reload).

**Service:** `EQService` — owns `AVAudioUnitEQ` (10 bands, lowShelf/parametric/highShelf), presets + per-band gain, bypass, UserDefaults persist, v1→v2 migration.

**Service:** `AudioEffectsService` — owns `AVAudioUnitTimePitch` (speed + pitch, single node, auto-bypass when neutral) and `AVAudioUnitReverb` (factory preset + wet/dry, auto-bypass when wet<0.5).

**Service:** `NowPlayingInfoService`
- Lock screen & control center integration
- Metadata display in system UI

### Audio Editor Export

`ExportEditedAudioUseCase` produces a non-destructive edited copy:
1. `AVMutableComposition` inserts the trimmed time range (timescale 600).
2. `AVMutableAudioMix` applies base volume (= normalize gain when enabled) + fade-in/out volume ramps in composition coordinate space.
3. `AVAssetExportSession` (preset `AppleM4A`) writes **M4A/AAC** to a uniquified path in `Documents/Music/`.
4. A `UIApplication` background task spans the export; progress polled every 200 ms; cancel/fail removes the partial file.

Normalization is **peak-based** (`ComputeNormalizationGainUseCase`: scan peak → `0.95/peak`, clamp [0.5, 3.0]), not LUFS — chosen for cheap single-pass computation without loudness libraries.

### External File Import Flow

Every "file from outside" route converges on one coordinator:

```
AirDrop / Open-in / Share  ─ MusicApp.onOpenURL ─────────────┐
Finder / Files.app drop    ─ scenePhase .active scan ────────┤
URL download (HTTPS)       ─ DownloadAudioFromURLUseCase ─────┼→ ExternalFileImportCoordinator
Web Transfer (GCDWebServer)─ upload ─────────────────────────┘        │
Import Hub (manual)        ─ ImportHubView routes ────────────────────┤
                                                                       ▼
                                          ImportSongFromFilesUseCase (dedup, metadata, .lrc sidecar)
                                                                       │
                                                       posts .externalImportFinished(ExternalImportSummary)
```

`ExternalFileImportCoordinator` is `@MainActor`, guards against concurrent batches (`inFlight`), and on a Documents-root scan skips managed subfolders (`Music`, `Lyrics`, `Inbox`) and non-audio files.

## Event Publishing

**Event Center:** `PlaylistEventCenter`

```swift
enum PlaylistEvent {
    case updated(UUID)   // Playlist updated
    case deleted(UUID)   // Playlist deleted
}

// Broadcast change
PlaylistEventCenter.shared.subject.send(.updated(playlistId))

// Subscribe
PlaylistEventCenter.shared.subject
    .sink { event in
        // Handle event
    }
```

Used by:
- ReorderPlaylistSongsUseCase — Publish after reorder
- DeletePlaylistUseCase — Publish after delete
- Listeners: PlaylistDetail, Library views

## Threading Model

**Main Thread:**
- All UI updates via @Published properties
- ViewModel state changes on main thread

**Background Threads:**
- Use cases execute async/await (background by default)
- CoreData uses serial dispatch queue (`performWithSerialQueue`)
- File I/O via background threads
- Audio processing on dedicated AVAudioSession

**Thread-Safe Access:**
```swift
coreDataService.performWithSerialQueue { context in
    // Always on serial queue, safe to modify
    let entity = try context.fetch(...)
    context.save()
}
```

## Design System

**Location:** `DesignSystem/`

**Tokens:**
- `AppColor` — Color palette
- `AppFont` — Typography
- `DesignToken` — Spacing, sizing, corner radius

**Usage:**
```swift
Text("Playlist").font(AppFont.title1)
    .foregroundColor(AppColor.text)
    .padding(.horizontal, DesignToken.spacing.medium)
```

## Security Considerations

### Data Storage
- Songs stored in app Documents (sandboxed)
- CoreData encrypted at rest (on device)
- No cloud sync (offline-first design)

### File Access
- UIDocumentPickerViewController for user file selection
- No arbitrary file system access
- Files copied to app sandbox

### Audio Permissions
- Background audio requires Info.plist configuration
- AVAudioSession setup in PlayerManager
- File sharing via iTunes requires entitlements

## Performance Optimization

### Image Caching
- `ImageCacheManager` caches album artwork
- In-memory + disk cache
- Prevents repeated metadata extraction

### CoreData Optimization
- Serial queue prevents race conditions
- Batch operations for bulk updates
- Fetch requests use predicates for filtering

### Playlist Song Order
- Preserves order via songUUIDs array in CoreData
- Order NOT dependent on song fetch order
- Reorder updates array directly

## Testing Architecture

**Testable by Design:**
- All dependencies are protocols
- Use cases accept repository protocols
- Mock repositories for unit testing

**Example Test:**
```swift
let mockRepository = MockPlaylistRepository()
let useCase = AddPlaylistUseCase(repository: mockRepository)

// Test validation
XCTAssertThrowsError(try await useCase.execute(with: ""))
XCTAssertThrowsError(try await useCase.execute(with: String(repeating: "a", count: 51)))
```

## Deployment Notes

**Build Configuration:**
- Min target: iOS 15.0
- Swift 5.5+
- Dynamic frameworks enabled (Podfile)

**Pre-release Checklist:**
- Run all tests: `xcodebuild test -scheme MusicApp`
- Build cache clean: `Cmd+Shift+K`
- CoreData migration (if schema changed)
- Test on physical device (simulator limitations with file access)

## Future Improvements

See `docs/development-roadmap.md` for planned architecture changes and new features.
