# Security / Privacy / UX-Robustness Review — MusicOffline-SwiftUI

Reviewer: reviewer-security · Date: 2026-05-29 · Scope: `MusicApp/` · Build+tests pass.

Severity legend: CRITICAL = ship-blocker (data exposure / store rejection / crash), IMPORTANT = fix before release, MODERATE = should fix.

---

## CRITICAL

[CRITICAL] No `NSLocalNetworkUsageDescription` (nor any usage-description string) in Info.plist while the app runs a local HTTP server.
— Evidence: `MusicApp/Info.plist:1-59` contains zero `*UsageDescription` keys (grep over `MusicApp/` returns none). The Web Upload feature binds a `GCDWebUploader` on the LAN: `MusicApp/Core/WebServerGCDService.swift:59,90-96` (port 61234). iOS 14+ triggers a Local Network permission prompt the first time a process accesses the local network; without `NSLocalNetworkUsageDescription` the prompt has no rationale string and App Store review commonly rejects this, and on device the access can silently fail.
— Recommendation: Add `NSLocalNetworkUsageDescription` (e.g. "Used to transfer music from your computer over Wi-Fi") and, if Bonjour advertising is used by the uploader, `NSBonjourServices`. Verify the permission prompt appears and the server is reachable after granting.

[CRITICAL] Verbose Logger ships in release and logs file paths / server URL / IP to stdout unconditionally (no `#if DEBUG` gate).
— Evidence: `MusicApp/Commons/Logger/CommonLogger.swift:152-195` ends in a bare `print(logMessage)`; minimum level defaults to `.debug` (`:43`) and is set to `.debug` at startup with no build guard — `MusicApp/Presentation/Feature/App/MusicApp.swift:18-22`. Path/PII-bearing call sites: documents path `WebServerGCDService.swift:61`; server URL/IP `:80,:113`; uploaded/deleted/moved file paths `:144,:149,:154`; missing-song path `Core/PlayerManager.swift:358`; uploaded path `Setting/SettingViewViewModel.swift:104`; external file name `App/MusicApp.swift:32`. These are written to the device console/`os_log` sink in production.
— Recommendation: Wrap the actual emit in `#if DEBUG` (or route through `os.Logger` with `.private` interpolation and disable `.debug`/`.info` in release). At minimum gate `Logger.setup` level by build config so release defaults to `.warning`+. Do not log absolute file paths.

---

## IMPORTANT

[IMPORTANT] Web upload server has no authentication and stays running after you leave the Transfer screen.
— Evidence: `WebServerGCDService.swift:90-96` starts the uploader with only `Port` + `AutomaticallySuspendInBackground:false`; no `GCDWebServer` username/password/`AuthenticationMethod` is set, so anyone on the same Wi-Fi who reaches `http://<phone-ip>:61234/` can browse/upload/delete/rename files in the app's Documents folder (delegate handles delete/move: `:148-156`). The server is only stopped on `.toggleServer` (`TransferViewModel.swift:127-132`, `SettingViewViewModel.swift:123-124`) and on app-background (`Core/Application/SystemEventsHandler.swift:43-53`). `TransferView.swift` has NO `.onDisappear`/scenePhase stop, so navigating back / to another tab while staying foreground leaves the server live and unmonitored. Background-stop relies on `.background`; during `.inactive` (transition, control center, incoming call) the server is still up.
— Recommendation: (1) Stop the uploader in `TransferView.onDisappear` and on `.inactive`, not only `.background`. (2) Consider a per-session passcode shown in-app (GCDWebServer supports basic auth) given delete/move are exposed. (3) Document that this is LAN-only by design; it is (GCDWebServer binds all interfaces but is plain HTTP on the local subnet) — the real risk is hostile peers on shared/public Wi-Fi.

