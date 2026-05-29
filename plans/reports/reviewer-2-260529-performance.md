# Performance / Memory / Concurrency Review — reviewer-perf — 2026-05-29

Scope: `MusicApp/`. Focus: runtime cost, leaks, concurrency. Build/tests assumed green.
Evidence is `file:line` against current `Master`.

## Severity counts
- CRITICAL: 3
- IMPORTANT: 5
- MODERATE: 6

---

## CRITICAL

[CRITICAL] Per-tick allocation of a full ImageCacheManager (leaks NotificationCenter observers + spawns disk-scan Task every ~1s while playing) — `NowPlayingInfoService.swift:55` inside `updateNowPlaying`, driven by `PlayerManager` `$state` emitting on every `progressTimerService` tick (`PlayerManager.swift:109-113`, tick interval 1.0s `PlayerManager.swift:165,373`). `ImageCacheFactory.createDefaultCache()` returns a brand-new `ImageCacheManager` each call (`ImageCacheFactory.swift:5`); its `init` registers a block-based `didReceiveMemoryWarning` observer (`ImageCacheManager.swift:82-92`) and launches a disk cleanup `Task` (`ImageCacheManager.swift:42-44`). Block-based observers are NOT removed by `removeObserver(self)` in `deinit` (`ImageCacheManager.swift:381-383`), so every second of playback permanently leaks one observer + re-decodes artwork from disk/asset. — Recommendation: inject a single shared cache into `NowPlayingInfoService`; cache the decoded `UIImage`/artwork for the current song and only refresh on song change, not on progress tick. Switch block-based observer to the token API and store/remove the token, or use `@objc` selector form.

[CRITICAL] `PlayerManager` mutates `@Published state` off the main thread (data race) — `PlayerManager` is a plain `final class`, not `@MainActor` (`PlayerManager.swift:13`). `handleSongFinished()` runs inside `Task { await ... }` from a background executor and writes `state.isPlaying`/`state.currentSong` (`PlayerManager.swift:103,392-417`); `play/pause/next/previous` are `async` and invoked from `Task {}` in view models off-main (e.g. `NowPlayingViewModel.swift:231-249`), all funneling into `updateState` which mutates `state` directly (`PlayerManager.swift:445-447`). Concurrent with the main-thread timer sink writing `state.currentTimePlay` (`PlayerManager.swift:110-112`) this is an unsynchronized read/write of shared mutable state from multiple threads. Consumers `.receive(on: .main)` so the UI is protected, but the producer-side race remains (intermittent corruption / crashes under load). — Recommendation: annotate `PlayerManager` `@MainActor` (it already only does lightweight orchestration; engine I/O is in the engine), or serialize all `state` access through a dedicated actor/queue.

[CRITICAL] `performTransferInTransferContext` does not actually serialize work; `isTransferQueueIdle` reports idle while saves are still in flight — `PersistenceController.swift:136-160`. The `BlockOperation` body only calls `transferContext.perform { ... }` (an async enqueue) and then returns, so the `OperationQueue` (maxConcurrentOperationCount=1, `:103-105`) marks the operation finished before the Core Data work runs. `isTransferQueueIdle` (`:158-160`) therefore returns `true` while a save is still pending on the context's private queue. This idle flag gates real logic in `TransferUseCase.swift:54`, so the transfer can be considered "done" before persistence completes → lost/partial writes during file-transfer reconciliation. — Recommendation: resume the continuation from *inside* `context.perform` AND keep the operation alive until completion (e.g. make the `BlockOperation` block synchronously wait, or replace the queue with `context.perform`/`performAndWait` chained through an `actor`). Make `isTransferQueueIdle` reflect outstanding context work, not queue op count.

---

## IMPORTANT

[IMPORTANT] Multiple independent ImageCacheManager instances fragment the in-memory cache and each leaks an observer — `ImageCacheFactory.createDefaultCache()` called at 4 distinct sites that persist: `DIContainer.swift:79`, `AudioImageRepository.swift:15` (default arg), `NowPlayingView.swift:13` (one per view instantiation), plus the per-tick one above. Each has its own `NSCache` (`ImageCacheManager.swift:21`) so the same artwork is decoded and held N times; memory-warning observers accumulate. — Recommendation: make the cache a true singleton (or the one DI-owned instance) injected everywhere; remove `createDefaultCache()` default args that silently spawn new caches.

[IMPORTANT] Main-thread block at launch: `group.wait()` blocks the main thread during Core Data store load — `PersistenceController.swift:85-93`. `CoreDataManager.shared` is first realized inside `AppEnvironment.bootstrap()` (`DIContainer.swift:82` via `createDefault`), and `bootstrap()` runs synchronously in `@StateObject private var environment = AppEnvironment.bootstrap()` at app init (`MusicApp.swift:16`, `AppEnvironment.swift:59`). `loadPersistentStores` + lightweight migration runs on the main thread before first frame; with a large/migrating store this stalls launch and can trip the watchdog. — Recommendation: load the store asynchronously (completion handler off-main) and gate UI on a loading state, or accept the block only for a tiny store and document the cap.

[IMPORTANT] `BackgroundDownloadService` mutates `currentTask`/`currentSubject` across threads without synchronization — `BackgroundDownloadService.swift:30-51,55-90`. Delegate callbacks fire on the session's `delegateQueue: nil` (a background serial queue, `:27`) and read/write `currentSubject`/`currentTask`, while `download(...)`/`cancelCurrent()` mutate the same vars from the caller's thread. Concurrent download+cancel can race (send on a stale subject, or cancel the wrong task). — Recommendation: confine all mutable state to a private serial queue or make the type an `actor`; or set a dedicated `delegateQueue` and hop the public API onto it.

