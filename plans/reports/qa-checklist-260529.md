# QA Checklist — Audio Editing + Import Expansion (Phase 08)

**Date:** 2026-05-29
**Plan:** `plans/260526-audio-editing-and-import-expansion/`
**Verifier:** dev-qa-docs
**Method:** Automated build/test + static code reading. UI/device cases marked NEEDS-DEVICE.

## Build / Test Result

| Check | Result | Detail |
|-------|--------|--------|
| `pod install` | N-A | Pods already installed (GCDWebServer present in `Pods/`) |
| `xcodebuild build` (MusicApp, iPhone 17 Pro sim) | **PASS** | `** BUILD SUCCEEDED **`, exit 0. Only warning: AppIntents metadata extraction skipped (benign, no AppIntents dep) |
| `xcodebuild test -only-testing:MusicAppTests` | **PASS** | `** TEST SUCCEEDED **`, exit 0. `LyricsStemMatchingTests` (12 methods: normalize, lyricsStem extraction, repo exact + normalized-fallback load) all green |

## Legend
- **AUTO-VERIFIED** — confirmed by build/test or by reading wiring in source (cited)
- **NEEDS-DEVICE** — requires running app + manual interaction / external device
- **N-A** — not applicable / out of scope this phase

---

### Lyrics (P00)
| Case | Status | Evidence |
|------|--------|----------|
| Exact stem match | AUTO-VERIFIED | `LyricsRepository.load` exact path `LyricsRepository.swift:36-38`; test `test_repository_loadsExactStem` |
| Vietnamese diacritics | AUTO-VERIFIED | `normalize` folds diacritics `LyricsRepository.swift:97-106`; test `test_normalize_stripsDiacritics_vietnamese` ("Hạ Trắng"→"hatrang") |
| Casing mismatch | AUTO-VERIFIED | case-insensitive fold; test `test_normalize_lowercases`, `test_repository_loadsViaNormalizedFallback` |
| Space ↔ underscore | AUTO-VERIFIED | collapses `[\s_-]` `LyricsRepository.swift:102`; test `test_normalize_collapsesWhitespaceAndPunct` |
| Paste lyrics inline | AUTO-VERIFIED | `AttachLyricsToSongUseCase.executeFromText` with empty guard `AttachLyricsToSongUseCase.swift:25-31` |
| Remove lyrics | AUTO-VERIFIED | `RemoveLyricsUseCase` + `LyricsRepository.delete` `LyricsRepository.swift:47-50` |
| Toggle button disabled when empty | NEEDS-DEVICE | UI state in `NowPlayingFullPlayerView` — render check |
| activeLyricIndex when time < first | AUTO-VERIFIED | `NowPlayingStateReducer.activeLyricIndex(for:in:)` `NowPlayingStateReducer.swift:90` |

### EQ 10-band (P01)
| Case | Status | Evidence |
|------|--------|----------|
| All 10 sliders realtime | NEEDS-DEVICE | `setBandGain` writes hardware `EQService.swift:53-61`; slider binding in `EqualizerView` — audible check on device |
| 6 built-in presets apply | AUTO-VERIFIED | `EQPreset` flat/bassBoost/pop/rock/classical/jazz + custom, 10-band gains `EQPreset.swift:6-46`; `applyPreset` `EQService.swift:45` |
| Save custom preset | AUTO-VERIFIED | `SaveUserEQPresetUseCase` + `UserEQPresetRepository.swift` |
| Load custom preset post-restart | NEEDS-DEVICE | persistence wired (`restorePersistedState` `EQService.swift:79`); restart-survival = device |
| Migrate v1 (3-band)→v2 (10-band) | AUTO-VERIFIED | `migrateLegacyGainsIfNeeded` reads `eqGains` len-3, projects to 10, deletes legacy key `EQService.swift:103-114` |
| A/B bypass | AUTO-VERIFIED | `setBypass` toggles `eqNode.bypass` `EQService.swift:73-77` |