[IMPORTANT] Downloaded-file destination name is derived from server-controlled URL path with no sanitization of the base name.
— Evidence: `DownloadAudioFromURLUseCase.inferFilename` (`Domain/UseCases/Import/DownloadAudioFromURLUseCase.swift:61-65`) takes `url.lastPathComponent` (percent-decoded) verbatim; `BackgroundDownloadService.uniqueDestinationURL` (`Core/BackgroundDownloadService.swift:96-108`) splits into base+ext and does `dir.appendingPathComponent("\(base).\(ext)")`. A decoded `lastPathComponent` containing `/` or `..` (e.g. URL `https://h/a%2F..%2Fevil.mp3`) feeds path separators into `appendingPathComponent`. `lastPathComponent` normally strips slashes, but the explicit `removingPercentEncoding` at `:62` reintroduces `/` and `..` after URL parsing, so the resulting `base` can contain traversal segments before being re-joined. Writes are confined under Documents/Music in the common case, but the decode-after-parse ordering removes the guarantee.
— Recommendation: Sanitize the inferred name: strip path separators and `..`, disallow leading dots, clamp length, and re-encode/whitelist `[A-Za-z0-9._- ]`. Build the destination from the sanitized base only. Apply same hardening to `ImportSongFromFilesUseCase.copyFile` which uses `sourceURL.lastPathComponent` (`ImportSongFromFilesUseCase.swift:121`) — for security-scoped Files URLs this is low-risk, but the .lrc `stem` path (`:57`) flows into `lyricsRepository.save(stem:)` and should be checked there too.

[IMPORTANT] No SSRF / target-host restriction on URL download; HTTPS-only is the sole guard.
— Evidence: `sanitizedHTTPSURL` (`DownloadAudioFromURLUseCase.swift:52-59`) accepts any `https` URL with a non-empty host; `BackgroundDownloadService.download` (`:36-45`) issues the request with no host allow/deny list. A user can be social-engineered into pasting `https://192.168.x.x/...`, `https://localhost/...`, or a cloud metadata endpoint; the app will fetch it. Impact is bounded (offline music player, no server-side proxy, response only saved as a file if it passes the audio check), so this is user-initiated SSRF with limited blast radius rather than a server-side SSRF.
— Recommendation: Acceptable to defer given the threat model, but at minimum reject obvious private/loopback/link-local hosts (`127.0.0.0/8`, `10/8`, `172.16/12`, `192.168/16`, `169.254/16`, `::1`, `fc00::/7`) and `*.local`. Document the decision.

[IMPORTANT] Content-type validation is bypassable; a non-audio body can be saved if the URL ends in an audio extension.
— Evidence: `BackgroundDownloadService.urlSession(_:downloadTask:didFinishDownloadingTo:)` (`:67-83`): the MIME check (`:72-75`) only throws when `mime` is present AND not `audio/*` AND the suggested name extension is not in the acceptable set. If `response.mimeType` is nil (common for some servers) the check is skipped entirely; if the URL ends in `.mp3` the check passes regardless of actual bytes. No magic-byte / header sniffing. Downstream `AVAsset` metadata load will simply fail later, surfaced as an import error — so this is a robustness/quality issue, not RCE.
— Recommendation: After download, validate the audio by attempting an `AVAsset`/`AVAudioFile` open (or sniff the first bytes for known audio magic) before adding to the library; delete the temp file on failure. Treat nil-MIME as "must sniff", not "trust extension".

---

## MODERATE

[MODERATE] HTTPS-only blocks archive.org HTTP direct links — in-app tip is misleading. (Product decision, not a vuln.)
— Evidence: `sanitizedHTTPSURL` requires `scheme == "https"` (`DownloadAudioFromURLUseCase.swift:55-56`); the UI explicitly tells users "archive.org direct links work out of the box" (`Import/UrlDownload/UrlDownloadView.swift:143`). Many archive.org direct file URLs are served over plain HTTP, which will be rejected with "Invalid URL" — a confusing UX gap. The HTTPS-only choice itself is correct (ATS-aligned, avoids needing an `NSAllowsArbitraryLoads` exception that risks store rejection).
— Recommendation: Keep HTTPS-only. Fix the tip text to set expectations ("HTTPS links only; some archive.org links are HTTP and won't work — use the https:// variant"). Optionally surface a clearer error than the generic invalid-URL when the only problem is a non-HTTPS scheme.

[MODERATE] URL-download cancel is not fully race-safe; a late completion can still ingest after cancel.
— Evidence: `BackgroundDownloadService.cancelCurrent` (`Core/BackgroundDownloadService.swift:47-51`) nils `currentTask`/`currentSubject`, but `didFinishDownloadingTo` (`:67-83`) and the use-case's `.completed` tap (`DownloadAudioFromURLUseCase.swift:31-42`, which spawns a detached `Task` calling `addSong.execute`) capture the subject/closure independently. A download that finishes in the same runloop tick as cancel can still move the file and call `addSong`. Single-task model also means starting a new download silently cancels the old one (`download` calls `cancelCurrent` at `:37`) with no user feedback. No `[weak self]` on the ingest `Task` (`:35`) — minor retain during ingest.
— Recommendation: Guard `didFinishDownloadingTo`/`progress` against a cancelled/replaced task (compare `downloadTask === currentTask`). Ignore completion if the subject was cleared.

