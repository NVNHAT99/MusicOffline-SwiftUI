# Code Standards & Guidelines

Codebase standards for MusicOffline-SwiftUI development. Follow these guidelines for all code contributions.

## Naming Conventions

### Swift Files
Use **PascalCase** for file names matching the primary class/struct:
- `PlayerManager.swift` — Contains PlayerManager class
- `PlaylistRepository.swift` — Contains PlaylistRepository class
- `AddPlaylistUseCase.swift` — Contains AddPlaylistUseCase class

**Exception:** Protocol files can use descriptive names:
- `PlaylistRepositoryProtocol.swift` — Protocol definition
- Use PascalCase for the protocol file name

### Swift Identifiers
- **Classes/Structs/Enums:** PascalCase (PlaylistDetail, SongModel, ImportSongError)
- **Functions/Variables:** camelCase (fetchPlaylist(), isLoading, selectedSongIDs)
- **Constants:** UPPER_SNAKE_CASE (CACHE_SIZE, DEFAULT_TIMEOUT)
- **Enum cases:** camelCase (case playing, case paused, case failed)

**Examples:**
```swift
// Correct
class PlaylistDetailViewModel { ... }
func fetchAllPlaylists() { ... }
var isEditMode: Bool = false
let MAX_PLAYLIST_SIZE = 1000

// Incorrect
class playlistDetailViewModel { ... }
func fetch_all_playlists() { ... }
var IsEditMode: Bool = false
```

### Feature Modules
Organize by feature with consistent naming:
```
Presentation/Feature/{FeatureName}/
├── {Feature}State.swift          # State immutable struct
├── {Feature}Intent.swift         # Intent enum
├── {Feature}ViewModel.swift      # ViewModel class
├── {Feature}StateReducer.swift   # State transition logic
└── {Feature}View.swift           # SwiftUI view
```

**Examples:**
- PlaylistDetail → PlaylistDetailState, PlaylistDetailIntent, PlaylistDetailViewModel
- ImportSong → ImportSongState, ImportSongIntent, ImportSongViewModel
- AddPlaylist → AddPlaylistState, AddPlaylistIntent, AddPlaylistViewModel

### Directories
Use kebab-case for feature directories (iOS convention):
```
Presentation/Feature/add-playlist/
Presentation/Feature/playlist-detail/
Presentation/Feature/now-playing-screen/
```

Actually, current convention in codebase is **PascalCase** for feature dirs. Follow existing pattern:
```
Presentation/Feature/AddNewsPlaylist/
Presentation/Feature/PlaylistDetail/
Presentation/Feature/NowPlayingScreen/
```

## Code Organization

### File Structure

**Use Case File Template:**
```swift
//
//  {Name}UseCase.swift
//  MusicApp
//

import Foundation

enum {Name}Error: Error {
    case errorCase1
    case errorCase2
}

protocol {Name}UseCaseProtocol {
    func execute(...) async throws -> Result
}

final class {Name}UseCase: {Name}UseCaseProtocol {
    private let repository: RepositoryProtocol

    init(repository: RepositoryProtocol = DefaultRepository()) {
        self.repository = repository
    }

    func execute(...) async throws -> Result {
        // Implementation
    }
}
```

**ViewModel File Template:**
```swift
//
//  {Feature}ViewModel.swift
//  MusicApp
//

import Foundation
import Combine

final class {Feature}ViewModel: ObservableObject {
    @Published var state = {Feature}State()
    
    private let useCase: UseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    init(useCase: UseCaseProtocol) {
        self.useCase = useCase
    }

    func send(_ intent: {Feature}Intent) {
        Task {
            await handle(intent)
        }
    }

    private func handle(_ intent: {Feature}Intent) async {
        // Handle intent, update state
    }
}
```

**View File Template:**
```swift
//
//  {Feature}View.swift
//  MusicApp
//

import SwiftUI

struct {Feature}View: View {
    @StateObject private var viewModel: {Feature}ViewModel
    @Environment(\.container) var container

    init(viewModel: {Feature}ViewModel = {Feature}ViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            // UI content
        }
        .onAppear { viewModel.send(.onLoad) }
    }
}

#Preview {
    {Feature}View()
}
```