### Effects (P02)
| Case | Status | Evidence |
|------|--------|----------|
| Speed 0.5x audible | NEEDS-DEVICE | `setSpeed` clamps 0.5–2.0 → `timePitchNode.rate` `AudioEffectsService.swift:37-42` |
| Pitch +5st audible, tempo same | NEEDS-DEVICE | `setPitch` semitones×100=cents → `timePitchNode.pitch` `AudioEffectsService.swift:44-49` |
| Reverb cathedral wet 50% | NEEDS-DEVICE | `ReverbPreset.cathedral` (rawValue 8) `ReverbPreset.swift:13`; `setReverbWetDryMix` `AudioEffectsService.swift:57` |
| Bypass each independently | AUTO-VERIFIED | timePitch auto-bypass when neutral `AudioEffectsService.swift:86-89`; reverb bypass `:70-75`; EQ bypass separate node |
| Persist post-restart | NEEDS-DEVICE | `restorePersistedState`/UserDefaults `AudioEffectsService.swift:100-110` |

### Audio Editor Export (P03)
| Case | Status | Evidence |
|------|--------|----------|
| Trim 30s file | AUTO-VERIFIED | composition insertTimeRange `ExportEditedAudioUseCase.swift:62-66` (≥1s guard `:47`) |
| Trim 4-min file | AUTO-VERIFIED | same path; timescale 600 |
| Fade in 5s + fade out 5s | AUTO-VERIFIED | `setVolumeRamp` in/out `ExportEditedAudioUseCase.swift:76-92` |
| Normalize quiet file | AUTO-VERIFIED | `ComputeNormalizationGainUseCase` peak→0.95FS, clamp[0.5,3.0] `:34-35`; applied as base volume `Export…:72` |
| Cancel export mid-way | AUTO-VERIFIED | `.cancelled` → remove file + throw `ExportEditedAudioUseCase.swift:135-137` |
| Background export survives backgrounding | NEEDS-DEVICE | `beginBackgroundTask`/`endBackgroundTask` `Export…:109-118` — device backgrounding |

### Share Ext + AirDrop (P04)
| Case | Status | Evidence |
|------|--------|----------|
| AirDrop from Mac 1 mp3 | NEEDS-DEVICE | `onOpenURL`→`ExternalFileImportCoordinator.handle` `MusicApp.swift:31-34` (AirDrop path) |
| Share Sheet in Safari | NEEDS-DEVICE | Share Extension target — **deferred** (artifact written, pbxproj target add pending; owned by other teammate) |
| Share Sheet in Mail | NEEDS-DEVICE | same — deferred |
| Multi-file share 5 files | NEEDS-DEVICE | coordinator `importBatch` accepts arrays `ExternalFileImportCoordinator.swift:47` |

### URL Download (P05)
| Case | Status | Evidence |
|------|--------|----------|
| archive.org direct mp3 | NEEDS-DEVICE + FLAG | `DownloadAudioFromURLUseCase.sanitizedHTTPSURL` accepts **HTTPS only** `:52-58`. Many archive.org links are HTTP → would be rejected as invalid. See Findings. |
| Dropbox direct link | NEEDS-DEVICE | HTTPS Dropbox links pass; `inferFilename` handles query/ext `:61-65` |
| Invalid URL rejected | AUTO-VERIFIED | non-HTTPS / no-host → `.failed(.invalidURL)` `DownloadAudioFromURLUseCase.swift:24-26,52-58` |
| Background download | NEEDS-DEVICE | `BackgroundDownloadService.shared` injected `:16` |
| Cancel mid-download | AUTO-VERIFIED | `cancel()`→`service.cancelCurrent()` `:46-48` |

