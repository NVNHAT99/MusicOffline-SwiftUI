# Code Review — Correctness & Architecture (reviewer-correctness)

Date: 2026-05-29 · Branch: Master · Scope: MusicApp/ (Core, Data, Domain, Presentation, Commons, Utilities)
Build PASSES, tests PASS — findings are logic/design, not compile errors.

## Summary counts
- CRITICAL: 3
- IMPORTANT: 5
- MODERATE: 9

---

## CRITICAL

[CRITICAL] Import Hub "Pick from Files" is a dead action — primary import path silently does nothing.
— Evidence: `ImportHubView.swift:46` posts `.openImportFromFiles`; the ONLY references to that name are the post site and its declaration (`ImportHubView.swift:115`). Zero observers anywhere (`grep openImportFromFiles` → 2 hits, both in this file). The sheet dismisses (`:47`) and nothing opens.
— Recommendation: Add an observer (e.g. in `RootView` or `SettingView`) that presents the existing `ImportSong` screen / `UIDocumentPicker`, OR change the row to `router.route(to:)` a real document-picker route. Note `.switchMainTab` (`:57`) DOES have an observer (`MainTabView.swift:78`) so the Web-Transfer row works — only the Files row is dead.

[CRITICAL] PlayerManager mutates `@Published state` and non-published `playlist`/`shuffledOrder` from background threads — data race + SwiftUI "publishing from background" violations.
— Evidence: `PlayerManager` (`PlayerManager.swift:13`) is NOT `@MainActor`. `subscribeToEngineEvents` (`:96`) dispatches `Task { await self.handleSongFinished() }` (`:103`) which runs on the default (background) executor and writes `self.state.isPlaying`, `self.state.currentSong`, `self.state.currentTimePlay` (`:394, :409, :413`). `initData`'s `Task {}` (`:79-91`) writes `state.currentSong` off-main. `playlist`/`shuffledOrder` (`:49-50`) are mutated from these same background Tasks (`reloadPlaylist :423`, `regenerateShuffleOrder :352`) while read from `currentIndex`/`computeNextIndex`. `updateState` (`:445`) is commented "Thread-safe" but only runs the closure synchronously on the caller thread — it provides NO synchronization.
— Recommendation: Annotate `PlayerManager` `@MainActor` (it's an `ObservableObject` driving UI), or funnel all state writes through `await MainActor.run`. Consumers already `.receive(on: .main)` (`NowPlayingViewModel.swift:61`) so the read side is safe — the write side is the bug.

[CRITICAL] File import creates duplicate CoreData song rows on re-import of a same-named file.
— Evidence: `ImportSongFromFilesUseCase.copyFile` (`ImportSongFromFilesUseCase.swift:123`) returns the EXISTING `destURL` without error when the file already exists, then `execute` (`:77`) unconditionally calls `addSongUseCase.execute(from: destURL.path)`. `AddSongUseCase.execute` (`AddSongUseCase.swift:25-28`) → `SongRepository.addSong` (`SongRepository.swift:19-34`) inserts a NEW `SongEntity` every time with NO existence/url-uniqueness check. Net: same file → second library entry pointing at the same path.
— Recommendation: In `addSong`, fetch by `url == path` first and skip/update if present; OR have `copyFile` signal "already imported" so the use case records a skip instead of re-adding.

---

## IMPORTANT

[IMPORTANT] `next()` can infinitely recurse/loop when files are missing.
— Evidence: `PlayerManager.loadAndPlay` on missing/unreadable file calls `Task { await next() }` (`:360, :377`). `next()` (`:210`) picks the next song and calls `play(song:)` → `loadAndPlay` again. If many/all files are missing (common after iCloud offload or a Documents wipe), this walks the whole playlist with no visited-set / attempt cap, and with `repeatMode == .all` never terminates.
— Recommendation: Track consecutive-failure count; after N failures (or one full pass) stop and surface a "no playable songs" state instead of recursing.

[IMPORTANT] Song deletion orphans the audio file on disk — storage leak.
— Evidence: `DeleteSongUseCase` injects `documentFileService` (`DeleteSongUseCase.swift:18, 21`) and even carries a `// TODO: need delete file also` (`:19`), but `executeList`/`execute` only call repository delete (`:26-37`); the injected `documentFileService` is never used. `SongRepository.deleteSong` (`SongRepository.swift:124`) removes only the CoreData row. Files accumulate in `Documents/Music/`.
— Recommendation: After successful DB delete, remove the file via `documentFileService`. Guard against deleting a file still referenced by another (duplicate) row — see the duplicate-row CRITICAL above.

[IMPORTANT] `ensureLocallyAvailable` blocks a cooperative thread for up to 30s with `Thread.sleep`.
— Evidence: `ImportSongFromFilesUseCase.ensureLocallyAvailable` (`:146-162`) loops `Thread.sleep(forTimeInterval: 1)` ×30 (`:153-154`). It's called from `copyFile`/`readTextFile` inside `execute` (an `async` func) — blocking sleeps inside async code starve the limited Swift concurrency thread pool and freeze the import `Task`.
— Recommendation: Use `try await Task.sleep(...)` in an async poll, or `URLSession`/coordinator-based download completion, instead of `Thread.sleep`.

[IMPORTANT] MVI pattern is inconsistent — two features have no Reducer/Action layer.
— Evidence: `Presentation/Feature/ImportSong/` has Intent + State + ViewModel but NO Reducer/Action file (`ls` → ImportSongIntent/State/ViewModel only). `Presentation/Feature/AddNewSongs/` (EditPlaylist) same — Intent + State + ViewModel, no Reducer. `EditPlaylistViewModel` mutates state imperatively (`EditPlaylistViewModel.swift:48, 64, 71, 75, 89-93`) rather than via `reducer.reduce(state, action)` like Home/NowPlaying/Equalizer/AudioEditor/PlaylistDetail/Transfer do.
— Recommendation: Either add Reducer/Action for these two to match the unidirectional pattern, or document that simple sheets intentionally skip the reducer. Mutation stays inside the ViewModel (no view→model violation), so this is design consistency, not a data bug.

[IMPORTANT] 26 `print()` calls in production code bypass the project's `Logger`/`CommonLogger` abstraction.
— Evidence: `grep 'print(' --exclude tests` → 26 hits across `SongRepository.swift:28,43,182`, `PlayerManager.swift:190,388`, `ImageCacheManager.swift` (8×), `WebServerGCDService.swift`, `RecentSongsManager.swift`, `PlaylistRepository.swift`, `SongMetadataRepository.swift`, `EditPlaylistViewModel.swift`, custom views. Project ships `Logger.setup(...)` (`MusicApp.swift:20`) with levels.
— Recommendation: Replace with `Logger.debug/error`. `print` is uncontrolled in release builds and inconsistent with the rest of the codebase.

---

## MODERATE

[MODERATE] `appRouter(for:)` fallback creates a throwaway Router with no `factory` — latent silent-failure path.
— Evidence: `DIContainer+ViewFactory.swift:228-230` returns `(router as? Router<AppRoute>) ?? Router<AppRoute>()`. The fallback `Router<AppRoute>()` has `factory == nil`, so any `route(to:)` on it renders `EmptyView` (`Router.swift:60-61`). In current code the cast always succeeds (only `Router<AppRoute>` exists — `grep` confirms no other Routable router type), so it's not hit today, but it will fail silently if a different router type is ever introduced.
— Recommendation: Make the helper `precondition`/`assertionFailure` on cast miss, or pass the known `appRouter` from `AppEnvironment` rather than fabricating one.

[MODERATE] `isFirstInstall` is dead code with a hidden write side-effect.
— Evidence: `AppState.swift:56-62` — computed `isFirstInstall` writes `firstLaunchDate` on first read, but `grep isFirstInstall` shows it's declared in the protocol (`:13`) and implemented (`:56`) and never READ anywhere. `firstLaunchDate` is likewise only written (`:57-58`), never read. The first-launch → Import-Hub routing implied by the QA note never happens; Import Hub is only reachable via `LibaryView.swift:95`.
— Recommendation: Either wire first-launch to route into `ImportHubView` (intended UX), or delete `isFirstInstall` + `firstLaunchDate` as dead. A computed property with a persistence side effect is a footgun regardless.

[MODERATE] "Recently played" Home section is fully stubbed despite a working backend.
— Evidence: `HomeView.recentSongsSection()` returns `EmptyView()` with a large commented block (`HomeView.swift:113-129`). `HomeViewModel.swift:91-101` has the recent-songs fetch commented out. `HomeViewState.swift:15-16` comments out `recentSongs`. Yet `RecentSongsManager.fetchRecentSongs()` is real and used by `PlayerManager` (`:81`), and `FetchHomeDataUseCase.swift:36` hardcodes `recentSongs: []`. `HomeEntity.recentSongs` (`:13`) is dead.
— Recommendation: Finish the feature (define the missing `RecentSongItem` view model the TODOs reference) or remove the dead state/entity field + section. Currently it's half-wired noise.

[MODERATE] `ImageCacheManager` carries 4 dead duplicate methods + an unused queue.
— Evidence: `setupCache()` (`ImageCacheManager.swift:48`), `setupMemoryCache()` (`:57`), `observeMemoryWarnings()` (`:63`), `cleanupExpiredCache()` (`:274`) each have ZERO callers (`grep` confirms 0; the `*Sync`/`*Async` variants at `:76, :82, :95, :296` are the live ones). `accessQueue` (`:25`) is declared and never used (`grep accessQueue` → 1 hit, the declaration).
— Recommendation: Delete the four unused methods and the unused `accessQueue` (or actually use it to serialize `accessOrder` mutations — see file-size note).

[MODERATE] File-size rule (<200 LOC) violations — refactor plan claimed these were split.
— Evidence (`wc -l`): `PlayerManager.swift` = 448; `ImageCacheManager.swift` = 394; `DIContainer+ViewFactory.swift` = 344; `NowPlayingViewModel.swift` = 311; `CustomTabBar.swift` = 311 (`Commons/Tabars/`); `NowPlayingFullPlayerView.swift` = 296; `CommonLogger.swift` = 252; `AudioEngineService.swift` = 243; `PlaylistDetailViewModel.swift` = 233; `SongRepository.swift` = 232; `Modifiers.swift` = 224; `PlaylistRepository.swift` = 210; `SettingViewViewModel.swift` = 205; `CustomSliderView.swift` = 202. Within limit / claims verified OK: `NowPlayingView.swift` = 70, `DIContainer.swift` = 127, old `CustomViews/CustomTabar.swift` = 9 (now a shim).
— Recommendation: Prioritize splitting `PlayerManager` (mix of playback control, shuffle, persistence, recent-songs) and `ImageCacheManager` (deleting the dead dups gets it close). The rest are borderline; flag, don't block.

[MODERATE] `dismiss()` of `ImportHubView`'s `NavigationView` + `@Environment(\.dismiss)` is fragile.
— Evidence: `ImportHubView.swift:14` wraps content in deprecated `NavigationView`; `dismiss()` (`:9, :31, :47, :58`) relies on the sheet's environment dismiss. Combined with the dead `.openImportFromFiles` post, the Files row dismisses the hub and then nothing happens — the user sees the sheet vanish with no result (poor UX even once the observer is added).
— Recommendation: Migrate to `NavigationStack`; ensure the document picker is presented BEFORE or instead of dismissing so the user gets feedback.

[MODERATE] `currentTime` accessor returns stale value after pause (uses `lastRenderTime`).
— Evidence: `AVAudioPlayerEngineService.currentTime` (`AudioEngineService.swift:50-56`) computes from `playerNode.lastRenderTime`/`playerTime`. After `pause()` (`:135`) `lastRenderTime` keeps returning the last value and `playerTime(forNodeTime:)` becomes `nil` once stopped, falling back to `seekOffsetFrames/sampleRate` — but `seekOffsetFrames` is only updated on seek/load, not on pause, so the reported time can jump backward to the last seek point. The app sidesteps this by tracking time in `ProgressTimerService` instead, so `engine.currentTime` is effectively unused for the UI — but it's a correctness trap for any future caller.
— Recommendation: Either remove `currentTime` from the protocol if unused, or persist the paused frame offset so the accessor is monotonic.

[MODERATE] Leftover TODOs marking unfinished behavior in shipping paths.
— Evidence: `TransferUseCase.swift:25, 58`; `TransferViewModel.swift:98` ("Handle already running"); `DIContainer+ViewFactory.swift:181` ("Connect to NowPlayingViewModel" — the timer-menu `onCancelSleepTime` only dismisses, never cancels the actual sleep timer in PlayerManager); `SettingConstants.swift:9, 13` ("Replace with real URLs / App Store ID before release").
— Recommendation: The timer-menu→PlayerManager disconnect (`:181`) is a real functional gap (Cancel Sleep Timer from the menu sheet does nothing). The Setting placeholder URLs/IDs must be filled before App Store submission.

[MODERATE] `Documents` root scan import excludes only 3 managed folders; edited-export folder reuse is fine but scan can re-pick already-imported loose files repeatedly until copied.
— Evidence: `ExternalFileImportCoordinator.scanDocumentsRootAndImport` (`ExternalFileImportCoordinator.swift:29-43`) skips `["Music","Lyrics","Inbox"]` and scans loose audio in Documents root on every `.active` scene phase (`MusicApp.swift:38-43`). Dedup relies on `copyFile` filename match into `Music/`, so a loose file is copied once then skipped — acceptable — but the original loose file is never moved/removed, so it's re-scanned (and re-dedup-checked) on every foreground. Combined with the duplicate-row CRITICAL, a loose file whose name later collides could double-add.
— Recommendation: After a successful import of a loose Documents-root file, move it into `Music/` (or delete it) so it isn't rescanned; fixing the addSong dedup also closes the double-add path.

---

## Positive observations
- AVAudioEngine graph is correct: nodes attached up-front, chain reconnected with the file's native `processingFormat` on load (`AudioEngineService.swift:113-123`), effects toggled via `.bypass` (no engine stop). `timePitch.bypass` neutral logic (`AudioEffectsService.swift:86-89`) and reverb auto-bypass (`:62-67`) are sound. Interruption/route-change/media-reset handlers present (`:204-242`).
- EQ v1→v2 migration is correct: 3→10 band projection (bass×3, mid×4, treble×3) (`EQService.swift:103-114`), guarded by `gainsV2` presence, runs before `restorePersistedState`, deletes legacy key once.
- ExportEditedAudioUseCase is solid: trim/fade-in/fade-out/normalize math correct, unique output URL, background task, progress polling, cleanup-on-failure (`ExportEditedAudioUseCase.swift`). AudioEditorViewModel registers the exported file via `addSong.execute` (`:106`) so it appears in the library.
- `onOpenURL` + scene-active Documents scan + `.externalImportFinished` observer (`RootView.swift:51`) are correctly wired; coordinator's `inFlight` guard prevents overlapping batches.
- Demo/example files (LoggerExample, DemoDelayTouch) already deleted — `grep` found none.
- `makeEditPlaylistView` returns a real `EditPlaylistView` (NOT EmptyView) — that prior known bug is FIXED. The `EmptyView()` at `DIContainer+ViewFactory.swift:20` is only the default fallback for unknown route TYPES, which is correct.

## Unresolved questions
- Is the first-launch → Import-Hub routing (implied by `firstLaunchDate`) a planned UX that was dropped, or should `isFirstInstall` simply be deleted? Affects whether the AppState dead code is a bug or cleanup.
- Is `AudioEngineProtocol.currentTime` consumed anywhere, or can it be removed? (UI uses ProgressTimerService instead.)
