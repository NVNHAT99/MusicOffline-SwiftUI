---
title: "UI/UX Design-System Overhaul — Dynamic Artwork Color + Motion"
description: "Kill the monotone grey look: artwork-driven color + tasteful animations applied app-wide via an extended design system."
status: done
priority: P2
effort: ~26h (9 phases)
branch: Master
tags: [ui, design-system, swiftui, animation, accessibility, color]
created: 2026-05-29
---

# UI/UX Design-System Overhaul

Refactor the design system, then apply it to every screen. Headline change: a
per-song **dynamic color** extracted from album artwork drives a background
gradient + accent color (Apple Music / Spotify style), replacing the flat
`#1C1C1E` grey used across ~29 files. Add **moderate** motion: press feedback +
haptics, list/card entrance, smooth transitions, springy mini↔full player.

Stack reality (verified): SwiftUI, **iOS 17.6** target, **Swift 5.0** language
(NOT Swift 6 — `project.pbxproj`), MVI + Clean Arch + DI. iOS 17 APIs available:
`.sensoryFeedback`, `PhaseAnimator`, `KeyframeAnimator`, `onChange(of:_:)` 2-arg.

## Execution model
Sequential, single agent. **User approves each phase before the next.** Each
phase is self-contained and independently shippable/reviewable.

## Skills
`/ck:design-system-architect` (tokens), `/ck:ios-swiftui-modern` (motion/haptics),
`/ck:ios-hig-accessibility` (contrast, Reduce Motion, Dynamic Type, VoiceOver).

## Phases
| #  | Phase | Status | Summary |
|----|-------|--------|---------|
| 01 | [Foundation: color + motion tokens](phase-01-foundation-color-motion-tokens.md) | done | Color token layer, motion presets, haptics, view modifiers — NO screen changes |
| 02 | [Artwork color-extraction engine](phase-02-artwork-color-extraction-engine.md) | done | `ArtworkColorExtractor` + per-song cache + contrast/legibility guarantees (7 tests green) |
| 03 | [Now Playing showcase (full + mini)](phase-03-now-playing-showcase.md) | done | Dynamic gradient + themed accent + press/haptics; full player split into 5 files (<200 LOC). Build clean. Visual not eyeballed (sim has no songs) |
| 04 | [Shared components + dedupe](phase-04-shared-components-and-dedupe.md) | done | 3 orphans deleted; tab bar (accent active + haptic, verified on-device), SongItemView, nav bar, slider, playlist row restyled |
| 05 | [Home + Library + PlaylistDetail](phase-05-home-library-playlistdetail.md) | done | AppFont/tokens, entrance animations, accent FABs + press feedback. Build clean |
| 06 | [Playlist editors + Import + Transfer](phase-06-editors-import-transfer.md) | done | 11 View files: tokens + press/haptics + entrance + success feedback. No logic touched. Build clean |
| 07 | [Settings + Equalizer + AudioEditor](phase-07-settings-equalizer-audioeditor.md) | done | 9 View files: tokens, themed EQ/waveform sliders, detent/grab haptics. EQ 189/AudioEditor 187 LOC. Build clean |
| 08 | [Sheets + remaining surfaces](phase-08-sheets-and-remaining.md) | done | 9 sheets/overlays restyled; ToastView animated; shimmer tuned; residual text colors cleaned. Build clean |
| 09 | [QA pass + docs](phase-09-qa-and-docs.md) | done | Residual-color audit (0 cyan accents, 18 haptics, Reduce Motion covered), 7 contrast tests green, docs/design-guidelines.md + changelog written |

## Key dependencies
- P02 depends on P01 (color token types + protocols).
- P03 depends on P01 + P02 (consumes extractor + tokens; proves the language).
- P04..P08 depend on P03 approval (visual language locked) + P01/P02 utilities.
- P09 depends on all prior phases.

## Cross-cutting risks (detailed per phase)
- **Perf**: never extract color on redraw — compute off main thread, cache per
  song key (reuse `ImageCacheFactory.shared` keying). Owned by P02.
- **Legibility**: extracted color may clash with white text → enforce WCAG
  contrast, fall back to scrim/desaturation. Owned by P02, consumed everywhere.
- **Reduce Motion / Dynamic Type / VoiceOver**: every animated/colored surface
  must degrade gracefully. Enforced via P01 modifiers, audited in P09.
- **File-size rule** (<200 LOC, kebab-case): split where touching large views.