### iTunes Sharing + Open-in (P06)
| Case | Status | Evidence |
|------|--------|----------|
| Finder drag 3 files | NEEDS-DEVICE | `scanDocumentsRootAndImport` on scenePhase active `MusicApp.swift:38-43` + `ExternalFileImportCoordinator.swift:29-43` |
| Files app "Open in MusicApp" | NEEDS-DEVICE | `onOpenURL`→coordinator `MusicApp.swift:31-34` |
| No duplicate on rescan | AUTO-VERIFIED (logic) | scan skips managed dirs (Music/Lyrics/Inbox); dedup delegated to `ImportSongFromFilesUseCase` — device confirms dedup |

### Import Hub (P07)
| Case | Status | Evidence |
|------|--------|----------|
| First-launch routes to Hub | **NOT IMPLEMENTED** | No first-launch routing to Hub exists. `firstLaunchDate` recorded `AppState.swift:57-58` but never used to present Hub. Hub reached only via Library `LibaryView.swift:95`. See Findings. |
| All method tap actions | PARTIAL / FLAG | 5 rows present (not 6): URL `router.route(.urlDownload)` ✓, Web Transfer `.switchMainTab→transfer` ✓ (handler `MainTabView.swift:78`), AirDrop + iTunes = info alerts ✓. **"Pick from Files" posts `.openImportFromFiles` which has NO listener — dead action.** See Findings. |
| Tutorial sections render | NEEDS-DEVICE | info-alert copy present `ImportHubView.swift:62-75` |

### Regression
| Case | Status | Evidence |
|------|--------|----------|
| Playback existing song | AUTO-VERIFIED (build) | AVAudioEngine graph builds + loads file `AudioEngineService.swift:101-127`; full build passes |
| Create playlist | NEEDS-DEVICE | existing flow, unchanged this plan |
| Smart playlist | NEEDS-DEVICE | existing flow, unchanged this plan |
| Background audio | NEEDS-DEVICE | `.playback` session category `AudioEngineService.swift:97` |
| Sleep timer | NEEDS-DEVICE | existing flow, unchanged this plan |

---

## Findings (flagged dead / incomplete paths)

1. **ImportHub "Pick from Files" is a dead action.** `ImportHubView.swift:46` posts `Notification.Name.openImportFromFiles`, but grep across `MusicApp/**` finds **zero** observers. Tapping the row dismisses the hub and does nothing. Either add a listener (e.g. in Library/Settings to present the existing ImportSong screen) or route directly. Severity: medium (advertised entry point non-functional).

2. **First-launch routing to Import Hub not implemented.** Phase matrix lists "First-launch routes to Hub". Only `firstLaunchDate` is stored (`AppState.swift:57-58`); it is never read to present the Hub. Hub is reachable only manually from Library (`LibaryView.swift:95`). Severity: low–medium (onboarding gap, not a crash).

3. **URL download rejects HTTP (HTTPS-only).** `sanitizedHTTPSURL` (`DownloadAudioFromURLUseCase.swift:52-58`) accepts `https` only. The matrix's "archive.org direct mp3" case will commonly fail because many archive.org direct file links are `http://`. This is likely an intentional ATS/security decision, but it diverges from the QA expectation — confirm intent or relax to allow ATS-compliant HTTP. Severity: low (security-conscious default; flagged for product decision).

4. **ImportHub has 5 rows, matrix says 6.** AirDrop and Share Sheet are collapsed into one info row; this is a reasonable consolidation, not a defect. No action needed beyond noting the count divergence.

## Summary
- Build: PASS. Unit tests: PASS. No compile errors, one benign metadata warning.
- All P00–P03, P05, P06 core logic is real and wired (no stubs).
- P04 Share Extension is deferred (target add pending in Xcode) — artifact prepared by another teammate.
- P07 Import Hub is wired but has 2 gaps: dead "Pick from Files" action + missing first-launch routing.
- Auto-verifiable cases pass. Audible/persistence/backgrounding/external-device cases require manual device QA.

## Unresolved Questions
- Is HTTPS-only download intentional (ATS) or should HTTP archive.org links be supported?
- Should "Pick from Files" wiring + first-launch Hub routing be completed in this plan or tracked as follow-up?