[MODERATE] iCloud container is document-scope public; ensure no private/internal files land there.
— Evidence: `Info.plist:46-57` sets `NSUbiquitousContainerIsDocumentScopePublic` = true for `iCloud.com.nph.OffIMuzikBox`; entitlements grant `CloudDocuments` (`MusicApp.entitlements:9-12`). Document-scope-public means the container's Documents folder is user-visible in the Files app. This is fine for user music, but any cache/metadata/sqlite the app might write into the ubiquity container would also be exposed.
— Recommendation: Confirm only user-facing media is written to the ubiquity Documents folder; keep app-internal data in the app sandbox (it currently uses local Documents/Music + Core Data, so this is likely fine — verify no Core Data store or token is ever placed in the iCloud container).

[MODERATE] iCloud materialization blocks a thread for up to 30s with `Thread.sleep` in a 1s poll loop.
— Evidence: `ImportSongFromFilesUseCase.ensureLocallyAvailable` (`:146-162`) loops `for _ in 0..<30 { Thread.sleep(forTimeInterval: 1) ... }`. Called from `copyFile`/`readTextFile` inside the `async execute` (`:75-77,:59`). This blocks the executing thread (not cooperative async suspension); for a batch import of N iCloud-placeholder files this serializes up to 30s each and can stall the import with no cancel path. UX: the import progress UI (`ImportSongViewModel.swift:41-53`) will appear frozen.
— Recommendation: Replace with async/await (`Task.sleep`) and a single overall timeout/cancel; surface a per-file "downloading from iCloud…" state.

[MODERATE] `canStart` URL gate is weak (`count > 10` + `https://` prefix only).
— Evidence: `UrlDownloadState.canStart` (`Import/UrlDownload/UrlDownloadState.swift:10-14`). `"https://x.xx"` passes; combined with the lenient `sanitizedHTTPSURL` (only checks scheme+non-empty host) the user can kick off requests to malformed/odd hosts. Low impact (download just fails), but the button-enabled state misleads.
— Recommendation: Validate via `URLComponents` (host present, has a path or looks like a file) before enabling Download.

---

## Positive observations

- HTTPS-only enforced for URL download (`DownloadAudioFromURLUseCase.swift:55-56`) — correct ATS-aligned choice.
- 200 MB size cap enforced early via `totalBytesExpectedToWrite` and cancels the task (`BackgroundDownloadService.swift:34,57-61`).
- Web server IS stopped on app background (`SystemEventsHandler.swift:43-53`) — limits the always-on exposure window.
- GCDWebServer pinned at 3.5.4 (`Podfile.lock`) — current; GCDWebUploader sandboxes uploads to the configured directory and rejects `..` traversal in its request handler. (Constraint `~> 3.0` is loose; consider pinning tighter.)
- Import + URL-download errors DO reach the user: import results sheet (`ImportSongViewModel.swift:48-52`, results surfaced), URL errors shown as a tappable toast (`UrlDownloadView.swift:36-48`); server start/stop failures toast (`TransferViewModel.swift:93-96`, `SettingViewViewModel.swift:81-91`). Failures are not silently swallowed.
- Security-scoped resource access is correctly bracketed with start/stop + `defer` for imported files (`ImportSongFromFilesUseCase.swift:94-95,115-116`) and uses `NSFileCoordinator` for iCloud-safe reads (`:130-136`).
- Unsupported file formats and decode failures produce per-file `ImportSongResult` errors rather than crashing (`ImportSongFromFilesUseCase.swift:69-73,79-83`).

---

## Unresolved questions

1. Does the Web Upload feature trigger the iOS Local Network prompt on a real device today (i.e., does GCDWebServer advertise Bonjour)? If yes, the missing `NSLocalNetworkUsageDescription` is a hard store-rejection / functional blocker; if it binds without Bonjour the prompt may not fire — needs device verification.
2. Is anything other than user media ever written into the iCloud ubiquity container (Core Data store, caches, tokens)? Needs a grep of write paths against the ubiquity URL to fully clear the document-scope-public exposure.
3. Intended threat model for Web Upload — is "trusted home Wi-Fi only" an accepted constraint, or should per-session auth be added before release?