### Import Organization
Group imports by category, order: Foundation → iOS frameworks → App modules:

```swift
// Foundation & Standard Library
import Foundation
import Combine

// Apple Frameworks
import SwiftUI
import CoreData
import AVFoundation

// App Modules
import Domain
import Data
```

### Line Length
- **Preferred:** 100-120 characters
- **Maximum:** 150 characters (before wrap)
- Break long method signatures across multiple lines

```swift
// Preferred
func updatePlaylist(id: UUID,
                    name: String,
                    songIDs: [UUID]) async throws {
    // Implementation
}

// Acceptable (if fits in 120 chars)
func updatePlaylist(id: UUID, name: String) async throws { }
```

## Code Style

### Spacing
- Use 4 spaces for indentation (NOT tabs)
- Add blank line between methods
- Add blank line between logical sections

```swift
class PlaylistViewModel {
    // Section 1: Properties
    @Published var state = PlaylistState()
    private let useCase: PlaylistUseCase

    // Section 2: Initialization
    init(useCase: PlaylistUseCase) {
        self.useCase = useCase
    }

    // Section 3: Public Methods
    func send(_ intent: PlaylistIntent) {
        // ...
    }

    // Section 4: Private Methods
    private func handle(_ intent: PlaylistIntent) {
        // ...
    }
}
```

### Comments
Use comments for **why**, not **what**:

```swift
// Good: Explains intent
// Fetch with descending date to show newest first
let descriptor = NSSortDescriptor(key: "createdAt", ascending: false)

// Bad: Just restates code
// Create sort descriptor
let descriptor = NSSortDescriptor(key: "createdAt", ascending: false)
```

**MARK Comments:** Organize large classes

```swift
final class PlaylistViewModel {
    // MARK: - Properties
    @Published var state = PlaylistState()

    // MARK: - Initialization
    init() { }

    // MARK: - Public Methods
    func send(_ intent: PlaylistIntent) { }

    // MARK: - Private Methods
    private func handle(_ intent: PlaylistIntent) { }
}
```

### Access Control
- Mark all properties private by default
- Expose only what's needed for testing/dependency injection
- Use `fileprivate` rarely; prefer `private`

```swift
final class PlaylistRepository {
    // Private dependencies
    private let coreDataService: CoreDataProtocol
    
    // Public for injection
    init(coreDataService: CoreDataProtocol = CoreDataManager.shared) {
        self.coreDataService = coreDataService
    }
}
```

## Architectural Patterns

### 1. Use Case Pattern

**Requirements:**
- Single responsibility (one use case = one operation)
- Protocol-based (UseCaseProtocol)
- Async/await for I/O operations
- Domain-specific error enums

```swift
protocol AddPlaylistUseCaseProtocol {
    func execute(with name: String) async throws
}

final class AddPlaylistUseCase: AddPlaylistUseCaseProtocol {
    private let repository: PlaylistRepositoryProtocol

    func execute(with name: String) async throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AddPlaylistError.nameEmpty }
        guard trimmed.count <= 50 else { throw AddPlaylistError.nameTooLong }
        
        if let _ = try await repository.fetchPlaylist(with: trimmed) {
            throw AddPlaylistError.playListNameExtisted
        }
        
        try await repository.addPlaylist(with: Playlist(
            id: UUID(),
            name: trimmed,
            songIDs: []
        ))
    }
}
```

### 2. Repository Pattern

**Requirements:**
- Protocol defines contracts (no implementation)
- Implementation handles persistence details
- Async operations for I/O
- CoreData encapsulation

```swift
protocol PlaylistRepositoryProtocol {
    func fetchAllPlayList(sortBy: PlaylistSortOption) async throws -> [Playlist]
    func updateSongOrder(playlistId: UUID, orderedSongIDs: [UUID]) async throws
    func addPlaylist(with: Playlist) async throws
}

final class PlaylistRepository: PlaylistRepositoryProtocol {
    private let coreDataService: CoreDataProtocol

    func fetchAllPlayList(sortBy: PlaylistSortOption = .nameAscending) 
        async throws -> [Playlist] {
        return try await coreDataService.performWithSerialQueue { context in
            let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
            // Configure sort descriptor based on sortBy parameter
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap(PlaylistEntityMapper.mapToPlayList(_:))
        }
    }
}
```