[IMPORTANT] Whole-`NowPlayingState` reassignment every progress tick forces full player + lyrics re-render — `NowPlayingViewModel.swift:83-84` reassigns `state` (single `@Published`, `:29`) on every player-state emission, which includes the 1s `currentTimePlay` tick. Because lyrics, artwork flags, and all controls live in the same `state`, SwiftUI invalidates the entire `NowPlayingFullPlayerView` (incl. lyrics `List`) once per second during playback. — Recommendation: split the high-frequency `currentTime` into its own `@Published` (or a separate lightweight observable) so only the progress bar/label re-renders; keep song/lyrics state in a separately-published value.

[IMPORTANT] `fetchSongs(_ idArray:)` does not preserve playlist order — `SongRepository.swift:51-62` fetches with `id IN %@` and maps results in arbitrary Core Data order; `PlayerManager` builds its `playlist` from this (`PlayerManager.swift:184,422`). Next/previous/shuffle-anchor indices then operate on a mis-ordered list → wrong "next song". (Correctness with a perf angle: also means shuffle order regeneration in `reloadPlaylist` anchors on a wrong index.) — Recommendation: re-sort the fetched results to match `playlist.songIDs` order before mapping (build a dictionary by id, then map over the ordered id array).

---

## MODERATE

[MODERATE] EQ band slider drag triggers a synchronous UserDefaults write storm — `EQBandSliderView.swift:34-39` (`Slider` step 0.5) fires `onChange` continuously; each call hits `EQService.setBandGain` → `persist()` which writes two keys incl. a `[Float]` array serialization every increment (`EQService.swift:53-61,124-127`). During a drag this is dozens of writes/sec on the calling thread. — Recommendation: apply the gain to the node live but debounce `persist()` (e.g. on drag-end / 250ms throttle).

[MODERATE] `updateSongs(from:)` saves inside the per-item loop (N saves) — `SongRepository.swift:95-120` calls `context.save()` for every (oldPath,newPath) pair, then a final save. For a multi-file transfer this is N round-trips instead of one batched save. — Recommendation: mutate all matched entities, then `save()` once after the loop (the trailing `hasChanges` save already does this; drop the in-loop save).

[MODERATE] `getCurrentMemorySize()` is a fake estimate (`accessOrder.count * 1024`) — `ImageCacheManager.swift:249-252`. Reported memory size is meaningless; any eviction/telemetry decision based on `getCacheSize().memory` is wrong. — Recommendation: track real summed cost on set/evict, or drop the API.

[MODERATE] Cache `set` runs a synchronous disk-size scan + oldest-file sort on the caller thread — `ImageCacheManager.swift:172-178` calls `getCurrentDiskSize()` (full directory enumeration, `:254-272`) and potentially `cleanupOldestFilesSync` (sort all files by date, `:318-344`) on whatever thread called `set`, including the artwork-extraction path reached from `get` (`:124`). With a large disk cache this stalls the caller. — Recommendation: move disk bookkeeping onto the existing `accessQueue` (declared `:25` but unused for disk ops); track running disk size incrementally instead of rescanning.

[MODERATE] `updateAccessOrder` hops to the main queue for every cache hit — `ImageCacheManager.swift:232-247` dispatches LRU bookkeeping to `DispatchQueue.main.async` on every `get`/`set`. Bursts of artwork lookups schedule many main-queue blocks competing with rendering. — Recommendation: perform LRU bookkeeping on the dedicated `accessQueue` (already declared) rather than main.

[MODERATE] `BackgroundDownloadService` URLSession is never invalidated; delegate retained for process lifetime — `BackgroundDownloadService.swift:23-28`. `URLSession(configuration:delegate:delegateQueue:)` strongly retains `self`. It's a `shared` singleton so not a growing leak, but the session/delegate cycle persists forever and there's no `finishTasksAndInvalidate`. — Recommendation: acceptable for a singleton; if ever made non-singleton, call `invalidateAndCancel()` on teardown.

---

## Positive observations
- All Combine subscriptions use `[weak self]` and subscribers consistently `.receive(on: .main)` (`NowPlayingViewModel.swift:61,68`, `HomeViewModel.swift:39`, etc.) — no obvious sink retain cycles.
- AVAudioEngine effect toggling uses `.bypass` instead of reconnecting the graph, avoiding mid-playback reconfigure pops/cost (`AudioEngineService.swift:73-86`, `EQService.setBypass`).
- `ScanWaveformUseCase` streams the file in capped 8192-frame chunks on a detached task — bounded memory regardless of file size (`ScanWaveformUseCase.swift:25-60`).
- `ExportEditedAudioUseCase` uses streaming `AVAssetExportSession` with a UIKit background task and cancels its progress-poll task on completion — good memory + lifecycle hygiene (`ExportEditedAudioUseCase.swift:108-130`).
- `ExternalFileImportCoordinator` is `@MainActor`, uses `[weak self]`, and an `inFlight` guard — clean (`ExternalFileImportCoordinator.swift:47-63`).
- List views (`PlaylistDetailView`, `HomeView`) render SF Symbols / Lazy stacks with no per-row async artwork load — no scroll-time decode thrash.

## Unresolved questions
- Is `CoreDataManager` store small enough in practice that the launch `group.wait()` (`PersistenceController.swift:93`) stays under the watchdog? Needs measurement on a large library / first-run migration.
- Confirm with reviewer-correctness whether the `fetchSongs` ordering bug is already tracked under their scope to avoid double-fixing.
