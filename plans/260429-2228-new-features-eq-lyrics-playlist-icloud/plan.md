---
title: "MusicApp — 4 New Features: iCloud, Lyrics, Smart Playlist, Equalizer"
description: "Sequential rollout of iCloud verification, .lrc lyrics, rule-based smart playlists, and AVAudioEngine-based 3-band EQ."
status: complete
priority: P2
effort: 10.5d
branch: Master
tags: [ios, swiftui, mvi, audio, coredata, icloud]
created: 2026-04-29
---

# MusicApp — 4 New Features Plan

## Goal
Add 4 user-facing features in strict order. Phase 04 (EQ) requires audio engine migration — highest risk, last.

## Phase Index

| # | Phase | Effort | Status | Risk | File |
|---|-------|--------|--------|------|------|
| 01 | iCloud Drive verification & entitlements | 0.5d | ✅ complete | Low | [phase-01-icloud-verification.md](phase-01-icloud-verification.md) |
| 02 | Lyrics (.lrc file support) | 2d | ✅ complete | Low | [phase-02-lyrics-lrc-support.md](phase-02-lyrics-lrc-support.md) |
| 03 | Smart Playlist (rule-based) | 3d | ✅ complete | Medium | [phase-03-smart-playlist.md](phase-03-smart-playlist.md) |
| 04 | Equalizer + AVAudioEngine migration | 5d | ✅ complete | **High** | [phase-04-equalizer-avaudioengine.md](phase-04-equalizer-avaudioengine.md) |

## Dependency Graph
```
P01 (iCloud) ──┐
               ├──> P02 (Lyrics) ──> P03 (Smart Playlist)
               │
               └─────────────────────────────────────────> P04 (EQ)
```
- P02 reuses P01's verified import flow (`ImportSongFromFilesUseCase` extension).
- P03 independent of P02 (touches CoreData/Library only).
- P04 independent — but most disruptive; do last so other features stable before audio rewrite.

## Cross-Phase Constraints
- MVI pattern: every new screen ships State/Intent/Action/Reducer/ViewModel.
- DI: register all new use cases in `DIContainer+UseCases.swift`.
- Files <200 LOC; kebab-case names.
- No third-party libs.
- All persistence via existing CoreData stack (P03) or filesystem (P02 lyrics).

## Rollback Strategy
- P01: revert entitlements file + Info.plist.
- P02: feature-flag toggle in NowPlayingFullPlayerView; lyrics files harmless if orphaned.
- P03: hide smart-playlist UI entry; existing CoreData migrations must be additive (new entity, no schema change to Song).
- P04: keep `AVAudioPlayer` impl behind protocol on a branch; can swap `AudioEngineProtocol` binding in DIContainer back if regressions.

## Success Criteria (overall)
- Each phase merges independently, no regression in existing playlist/playback flows.
- Manual smoke test matrix passes on iPhone 15 sim + 1 physical device per phase.
- All new code unit-tested where logic exists (parsers, predicate builders, preset math).

## Unresolved Questions
- P02: lyrics keying — by song filename, song id, or content hash? (Plan assumes filename stem; revisit if user re-imports.)
- P03: should smart playlists be playable via shuffle/queue identical to manual playlists? (Assume yes.)
- P04: should EQ apply to AirPlay output? (Assume local route only for v1.)
