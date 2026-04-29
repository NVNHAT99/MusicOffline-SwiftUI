# Phase 01 - Refactor DI Architecture

**Priority:** P0 | **Status:** ⬜ Todo | **Blocks:** Phase 02, 03

## Context Links
- Ref: `/Users/nhat/Dev/IOS/my-fax-app/EasyFax/EasyFax/DI/`
- Ref: `/Users/nhat/Dev/IOS/stress-app/stress-app/DI/`

## Overview

Two DI systems coexist: old `AppDependencies.shared` singleton and new `DIContainer/AppEnvironment`. The main DI layer is already correct. `AppDependencies.shared` only appears in `#Preview` blocks and one `ViewBuilder` — easy cleanup.

**Additional issues found:**
- `DIContainer+ViewFactory.swift`: `appRouter(for:)` returns a NEW empty `Router<AppRoute>()` each call — routing will be broken for all views created via ViewFactory
- `DIContainer+ViewFactory.swift`: `makeEditPlaylistView` returns `EmptyView()` (TODO not implemented)
- `AddNewPlaylistViewBuilder.swift`: uses `AppDependencies.shared` — should use `DIContainer`
- `#Preview` blocks in 5 view files use `AppDependencies.shared` — replace with `DIContainer`
- `AppDependencies.swift` itself self-references and initializes `PlayerManager.shared` with `.bind(to:)` — confirm bootstrap does same

## Key Insights
- `AppEnvironment.bootstrap()` already correct ✅
- `DIContainer.swift` Services + UseCases already correct ✅  
- `MusicApp.swift` uses `AppEnvironment.bootstrap()` ✅
- `MainTabView.swift` already injects via `@EnvironmentObject var container: DIContainer` ✅
- All production views already use constructor-injected ViewModel — only previews use `AppDependencies.shared`
- `AppDependencies.swift` initializes `nowPlayingService.bind(to: makePlayerManager())` — must preserve this in `AppEnvironment.bootstrap()`

## Requirements
- `AppDependencies.swift` deleted
- Zero `AppDependencies` references in codebase
- `appRouter(for:)` fixed — pass correct router to views created by ViewFactory
- `makeEditPlaylistView` implemented
- `NowPlayingInfoService` bound to `PlayerManager` in bootstrap
- Preview blocks use `DIContainer`

## Architecture

### DI Flow (already correct)
```
MusicApp.swift → AppEnvironment.bootstrap()
    → DIContainer (Services + UseCases + AppState)
    → Router<AppRoute>
    → SystemEventsHandler
```

### Fix for appRouter bug
```swift
// In DIContainer, store weak reference to appRouter
// OR: ViewFactory always receives router from caller, don't create new ones
```

## Related Code Files

**Delete:**
- `MusicApp/Core/AppDependencies.swift`

**Modify:**
- `MusicApp/Core/DI/AppEnvironment.swift` — add `NowPlayingInfoService.shared.bind(to: PlayerManager.shared)` in bootstrap
- `MusicApp/Core/DI/DIContainer+ViewFactory.swift` — fix `appRouter(for:)` + implement `makeEditPlaylistView`
- `MusicApp/Presentation/Feature/AddNewsPlaylist/AddNewPlaylistViewBuilder.swift` — replace `AppDependencies.shared` with `DIContainer`
- `MusicApp/Presentation/Feature/Home/HomeView.swift` — fix preview block
- `MusicApp/Presentation/Feature/AddNewSongs/EditPlaylistView.swift` — fix preview block
- `MusicApp/Presentation/Feature/NowPlayingScreen/NowPlayingView.swift` — fix preview block
- `MusicApp/Presentation/Feature/PlaylistDetail/PlaylistDetailView.swift` — fix preview block
- `MusicApp/Presentation/Feature/TransferView/TransferView.swift` — fix preview block

## Implementation Steps

1. **Fix `AppEnvironment.bootstrap()`**: After creating DIContainer, add:
   ```swift
   NowPlayingInfoService.shared.bind(to: PlayerManager.shared)
   ```

2. **Fix `DIContainer+ViewFactory.swift`**:
   - Store `appRouter` in `DIContainer` as a stored property (set during bootstrap, or passed via environment)
   - OR: change `appRouter(for:)` to cast the input router correctly instead of creating new one
   - Implement `makeEditPlaylistView` — create `EditPlaylistViewModel` with actual playlist data from router params

3. **Fix `AddNewPlaylistViewBuilder.swift`**: Change to accept `DIContainer` parameter instead of using `AppDependencies.shared`

4. **Fix preview blocks** in 5 view files: Replace `AppDependencies.shared` with proper `DIContainer` instantiation (same pattern as `MainTabView` preview)

5. **Delete `AppDependencies.swift`**

6. **Build verify**: `xcodebuild build -workspace MusicApp.xcworkspace -scheme MusicApp -destination 'platform=iOS Simulator,name=iPhone 16'`

## Todo List
- [ ] Fix `AppEnvironment.bootstrap()` — bind NowPlayingInfoService to PlayerManager
- [ ] Fix `DIContainer+ViewFactory.appRouter(for:)` — broken router creation
- [ ] Implement `DIContainer+ViewFactory.makeEditPlaylistView` (currently EmptyView)
- [ ] Fix `AddNewPlaylistViewBuilder` — replace AppDependencies.shared with DIContainer param
- [ ] Fix `HomeView.swift` preview block
- [ ] Fix `EditPlaylistView.swift` preview block
- [ ] Fix `NowPlayingView.swift` preview block
- [ ] Fix `PlaylistDetailView.swift` preview block
- [ ] Fix `TransferView.swift` preview block
- [ ] Delete `AppDependencies.swift`
- [ ] Delete `Commons/Router/Protocols/Routable.swift.backup`
- [ ] Verify: `grep -r "AppDependencies" MusicApp/` returns 0
- [ ] Build passes

## Success Criteria
- `AppDependencies.swift` deleted
- Zero `AppDependencies` references
- `EditPlaylistView` navigable (not EmptyView)
- Build clean

## Risk Assessment
- **Low** — AppDependencies only in previews + ViewBuilder, not in production code paths
- **Medium** — `appRouter(for:)` bug may cause navigation issues in ViewFactory routes; test carefully
