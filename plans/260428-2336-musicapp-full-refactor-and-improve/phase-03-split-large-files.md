# Phase 03 - Split Large Files (>200 LOC)

**Priority:** P1 | **Status:** ⬜ Todo | **Depends on:** Phase 01, 02 | **Blocks:** Phase 04

## Context Links
- Dev rules: `~/.claude/rules/development-rules.md` — max 200 LOC per file
- Plan: `plan.md`

## Overview

Split all files exceeding 200 LOC into focused, single-responsibility modules. This follows the team's 200-line rule and matches EasyFax/stress-app conventions.

**Files to split:**

| File | LOC | Split Strategy |
|------|-----|---------------|
| `Core/ImageCacheManager.swift` | 460 | Split into 3 files |
| `Core/PlayerManager.swift` | 439 | Split into 3 files |
| `Presentation/Feature/NowPlayingScreen/NowPlayingView.swift` | 339 | Split into 3 views |
| `Core/DI/DIContainer+ViewFactory.swift` | 258 | Split into 2 extensions |
| `Core/DI/DIContainer.swift` | 223 | Split UseCases.create into separate file |
| `Commons/Modifiers.swift` | 224 | Split by modifier category |
| `Commons/CustomViews/CustomSliderView.swift` | 202 | Borderline — split if needed |

## Split Plans

### `ImageCacheManager.swift` (460 → 3 files)
```
Core/
├── ImageCache/
│   ├── ImageCacheProtocol.swift          # Protocols + Configuration struct (~60 LOC)
│   ├── ImageCacheManager.swift           # NSCache + disk logic (~300 LOC)  
│   └── ImageCacheFactory.swift           # Factory enum + NSCacheDelegate (~50 LOC)
```

### `PlayerManager.swift` (439 → 3 files)
```
Core/
├── Player/
│   ├── PlayerManagerProtocol.swift       # Protocol + State + RepeatMode enum (~50 LOC)
│   ├── PlayerManager.swift               # Core play/pause/seek logic (~200 LOC)
│   └── PlayerManager+Navigation.swift   # next/previous/shuffle/index logic (~150 LOC)
```

### `NowPlayingView.swift` (339 → 3 files)
```
Presentation/Feature/NowPlayingScreen/
├── NowPlayingView.swift                  # Main view + coordinator (~80 LOC)
├── Views/
│   ├── NowPlayingMiniPlayerView.swift    # Mini player bar (~100 LOC)
│   └── NowPlayingFullPlayerView.swift   # Full screen player (~120 LOC)
```

### `DIContainer+ViewFactory.swift` (258 → 2 files)
```
Core/DI/
├── DIContainer+ViewFactory.swift         # Route switching + view creation (~150 LOC)
└── DIContainer+ViewModels.swift          # ViewModel factory methods (already exists partially)
```
> Note: `DIContainer+ViewModels.swift` extension may already exist or be in DIContainer.swift

### `DIContainer.swift` (223 → 2 files)
```
Core/DI/
├── DIContainer.swift                     # Container class + Services struct (~120 LOC)
└── DIContainer+UseCases.swift            # UseCases struct + create() factory (~110 LOC)
```

### `Commons/Modifiers.swift` (224 → 2 files)
```
Commons/Modifiers/
├── Modifiers.swift                       # Core/common modifiers (~100 LOC)
└── ShimmerModifier.swift                 # Already exists as ShimmerViewModifier.swift, consolidate
```

## Key Constraints
- All split files must be added to Xcode project to compile
- No behavioral changes — pure extract/reorganize
- Internal types/extensions stay `internal` (no visibility changes needed)
- `PlayerManager.shared` singleton stays in `PlayerManager.swift`

## Implementation Steps

1. **Split `ImageCacheManager.swift`**: Extract `ImageCacheProtocol`, `ImageCacheConfiguration` → `ImageCacheProtocol.swift`; extract `ImageCacheFactory` + `NSCacheDelegate` extension → `ImageCacheFactory.swift`

2. **Split `PlayerManager.swift`**: Extract protocol + types → `PlayerManagerProtocol.swift`; extract navigation methods (`computeNextIndex`, `computePreviousIndex`, `regenerateShuffleOrder`, `handleSongFinished`, etc.) → `PlayerManager+Navigation.swift`

3. **Split `NowPlayingView.swift`**: Extract `miniPlayer` computed property → `NowPlayingMiniPlayerView.swift` as a struct; extract `fullPlayer()` function → `NowPlayingFullPlayerView.swift`; keep only the main `NowPlayingView` body and `ContentView` in main file (or delete `ContentView` usage example)

4. **Split `DIContainer.swift`**: Move `UseCases` struct + `UseCases.create()` → `DIContainer+UseCases.swift`

5. **Split `DIContainer+ViewFactory.swift`**: Move ViewModel factory methods → `DIContainer+ViewModels.swift` (check if it already exists)

6. **Split `Modifiers.swift`**: Review content — split by concern if logical boundary exists

7. **Add all new files to Xcode project**

8. **Build verify** — no errors

## Todo List
- [ ] Split `ImageCacheManager.swift` → 3 files
- [ ] Split `PlayerManager.swift` → 3 files
- [ ] Split `NowPlayingView.swift` → 3 files (extract mini + full player)
- [ ] Split `DIContainer.swift` → 2 files (extract UseCases)
- [ ] Split `DIContainer+ViewFactory.swift` → 2 files (extract ViewModel factories)
- [ ] Review `Modifiers.swift` — split if clear boundary exists
- [ ] Add all new files to Xcode project
- [ ] Build verify

## Success Criteria
- No file exceeds 200 LOC
- All features work (PlayerManager, NowPlaying, DI wiring intact)
- Build clean

## Risk Assessment
- **Medium** — PlayerManager split is most risky; navigation logic is tightly coupled with state; must keep all `private var` state in same class or restructure access control
- **Low** — NowPlayingView and ImageCache splits are purely view/struct extractions with no shared mutable state
- **Mitigation**: Split PlayerManager last; verify playback after split