### 3. MVI Pattern (Model-View-Intent)

**Structure:**
- **State:** Immutable, value type (struct)
- **Intent:** User action enum
- **ViewModel:** ObservableObject, coordinates state changes
- **StateReducer:** Pure functions for state transitions
- **View:** SwiftUI, reactive to state changes

```swift
// State
struct PlaylistDetailState {
    var songs: [Song] = []
    var isLoading: Bool = false
    var sortOption: SortOption = .nameAscending
    var isEditMode: Bool = false
}

// Intent
enum PlaylistDetailIntent {
    case loadPlaylist
    case reorderSongs(from: IndexSet, to: Int)
    case toggleEditMode
}

// ViewModel
class PlaylistDetailViewModel: ObservableObject {
    @Published var state = PlaylistDetailState()
    
    func send(_ intent: PlaylistDetailIntent) {
        Task {
            let action = await handle(intent)
            PlaylistDetailStateReducer.reduce(&state, action: action)
        }
    }
}

// View
struct PlaylistDetailView: View {
    @StateObject private var viewModel: PlaylistDetailViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.state.songs) { song in
                Text(song.title)
            }
            .onMove { from, to in
                viewModel.send(.reorderSongs(from: from, to: to))
            }
        }
    }
}
```

### 4. Dependency Injection Pattern

**Rules:**
- All dependencies via initializer injection
- Use protocols for abstraction
- DIContainer for bootstrap

```swift
final class PlaylistViewModel {
    private let fetchUseCase: FetchPlaylistUseCaseProtocol
    private let addUseCase: AddPlaylistUseCaseProtocol

    init(
        fetchUseCase: FetchPlaylistUseCaseProtocol,
        addUseCase: AddPlaylistUseCaseProtocol
    ) {
        self.fetchUseCase = fetchUseCase
        self.addUseCase = addUseCase
    }
}

// In DIContainer
let viewModel = PlaylistViewModel(
    fetchUseCase: container.useCases.fetchPlaylistUseCase,
    addUseCase: container.useCases.addPlaylistUseCase
)
```

## Error Handling

### Error Enum Pattern
Define domain-specific errors in each layer:

```swift
// Domain Layer
enum AddPlaylistError: Error {
    case nameEmpty
    case nameTooLong
    case playListNameExtisted
}

// Data Layer
enum CoreDataError: Error {
    case saveFailed(Error)
    case deleteFailed(Error)
    case entityNotFound
}

// Presentation Layer
enum ImportError: Error, LocalizedError {
    case unsupportedFormat(String)
    case fileCopyFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return "File format not supported: \(format)"
        case .fileCopyFailed(let filename):
            return "Failed to copy file: \(filename)"
        }
    }
}
```

### Error Propagation
Use `async throws` for operations that can fail:

```swift
func execute(with name: String) async throws {
    guard !name.isEmpty else { throw AddPlaylistError.nameEmpty }
    try await repository.addPlaylist(with: playlist)
}

// In ViewModel
func send(_ intent: Intent) {
    Task {
        do {
            try await useCase.execute(with: name)
            state.isSuccess = true
        } catch let error as AddPlaylistError {
            state.errorMessage = error.localizedDescription
        }
    }
}
```

## Testing Standards

### Unit Test Template
```swift
final class AddPlaylistUseCaseTests: XCTestCase {
    var sut: AddPlaylistUseCase!
    var mockRepository: MockPlaylistRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockPlaylistRepository()
        sut = AddPlaylistUseCase(repository: mockRepository)
    }

    func testExecute_withEmptyName_throwsError() async throws {
        XCTAssertThrowsError(try await sut.execute(with: ""))
    }

    func testExecute_withLongName_throwsError() async throws {
        let longName = String(repeating: "a", count: 51)
        XCTAssertThrowsError(try await sut.execute(with: longName))
    }

    func testExecute_withValidName_callsRepository() async throws {
        try await sut.execute(with: "My Playlist")
        XCTAssertTrue(mockRepository.addPlaylistCalled)
    }
}
```

