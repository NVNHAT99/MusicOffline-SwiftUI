# Full-App Review Summary — MusicOffline-SwiftUI

Date: 2026-05-29 · Branch: Master · Build: PASS · MusicAppTests: PASS
Synthesized from 3 parallel reviewers (correctness/arch, performance/memory, security/UX).
Source reports:
- `plans/reports/reviewer-1-260529-correctness-arch.md`
- `plans/reports/reviewer-2-260529-performance.md`
- `plans/reports/reviewer-3-260529-security-ux.md`

Totals (pre-dedupe): 8 CRITICAL, 14 IMPORTANT, 20 MODERATE.
After dedupe (PlayerManager race counted once; fetchSongs-order counted once): **7 unique CRITICAL, 13 IMPORTANT**.

---

## CRITICAL (ship-blockers / data-loss / crash / store-rejection)

### C1. PlayerManager mutates `@Published state` off the main thread — data race
*Flagged by BOTH correctness + perf (independent confirmation → high confidence).*
- `PlayerManager.swift:13` is a plain `final class`, not `@MainActor`. `handleSongFinished` (`:103,:392-417`), `initData` (`:79-91`), and `async play/pause/next` write `state` / `playlist` / `shuffledOrder` from background `Task {}` concurrently with the main-thread timer tick (`:110-112`). `updateState` (`:445`) is mislabeled "thread-safe" — no synchronization. UI is shielded by `.receive(on:.main)`, but the producer-side race remains.
- **Fix:** annotate `PlayerManager` `@MainActor` (it only orchestrates; engine I/O lives in the engine), or funnel all `state` writes through `await MainActor.run`. Low-risk, high-value.

### C2. Per-second ImageCacheManager allocation while playing — leak + redundant decode
- `NowPlayingInfoService.swift:55` creates a NEW `ImageCacheManager` on every `$state` emission (~1s tick). Each `init` registers a block-based `didReceiveMemoryWarning` observer that `deinit`'s `removeObserver(self)` CANNOT remove (`ImageCacheManager.swift:82-92,381-383`) + re-decodes artwork from disk. Steady accumulating observer leak + CPU during playback.
- **Fix:** inject one shared cache; cache the decoded artwork for current song, refresh only on song change (not progress tick). Switch to token-based observer API.

### C3. File import creates duplicate CoreData rows
- `ImportSongFromFilesUseCase.copyFile` (`:123`) returns existing path w/o error → `execute` (`:77`) unconditionally calls `addSong` → `SongRepository.addSong` (`:19-34`) inserts a NEW entity with no url-uniqueness check. Re-import of same-named file = duplicate library entry on same path.
- **Fix:** in `addSong`, fetch by `url == path` first; skip/update if present. (Also closes the Documents-root rescan double-add path, MOD.)

### C4. Import Hub "Pick from Files" is a dead action
- `ImportHubView.swift:46` posts `.openImportFromFiles` with ZERO observers (grep: 2 hits, both in this file). The primary "add from Files" path dismisses the sheet and does nothing. (`.switchMainTab` works — has observer at `MainTabView.swift:78`.)
- **Fix:** add an observer (RootView) that presents `ImportSong` / `UIDocumentPicker`, or route via `router.route(to:)` a real picker route.

### C5. Core Data transfer queue does not serialize → idle flag lies → lost/partial writes
- `PersistenceController.swift:136-160`: `BlockOperation` returns before the async `context.perform` runs, so `maxConcurrentOperationCount=1` is ineffective and `isTransferQueueIdle` (`:158-160`) reports idle while saves are pending. This flag gates real logic in `TransferUseCase.swift:54`.
- **Fix:** resume continuation from INSIDE `context.perform`; keep the operation alive until completion. Make `isTransferQueueIdle` reflect outstanding context work.

### C6. No `NSLocalNetworkUsageDescription` while running a LAN HTTP server
- `Info.plist:1-59` has ZERO usage-description strings; Web Upload binds `GCDWebUploader` on port 61234 (`WebServerGCDService.swift:59,90-96`). iOS 14+ Local Network prompt has no rationale → common App Store rejection + access can silently fail.
- **Fix:** add `NSLocalNetworkUsageDescription` (+ `NSBonjourServices` if Bonjour advertised). Verify on device. *(Unresolved Q: does GCDWebServer advertise Bonjour today? — needs device check.)*

