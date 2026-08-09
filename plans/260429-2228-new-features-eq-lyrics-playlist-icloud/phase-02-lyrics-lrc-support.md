# Phase 02 — Lyrics (.lrc file support)

## Context Links
- `MusicApp/Domain/UseCase/ImportSongFromFilesUseCase.swift`
- `MusicApp/Presentation/Feature/NowPlaying/NowPlayingFullPlayerView.swift`
- `MusicApp/Presentation/Feature/NowPlaying/State/*`
- `MusicApp/DI/DIContainer+UseCases.swift`

## Overview
- **Priority:** P2
- **Status:** ✅ complete
- **Effort:** 2 days
- **Risk:** Low

Allow users to import `.lrc` files alongside songs; display synced lyrics in full player view, auto-scrolling and highlighting current line.

## Requirements
### Functional
- Import .lrc via same `UIDocumentPickerViewController` flow.
- Parse `[mm:ss.xx] Lyric line text` — tolerate multiple timestamps per line, blank lines, metadata tags `[ar:]`, `[ti:]` (skip).
- Lyrics keyed by song filename stem (e.g., `MySong.mp3` ↔ `MySong.lrc`).
- Toggle button in `NowPlayingFullPlayerView` shows/hides lyrics panel.
- Lyrics scroll view auto-scrolls to current line as `currentTime` advances; highlights active line.
- If no lyrics file exists for current song, show "No lyrics available" placeholder.

### Non-Functional
- Parser O(n); no main-thread hangs for typical 200-line files.
- Lyrics storage: filesystem under `Documents/Lyrics/{stem}.lrc`.

## Architecture
```
ImportSongFromFilesUseCase
  ├─ if .mp3/.m4a → existing flow
  └─ if .lrc      → LyricsRepository.save(stem, content)

NowPlayingViewModel
  ├─ on songChanged → FetchLyricsUseCase(stem) → [LyricsLine]
  └─ on currentTime tick → reducer computes activeIndex

NowPlayingFullPlayerView
  └─ LyricsView(lines, activeIndex, scrollProxy)
```

### Data Model
```swift
struct LyricsLine: Equatable {
    let timestamp: TimeInterval  // seconds
    let text: String
}
```

### Parser Rules
- Match `\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]` — capture mm, ss, optional ms.
- One physical line may have N timestamp tags → emit N `LyricsLine` rows with same text.
- Skip lines starting with `[ar:`, `[ti:`, `[al:`, `[by:`, `[offset:` (apply offset later if needed).
- Sort final array by timestamp ascending.

## Related Code Files
### Create
- `MusicApp/Domain/Entity/LyricsLine.swift`
- `MusicApp/Domain/Repository/LyricsRepositoryProtocol.swift`
- `MusicApp/Data/Repository/LyricsRepository.swift`
- `MusicApp/Domain/UseCase/FetchLyricsUseCase.swift`
- `MusicApp/Domain/UseCase/ParseLrcContentUseCase.swift` (optional split for testability)
- `MusicApp/Presentation/Feature/NowPlaying/Components/LyricsView.swift`

### Modify
- `MusicApp/Domain/UseCase/ImportSongFromFilesUseCase.swift` — branch on UTI/extension; route .lrc to LyricsRepository.
- `MusicApp/Presentation/Feature/NowPlaying/NowPlayingFullPlayerView.swift` — add toggle + LyricsView.
- `MusicApp/Presentation/Feature/NowPlaying/State/NowPlayingState.swift` — add `lyrics: [LyricsLine]`, `activeLyricIndex: Int?`, `showLyrics: Bool`.
- `MusicApp/Presentation/Feature/NowPlaying/State/NowPlayingIntent.swift` — `toggleLyrics`, `lyricsLoaded([LyricsLine])`.
- `MusicApp/Presentation/Feature/NowPlaying/State/NowPlayingStateAction.swift` — matching actions.
- `MusicApp/Presentation/Feature/NowPlaying/State/NowPlayingStateReducer.swift` — compute activeIndex from currentTime via binary search.
- `MusicApp/Presentation/Feature/NowPlaying/NowPlayingViewModel.swift` — wire FetchLyricsUseCase on song change.
- `MusicApp/DI/DIContainer+UseCases.swift` — register LyricsRepository, FetchLyricsUseCase.

## Implementation Steps
1. Create `LyricsLine` entity.
2. Implement parser (`ParseLrcContentUseCase`) with unit tests covering: single timestamp, multi-timestamp, metadata skip, malformed line tolerance.
3. Implement `LyricsRepository` (filesystem under `Documents/Lyrics/`). Methods: `save(stem, content)`, `load(stem) -> String?`, `delete(stem)`.
4. Implement `FetchLyricsUseCase`: load file → parse → return `[LyricsLine]` or `[]`.
5. Extend `ImportSongFromFilesUseCase`: detect `.lrc` extension; for each, write to LyricsRepository.
6. Update DIContainer.
7. Extend NowPlaying MVI: state fields, intents, reducer logic for activeIndex (binary search lower-bound on timestamp).
8. Build `LyricsView` using `ScrollViewReader` + `ScrollViewProxy.scrollTo(activeIndex, anchor: .center)`; animate.
9. Add toggle button to `NowPlayingFullPlayerView`; conditionally render `LyricsView`.
10. Subscribe NowPlayingViewModel to song change → dispatch fetch; subscribe to currentTime tick (already in state) → reducer recomputes activeIndex.
11. Manual test with sample .lrc files.

## Todo List
- [ ] Create LyricsLine entity
- [ ] Implement LRC parser + unit tests
- [ ] Implement LyricsRepository (filesystem)
- [ ] Implement FetchLyricsUseCase
- [ ] Extend ImportSongFromFilesUseCase for .lrc
- [ ] Register dependencies in DIContainer
- [ ] Add lyrics fields to NowPlayingState
- [ ] Add intents/actions/reducer cases
- [ ] Wire ViewModel song-change → fetch
- [ ] Build LyricsView with auto-scroll
- [ ] Add toggle button to FullPlayerView
- [ ] Manual test: import .lrc, play song, verify highlight + scroll
- [ ] Manual test: song without .lrc shows placeholder

## Success Criteria
- Parser unit tests pass (>=8 cases).
- Lyrics highlight active line within 200ms of timestamp.
- Auto-scroll keeps active line in view.
- No memory leak on song switch (fetch debounced/cancelled).

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Encoding issues (UTF-16 .lrc files) | Medium | Parser fails | Try UTF-8 then UTF-16 fallback in repo load |
| Filename mismatch (stem differs) | Medium | No lyrics shown | Document convention; future: allow manual link |
| Auto-scroll fights user manual scroll | Low | UX | Pause auto-scroll for 3s after user gesture |
| Reducer recompute on every tick costly | Low | Perf | Only recompute when crossing line boundary |

## Next Steps
- Unblocks: P03 (independent but easier to merge after).
