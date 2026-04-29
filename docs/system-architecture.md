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
- Library — Song browser & search
- PlaylistDetail — Playlist songs + management
- ImportSong — NEW: File import from Files app
- NowPlayingScreen — Full player interface
- AddPlaylist — Create new playlist
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
│   ├── ReorderPlaylistSongsUseCase # NEW: Drag reorder
│   ├── ImportSongFromFilesUseCase  # NEW: File import
│   └── DeletePlaylistUseCase       # Remove playlist
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

## New Features (Phase 04)

### Reorder Playlist Songs

**Files Modified:**
- `ReorderPlaylistSongsUseCase.swift` — NEW
- `PlaylistRepository.swift` — Added `updateSongOrder()`
- `PlaylistDetailState/Intent/ViewModel/View` — Reorder UI

**Flow:**

```
User drags song
  ↓
PlaylistDetailView.onMove fires
  ↓
Intent.reorderSongs(from: IndexSet, to: Int)
  ↓
PlaylistDetailViewModel.send(intent)
  ↓
ReorderPlaylistSongsUseCase.execute(playlistId, orderedSongIDs)
  ↓
PlaylistRepository.updateSongOrder(playlistId, orderedSongIDs)
  ↓
CoreData: Update playlist.songUUIDs array
  ↓
PlaylistEventCenter publishes .updated(playlistId)
  ↓
View re-renders with new order
```

**Sort Options:**

```swift
enum PlaylistSortOption {
    case nameAscending       // A-Z by song name
    case dateCreated         // Newest first
    case songCount           // Most songs first
}
```

Sorting happens in PlaylistRepository.fetchAllPlayList(sortBy:).

### Import Songs from Files

**Files Created:**
- `ImportSongFromFilesUseCase.swift`
- `ImportSong/` feature module (State, Intent, ViewModel, View)

**Architecture:**

```
ImportSongView (UIDocumentPickerViewController wrapper)
  ↓ User selects files
ImportSongIntent.selectFiles([URL])
  ↓
ImportSongViewModel.send(intent)
  ↓
ImportSongFromFilesUseCase.execute(urls: [URL]) async throws -> [ImportResult]
  ├─ For each file:
  │  ├─ Check duplicate (filename hash)
  │  ├─ Copy to Documents/Music/
  │  ├─ Extract metadata (AVAsset)
  │  ├─ Add to CoreData via AddSongUseCase
  │  └─ Publish progress
  ↓
State.importResults: [ImportResult]
  ├─ .success(Song)
  ├─ .failure(String, Error)

View displays results per file
```

**Supported Formats:**
- mp3, m4a, wav, flac, aac, ogg

**Duplicate Detection:**
- Filename-based (hash comparison)
- Prevents duplicate file copies

**Error Handling:**
```swift
enum ImportSongError: Error {
    case unsupportedFormat(String)
    case fileCopyFailed(String, Error)
    case metadataExtractionFailed(String)
    case addSongFailed(String, Error)
}
```

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

**Use Case Wiring (Phase 04 Changes):**

```swift
// DIContainer+UseCases.swift
let reorderSongs = ReorderPlaylistSongsUseCase(repository: playlistRepository)
let importSong = ImportSongFromFilesUseCase(addSongUseCase: addSong)

return UseCases(
    ...
    reorderPlaylistSongsUseCase: reorderSongs,
    importSongFromFilesUseCase: importSong,
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

### Audio Engine

**Service:** `PlayerManager`
- AVPlayer wrapper
- Playback control (play, pause, seek, skip)
- Shuffle & repeat modes
- Background playback support

**Service:** `AudioEngineService`
- Alternative audio engine (optional)

**Service:** `NowPlayingInfoService`
- Lock screen & control center integration
- Metadata display in system UI

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