### C7. Verbose Logger ships in release, leaks file paths / server URL / IP
- `CommonLogger.swift:152-195` ends in a bare `print(logMessage)`; level set to `.debug` at startup with no build guard (`MusicApp.swift:18-22`). Path/PII call sites: `WebServerGCDService.swift:61,80,113,144-156`, `PlayerManager.swift:358`, `SettingViewViewModel.swift:104`, `MusicApp.swift:32`.
- **Fix:** gate emit behind `#if DEBUG` or route via `os.Logger` `.private`; release default `.warning`+. Stop logging absolute paths. (Overlaps the 26 stray `print()` IMPORTANT below.)

---

## IMPORTANT (fix before release)

- **I1.** `next()` infinite recursion when files missing (`PlayerManager.swift:360,377,210`) — no visited-set/attempt cap; with `repeatMode==.all` never terminates after iCloud offload/Documents wipe. → track consecutive-failure count, surface "no playable songs".
- **I2.** Song deletion orphans audio file on disk (`DeleteSongUseCase.swift:18-37` injects `documentFileService`, never uses it; `// TODO: need delete file also`). Storage leak. → delete file after DB delete, guard against duplicate-row shared path (see C3).
- **I3.** `ensureLocallyAvailable` blocks cooperative thread up to 30s via `Thread.sleep` inside async (`ImportSongFromFilesUseCase.swift:146-162`). *Flagged by correctness + security.* → `Task.sleep` async poll + cancel path + "downloading from iCloud…" state.
- **I4.** Web upload server: no auth + not stopped on leaving Transfer screen (`WebServerGCDService.swift:90-96` no auth; `TransferView.swift` no `.onDisappear`; stop only on `.background`, not `.inactive`). Unauthenticated browse/upload/delete/rename live on Wi-Fi. → stop on `onDisappear` + `.inactive`; consider per-session passcode.
- **I5.** Launch-time main-thread block: `group.wait()` during Core Data store load (`PersistenceController.swift:85-93`) realized synchronously in `AppEnvironment.bootstrap()` (`MusicApp.swift:16`). Large/migrating store → watchdog risk. → load store async, gate UI on loading state.
- **I6.** `fetchSongs(idArray)` loses playlist order (`SongRepository.swift:51-62` `id IN %@`, arbitrary order). *Flagged by correctness + perf.* `PlayerManager` builds playlist from this → wrong next/previous + wrong shuffle anchor. → re-sort to match `songIDs` order.
- **I7.** Multiple ImageCacheManager instances fragment cache + each leaks an observer (`DIContainer.swift:79`, `AudioImageRepository.swift:15` default arg, `NowPlayingView.swift:13`, + per-tick C2). → single DI-owned cache; remove `createDefaultCache()` default args.
- **I8.** `BackgroundDownloadService` cross-thread state race on `currentTask`/`currentSubject` (`:30-90`, delegateQueue nil). → confine to serial queue or make `actor`.
- **I9.** Whole-`NowPlayingState` reassignment every tick re-renders full player + lyrics List (`NowPlayingViewModel.swift:83-84`, single `@Published`). → split high-freq `currentTime` into its own published value.
- **I10.** Download filename from server-controlled URL path, percent-decoded AFTER parse → traversal surface (`DownloadAudioFromURLUseCase.swift:61-65`, `BackgroundDownloadService.swift:96-108`). → sanitize: strip `/` `..`, whitelist charset, clamp length.
- **I11.** No SSRF/private-host guard on URL download (HTTPS-only is the only check) (`DownloadAudioFromURLUseCase.swift:52-59`). Bounded (user-initiated, offline app). → reject loopback/private/link-local + `*.local`; document.
- **I12.** Content-type validation bypassable: nil MIME skips check, `.mp3` extension trusts bytes (`BackgroundDownloadService.swift:67-83`). → validate by opening `AVAsset`/`AVAudioFile` post-download; treat nil-MIME as must-sniff.
- **I13.** 26 stray `print()` in production code bypass Logger (`SongRepository`, `PlayerManager`, `ImageCacheManager`×8, `WebServerGCDService`, …). → replace with `Logger.debug/error`. (Subset of C7.)
- **I14 (design).** MVI inconsistent: `ImportSong` + `AddNewSongs`(EditPlaylist) have no Reducer/Action (`EditPlaylistViewModel.swift:48-93` mutates imperatively). → add Reducer/Action or document the exception. Not a data bug.

---

## MODERATE (selected — full list in source reports)

