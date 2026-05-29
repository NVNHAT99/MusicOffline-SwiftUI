# Audio Editing + Import Expansion — Shipped (P04 Share Ext deferred)

**Date**: 2026-05-29
**Severity**: Medium
**Component**: Lyrics (LyricsRepository normalize/index), Equalizer (10-band + v1→v2 migration), Effects (AVAudioUnitTimePitch + AVAudioUnitReverb), Audio editor (AVAssetExportSession), Import (ExternalFileImportCoordinator, URL download, Import Hub)
**Status**: Resolved (build PASS, MusicAppTests PASS)

## What Happened

Eight sub-phases of `plans/260526-audio-editing-and-import-expansion/`:

- **P00** Fixed the lyrics matching pipeline — the load-bearing piece that decides whether a song's lyrics ever surface.
- **P01** Expanded 3-band EQ → 10-band parametric, with a one-time v1→v2 UserDefaults migration.
- **P02** Added speed/pitch/reverb via `AVAudioUnitTimePitch` + `AVAudioUnitReverb` inserted into the engine graph.
- **P03** Non-destructive audio editor: trim + fade + normalize → M4A export.
- **P04** Share Extension — code artifact written; **target add deferred** (no pbxproj surgery this pass).
- **P05–P07** URL download, iTunes/Finder + Open-in import, and an Import Hub screen, all funneled through one coordinator.

Build succeeds on the iPhone 17 Pro simulator; `MusicAppTests` (lyrics matching suite) passes. QA matrix: `plans/reports/qa-checklist-260529.md`.

## Lessons

### 1. Lyrics fix root cause — matching was too literal
Lyrics failed to surface whenever the on-disk `.lrc` stem differed from the song filename by casing, diacritics, or separators (`My Song` vs `my_song` vs `Hạ Trắng`). The fix is a deterministic fallback chain — exact → case-insensitive → fully normalized (`folding(.diacriticInsensitive, .caseInsensitive)` then strip `[\s_-]` and NBSP) — backed by an in-memory index keyed on the normalized stem.

The non-obvious decision: when two files normalize to the **same** key, return `nil` and log, rather than guessing. Loading the *wrong* lyrics silently is worse than loading none — the user can attach manually. Ambiguity is a first-class outcome, not an error to paper over.

### 2. AVAudioEngine graph reconfigure pitfalls
Effect nodes (`timePitch`, `reverb`, `eq`) are attached **once** at graph-build time and toggled with `.bypass` — never detached/reattached at runtime. Stopping the engine to add/remove a node causes an audible pop; `.bypass` is silent and cheap.

Two reconfigure traps:
- **Format on load.** On every `load(url:)` the whole chain is disconnected and reconnected with the file's *native* `processingFormat`. Skip this and the engine pulls a default format → sample-rate-conversion artifacts. There is no Apple doc for this; it's trial-and-error tribal knowledge.
- **TimePitch is one node carrying two params.** Speed and pitch both live on `AVAudioUnitTimePitch`. It must be bypassed iff *both* are neutral (`rate≈1.0 && pitch≈0`), not per-parameter — otherwise touching speed re-enables a node that should stay transparent for pitch-only edits.
- **Media-services reset** wipes the graph; the engine has to rebuild + reload the current URL on `mediaServicesWereResetNotification` or playback dies silently after a reset.

### 3. AVAssetExportSession edge cases
- **Composition coordinate space.** After trimming into an `AVMutableComposition`, the timeline restarts at 0. Fade ramps must be expressed in *composition* time, not source time — fade-out start is `total - fadeOut`, not `trimEnd - fadeOut`.
- **No native progress callback.** `AVAssetExportSession` exposes `.progress` but no delegate; we poll every 200 ms in a `Task` and cancel it once `export()` returns. Always force `onProgress(1.0)` after — the poller may exit before reading the final value.
- **Partial files on failure.** `.failed`/`.cancelled` leave a zero/partial file at `outputURL`. Remove it explicitly before throwing, or the next export's uniquify-loop counts it as a real track.
- **Backgrounding.** Wrap the export in `beginBackgroundTask`/`endBackgroundTask` so a short app-switch doesn't kill it. Full backgrounding survival still needs device verification.

### 4. Decision: M4A (AAC) over MP3 output
The editor exports **M4A/AAC**, not MP3. AVFoundation ships a first-class `AVAssetExportPresetAppleM4A`; there is **no** built-in MP3 *encoder* on iOS (decode-only). Shipping MP3 would mean bundling LAME or similar — extra binary size, licensing friction, and a hand-rolled encode path. M4A is smaller at equal quality, universally playable on Apple devices, and zero-dependency. Not worth the MP3 tax for an offline player.

### 5. Decision: peak normalization over LUFS
`ComputeNormalizationGainUseCase` does **peak** normalization (scan max sample → `0.95/peak`, clamp [0.5, 3.0]), not LUFS/integrated loudness. LUFS is the "correct" perceptual target but needs K-weighting filters + gating windows — a real DSP dependency or a lot of hand-written math. Peak is a single cheap pass over the PCM buffer, runs on a detached task, and is good enough to rescue a quiet clip without clipping. The clamp prevents both runaway gain on near-silent files and attenuation surprises on already-hot sources. Revisit LUFS only if users report inconsistent loudness across edited tracks.

### 6. Share Extension memory budget (deferred — noted for next pass)
The Share Extension (P04) was left as a code artifact because adding the app-extension target is pbxproj surgery we deferred. Worth flagging for whoever wires it: share extensions run under a **tight memory budget (~120 MB)** and get killed hard if exceeded. Copy the incoming file to the app group / Documents and hand off — do **not** decode, normalize, or export inside the extension. AirDrop/Open-in already work today via `onOpenURL`, so the extension is additive, not blocking.

## Known Gaps (carried forward)
- Import Hub "Pick from Files" posts `.openImportFromFiles` with **no listener** — dead action. Add an observer (Library/Settings presents the existing ImportSong screen) or route directly.
- **First-launch routing to Import Hub** is not implemented; only `firstLaunchDate` is recorded. Hub is reachable only from Library.
- URL download is **HTTPS-only** — archive.org's common HTTP direct links are rejected. Confirm whether this ATS-driven default should relax.

## Unresolved Questions
- Is HTTPS-only download an intentional ATS posture, or should ATS-compliant HTTP be allowed for archive.org-style hosts?
- Complete the Import Hub "Pick from Files" wiring + first-launch routing in this plan, or track as a follow-up phase?
- When is the Share Extension target add scheduled (needs Xcode pbxproj work + memory-budget validation on device)?