### Mock Repository Pattern
```swift
class MockPlaylistRepository: PlaylistRepositoryProtocol {
    var addPlaylistCalled = false
    var addPlaylistCount = 0

    func addPlaylist(with playlist: Playlist) async throws {
        addPlaylistCalled = true
        addPlaylistCount += 1
    }

    // Implement remaining protocol methods
    // ...
}
```

## Performance Guidelines

### Avoid N+1 Queries
Fetch all data in one query, not in a loop:

```swift
// Bad
for playlistID in playlistIDs {
    let playlist = try await repository.fetchPlaylist(id: playlistID)
}

// Good
let playlists = try await repository.fetchPlaylists(ids: playlistIDs)
```

### Use Async/Await
Never block main thread:

```swift
// Bad
let result = try repository.fetchPlaylist() // Synchronous

// Good
let result = try await repository.fetchPlaylist() // Asynchronous
```

### Image Caching
Always cache images to prevent re-fetching:

```swift
// ImageCacheManager handles disk + memory cache
let image = try await imageCacheManager.image(for: song)
```

## Security Checklist

- [ ] No hardcoded credentials, API keys, or secrets
- [ ] All file operations use sandboxed Documents directory
- [ ] CoreData is encrypted at rest
- [ ] No user data leaked in logs
- [ ] Validate file formats before processing
- [ ] Use UIDocumentPickerViewController for user file selection (not arbitrary access)

## Code Review Checklist

Before submitting PR, verify:

- [ ] Follows naming conventions (PascalCase for classes, camelCase for functions)
- [ ] Has proper error handling (domain-specific errors)
- [ ] Protocol-based dependencies (testable)
- [ ] Async/await for I/O (no blocking)
- [ ] Unit tests for business logic
- [ ] No console warnings or errors
- [ ] Max file size < 200 LOC (consider splitting)
- [ ] Comments explain "why", not "what"
- [ ] No console logging left in (use proper logging framework)
- [ ] All imports organized & necessary
- [ ] Backward compatible (or documented breaking change)

## Common Pitfalls

### 1. Mixing Concerns
```swift
// Bad: View directly accesses repository
class SongListView: View {
    let repository = SongRepository()
    var songs = repository.fetchAllSongs() // No, use ViewModel
}

// Good: ViewModel mediates
class SongListViewModel {
    let repository: SongRepositoryProtocol
    @Published var songs = [Song]()
    
    func loadSongs() async {
        songs = try await repository.fetchAllSongs()
    }
}
```

### 2. Mutable State
```swift
// Bad: Mutable state in struct
struct PlaylistState {
    var songs: [Song] = []
    
    mutating func add(_ song: Song) { // No mutations
        songs.append(song)
    }
}

// Good: Immutable state, new instances via reducer
struct PlaylistState {
    let songs: [Song] = []
}

// State changes via immutable creation
var newState = state
newState.songs = newState.songs + [song]
```

### 3. Blocking Main Thread
```swift
// Bad: Blocking UI
DispatchQueue.main.sync {
    // This blocks!
}

// Good: Async callbacks
Task {
    let result = try await someAsyncOperation()
    await MainActor.run {
        state = result
    }
}
```

### 4. Over-Engineering
```swift
// Bad: Too many layers for simple operation
class PlaylistSortStrategyFactory { }
class SortStrategySelector { }
class PlaylistSortOrchestrator { }

// Good: Direct, clear approach
func sortPlaylists(_ playlists: [Playlist], 
                   by option: SortOption) -> [Playlist] {
    switch option {
    case .nameAscending:
        return playlists.sorted { $0.name < $1.name }
    // ...
    }
}
```

## Documentation Requirements

### Function Documentation
Document public functions with brief description and parameters:

```swift
/// Fetches all playlists from storage, sorted by option.
/// - Parameter sortBy: Sort order (name, date, or count)
/// - Returns: Array of playlists, empty if none exist
/// - Throws: CoreDataError if fetch fails
func fetchAllPlayList(sortBy: PlaylistSortOption = .nameAscending) 
    async throws -> [Playlist]
```

### Inline Comments
Explain non-obvious logic:

```swift
// Skip duplicate files based on filename hash
// This prevents importing the same file multiple times
let isDuplicate = existingHashes.contains(fileHash)
```

---

**Last Updated:** 2026-04-29 by docs-manager

**Next Review:** 2026-05-15 (Phase 05 planning)