- File-size <200 LOC still violated: `PlayerManager` 448, `ImageCacheManager` 394 (+4 dead dup methods + unused `accessQueue`), `DIContainer+ViewFactory` 344, `NowPlayingViewModel` 311, `CustomTabBar` 311, `NowPlayingFullPlayerView` 296, `CommonLogger` 252, `AudioEngineService` 243, `SongRepository` 232, `Modifiers` 224, +borderline. (refactor plan claimed split — partially regressed.)
- `isFirstInstall`/`firstLaunchDate` dead code with hidden write side-effect (`AppState.swift:56-62`); first-launch→Hub routing never happens. → wire or delete.
- "Recently played" Home section fully stubbed despite working backend (`HomeView.swift:113-129`, `FetchHomeDataUseCase.swift:36` hardcodes `[]`). → finish or remove.
- Sleep-timer "Cancel" in timer menu does nothing (`DIContainer+ViewFactory.swift:181` TODO "Connect to NowPlayingViewModel"). Real functional gap.
- EQ slider drag → UserDefaults write storm (`EQBandSliderView.swift:34-39` → `EQService.persist()` every increment). → debounce persist on drag-end.
- ImageCacheManager: fake memory estimate (`:249-252`), sync disk scan on caller thread (`:172-178`), main-queue LRU hop per hit (`:232-247`), 4 dead methods + unused queue.
- `updateSongs` saves per-item in loop (N saves) (`SongRepository.swift:95-120`). → batch one save.
- URL-download cancel race: late completion can ingest after cancel (`BackgroundDownloadService.swift:47-51` vs `:67-83`). → guard `downloadTask === currentTask`.
- iCloud container is document-scope-public (`Info.plist:46-57`) — verify only user media written there, no Core Data store/tokens.
- HTTPS-only blocks archive.org HTTP links but UI tip says they "work out of the box" (`UrlDownloadView.swift:143`) — misleading. *(Product decision: keep HTTPS-only, fix tip.)*
- Setting placeholder URLs/App Store ID must be filled before submission (`SettingConstants.swift:9,13`).
- `AudioEngineProtocol.currentTime` returns stale value after pause (`AudioEngineService.swift:50-56`) — unused by UI today (uses ProgressTimerService); correctness trap for future callers.

---

## What is GOOD (verified correct — do not touch)
- AVAudioEngine graph: nodes attached up-front, reconnect with native `processingFormat` on load, effects via `.bypass` (no mid-playback reconfigure). Interruption/route-change/media-reset handlers present.
- EQ v1→v2 (3→10 band) migration correct + guarded + one-time legacy key delete.
- AudioEditor export (trim/fade/normalize→M4A): math correct, unique output, background task, progress poll, cleanup-on-failure, registers exported file in library.
- `onOpenURL` + scene-active Documents scan + `.externalImportFinished` wiring correct; `inFlight` guard prevents overlap. Coordinator is `@MainActor` + `[weak self]`.
- Combine sinks all `[weak self]` + `.receive(on:.main)` — no sink retain cycles.
- Waveform scan streamed in capped chunks (bounded memory).
- Security-scoped resource access bracketed + `NSFileCoordinator` for iCloud reads; unsupported formats produce per-file errors, no crash.
- HTTPS-only + 200MB cap enforced; import/download/server errors DO surface to user (no silent swallow).
- `makeEditPlaylistView` is FIXED (real view); demo files (LoggerExample, DemoDelayTouch) already deleted.

---

## Recommended fix order (by risk × effort)
**Wave 1 — correctness/data-loss (do first):** C1 (@MainActor), C3 (import dedup), C5 (transfer queue serialize), C4 (dead Files action), I6 (fetchSongs order), I1 (next() recursion).
**Wave 2 — release-blockers (before submission):** C6 (Local Network plist), C7+I13 (release logging), I4 (web server auth/stop), I2 (delete orphan), Setting placeholder URLs/ID.
**Wave 3 — perf/memory:** C2 + I7 (shared cache, stop per-tick alloc), I9 (split currentTime publish), I5 (async store load), ImageCacheManager cleanup.
**Wave 4 — hardening/UX:** I10/I11/I12 (download sanitize/SSRF/sniff), I3 (async iCloud wait), download cancel race, EQ debounce, archive.org tip.
**Wave 5 — debt:** file-size splits, dead code (isFirstInstall, Recently-played, dead cache methods), MVI consistency.

## Open questions for product owner
1. **URL download HTTP:** keep HTTPS-only (reject archive.org HTTP, fix the misleading tip) — confirm? *(Reviewer consensus: keep HTTPS-only.)*
2. **Web Upload threat model:** "trusted home Wi-Fi only" accepted, or add per-session passcode given delete/rename are exposed?
3. **First-launch → Import Hub:** intended UX (wire it) or drop `isFirstInstall`/`firstLaunchDate` as dead?
4. **Recently-played Home section:** finish or remove?
5. Device verification needed: does Web Upload trigger the Local Network prompt (Bonjour)?
