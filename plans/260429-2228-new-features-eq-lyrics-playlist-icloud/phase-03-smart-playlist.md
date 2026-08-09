# Phase 03 — Smart Playlist (Rule-Based)

## Context Links
- `MusicApp/Presentation/Feature/Library/LibaryViewViewModel.swift`
- `MusicApp/Domain/Repository/PlaylistRepositoryProtocol.swift`
- CoreData model file

## Overview
- **Priority:** P2
- **Status:** ✅ complete
- **Effort:** 3 days
- **Risk:** Medium (CoreData schema additive)

Rule-based playlists: user defines field/operator/value rules; CoreData fetches matching songs via NSCompoundPredicate at view time. No ML.

## Requirements
### Functional
- Create/edit/delete smart playlists.
- Rules: field ∈ {artist, album, duration, dateAdded}, operator ∈ {equals, contains, greaterThan, lessThan}, value: String.
- Combine rules via AND (v1; OR can come later).
- Live preview: show count of matching songs as user edits.
- Smart playlists appear in Library list, marked with ⚡ icon.
- Tapping smart playlist plays/lists current matches.

### Non-Functional
- Predicate evaluated lazily on view; not persisted-derived.
- Schema migration must be additive; existing Song entity untouched.

## Architecture
```
SmartPlaylistEditorView
  ├─ rules: [SmartPlaylistRule] @State
  ├─ live preview: SmartPlaylistUseCase.execute(rules) → count
  └─ Save → SmartPlaylistRepository.save(SmartPlaylist)

LibraryView load:
  ├─ regular playlists (existing)
  └─ smart playlists (new) → on tap → resolve to [Song] via UseCase
```

### Entities
```swift
enum RuleField: String, Codable { case artist, album, duration, dateAdded }
enum RuleOperator: String, Codable { case equals, contains, greaterThan, lessThan }

struct SmartPlaylistRule: Codable, Equatable {
    let field: RuleField
    let `operator`: RuleOperator
    let value: String
}

struct SmartPlaylist: Identifiable, Equatable {
    let id: UUID
    var name: String
    var rules: [SmartPlaylistRule]
    var createdAt: Date
}
```

### CoreData
- New `SmartPlaylistEntity`: id (UUID), name (String), rulesJSON (String — encoded `[SmartPlaylistRule]`), createdAt (Date).
- Lightweight migration (additive entity).

### Predicate Builder
```
artist equals "X"     → NSPredicate(format: "artist == %@", "X")
album contains "Y"    → NSPredicate(format: "album CONTAINS[cd] %@", "Y")
duration greaterThan  → NSPredicate(format: "duration > %@", NSNumber(value: Double(value)))
dateAdded lessThan    → NSPredicate(format: "dateAdded < %@", date from value)
```
Numeric/date parse failures → rule skipped (logged), don't crash.

## Related Code Files
### Create
- `MusicApp/Domain/Entity/SmartPlaylist.swift`
- `MusicApp/Domain/Entity/SmartPlaylistRule.swift`
- `MusicApp/Domain/Repository/SmartPlaylistRepositoryProtocol.swift`
- `MusicApp/Data/Repository/SmartPlaylistRepository.swift`
- `MusicApp/Domain/UseCase/SmartPlaylistUseCase.swift` (rules → [Song])
- `MusicApp/Domain/UseCase/SaveSmartPlaylistUseCase.swift`
- `MusicApp/Presentation/Feature/SmartPlaylistEditor/SmartPlaylistEditorView.swift`
- `MusicApp/Presentation/Feature/SmartPlaylistEditor/State/SmartPlaylistEditorState.swift`
- `MusicApp/Presentation/Feature/SmartPlaylistEditor/State/SmartPlaylistEditorIntent.swift`
- `MusicApp/Presentation/Feature/SmartPlaylistEditor/State/SmartPlaylistEditorStateAction.swift`
- `MusicApp/Presentation/Feature/SmartPlaylistEditor/State/SmartPlaylistEditorStateReducer.swift`
- `MusicApp/Presentation/Feature/SmartPlaylistEditor/SmartPlaylistEditorViewModel.swift`

### Modify
- `MusicApp/Presentation/Feature/Library/LibaryViewViewModel.swift` — load + display smart playlists.
- `MusicApp/Presentation/Feature/Library/LibraryView.swift` — render with ⚡ icon.
- `MusicApp/Domain/Repository/PlaylistRepositoryProtocol.swift` — extend or add sibling protocol.
- CoreData `.xcdatamodeld` — new entity + version bump (lightweight migration).
- `MusicApp/DI/DIContainer+UseCases.swift` — register repo + use cases.
- `MusicApp/Navigation/AppRoute.swift` — add `.smartPlaylistEditor(SmartPlaylist?)`.

## Implementation Steps
1. Add CoreData entity `SmartPlaylistEntity`. Bump model version. Verify lightweight migration on existing DB.
2. Create domain entities + repo protocol.
3. Implement `SmartPlaylistRepository` with CRUD (encode/decode rulesJSON).
4. Implement predicate builder (private helper) + `SmartPlaylistUseCase.execute(rules:)` returning `[Song]` via existing Song fetch infrastructure.
5. Build editor MVI screen: list of rules, add row, delete row, name input, live count text.
6. Wire navigation: Library → "+ Smart Playlist" button → editor; tap existing smart playlist → editor with prefilled rules.
7. Update Library list rendering to show smart playlists (separate section or interleaved with ⚡).
8. Tapping smart playlist → resolve to songs → push to existing playlist detail view (or dedicated read-only view).
9. Add unit tests for predicate builder (one per operator × field combination viable).
10. Manual test full flow.

## Todo List
- [ ] Add SmartPlaylistEntity to CoreData model + version bump
- [ ] Verify lightweight migration on prior-version build
- [ ] Create SmartPlaylist + SmartPlaylistRule entities
- [ ] Implement SmartPlaylistRepositoryProtocol + impl
- [ ] Implement predicate builder + unit tests
- [ ] Implement SmartPlaylistUseCase
- [ ] Implement SaveSmartPlaylistUseCase
- [ ] Build SmartPlaylistEditorView + MVI
- [ ] Add live preview count
- [ ] Wire AppRoute for editor navigation
- [ ] Update LibraryView to show smart playlists with ⚡ icon
- [ ] Smart playlist tap → resolve + display matches
- [ ] DIContainer registration
- [ ] Manual test: create rule "artist equals X", save, play
- [ ] Manual test: edit rules, count updates
- [ ] Manual test: existing app upgrade path (migration)

## Success Criteria
- Lightweight migration succeeds from prior build.
- Predicate builder unit tests pass.
- User can create + play a smart playlist end-to-end.
- Editing rules reflects in Library count immediately.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| CoreData migration corrupts existing DB | Low | **High** | Use only additive entity, no Song changes; test on copy of old store |
| Invalid value (e.g., "abc" for duration) crashes predicate | Medium | Crash | Try/catch parse; skip rule with log |
| Empty rules → fetch all songs | Medium | UX surprise | Treat empty rules as `name == ""` (zero matches) or guard in UI |
| OR vs AND combination requested later | Medium | Refactor | Encode combinator field on entity now (default `.and`) for forward compat |

## Security Considerations
- Predicate format strings are static; user values bound via `%@` argv — no injection risk.

## Next Steps
- Unblocks: P04 (independent).
- Future: OR combinator, more operators (between, in last N days), play count field on Song.
