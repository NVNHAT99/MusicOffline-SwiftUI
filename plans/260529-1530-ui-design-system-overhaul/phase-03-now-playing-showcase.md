# Phase 03 — Now Playing Showcase (Full + Mini)

## Context Links
- Overview: [plan.md](plan.md) · Depends on: [phase-01](phase-01-foundation-color-motion-tokens.md), [phase-02](phase-02-artwork-color-extraction-engine.md)
- Coordinator: `MusicApp/Presentation/Feature/NowPlayingScreen/NowPlayingView.swift` (owns `uiImage`, `loadArtwork():52`, mini↔full swap, spring at `:44`)
- Full player: `MusicApp/Presentation/Feature/NowPlayingScreen/Views/NowPlayingFullPlayerView.swift` (296 LOC — over limit; takes `uiImage: UIImage?`, artwork at `:166`, controls `:261+`, currently `.background(Color.backgroundColor)` set at `NowPlayingView.swift:40`)
- Mini player: `MusicApp/Presentation/Feature/NowPlayingScreen/Views/NowPlayingMiniPlayerView.swift` (72 LOC)
- Host: `MusicApp/Presentation/Feature/Main/MainTabView.swift` (owns `nowPlayingViewModel`, spring `:65`)
- Skills: `/ck:ios-swiftui-modern`, `/ck:ios-hig-accessibility`, `/ck:design-system-architect`

## Overview
- **Priority:** P1 (visual-language approval gate)
- **Status:** pending
- **Description:** Apply dynamic artwork color + tasteful motion to the flagship screen FIRST, so the user approves the whole visual language before it spreads app-wide. Full player background becomes the per-song gradient; mini player gets a tinted accent; controls get press+haptic feedback; mini↔full transition refined.

## Key Insights
- Verified: `NowPlayingView` is the single owner of `uiImage` — extraction wires in at `loadArtwork()` with **one extra await**, no second decode.
- Verified: the full player's flat background is applied at `NowPlayingView.swift:40` (`.background(Color.backgroundColor.ignoresSafeArea())`) — replace THIS one line's source with `.dynamicBackground()` reading the injected theme. Single, low-risk swap.
- Verified: mini↔full already uses springs (`NowPlayingView:44`, `MainTabView:65`); refine to `MotionToken` presets, optionally `matchedGeometryEffect` on artwork for a hero transition (iOS 17 safe).
- `NowPlayingFullPlayerView` is **296 LOC > 200** — split during this phase (artwork, controls, progress, lyrics-menu sub-views) per file-size rule.
- Theme injection is **scoped** to the player subtree via `.environment(\.appColorTheme, theme)` — does NOT leak to tabs/other screens (they stay `.default` until their own phase).

## Requirements
**Functional**
- Per-song: extract palette in `loadArtwork()`, derive `AppColorTheme.dynamic`, inject into the player subtree.
- Full player background = animated gradient from theme (cross-fades on song change).
- Mini player: accent tint (play button / progress) from theme; legible text guaranteed.
- Controls (play/pause, next/prev, shuffle, repeat): `.pressScale()` + appropriate haptic (selection for toggles, light impact for transport).
- Mini↔full transition: `MotionToken.springStandard`; consider `matchedGeometryEffect` hero on artwork.

**Non-functional**
- Color recompute only on song change (cache via P02). Gradient animates with `MotionToken`, honors Reduce Motion (cross-fade → instant).
- Split files to < 200 LOC each.

## Architecture
**Data flow (additions in bold):**
```
NowPlayingView.loadArtwork() → uiImage
  **→ palette = await PaletteProvider.shared.palette(forKey: urlStr, image: uiImage)**
  **→ theme = AppColorTheme.dynamic(from: palette)  (stored in @State)**
body:
  full/mini subtree **.environment(\.appColorTheme, theme)**
  full player background: was `.background(Color.backgroundColor)` → **`.dynamicBackground()`**
  text/accents in full+mini read **\.appColorTheme** (onSurface, accent)
  transition: **MotionToken.springStandard** + reduceMotion fallback
```
- `@State private var theme: AppColorTheme = .default` in `NowPlayingView`; updated alongside `uiImage`. On nil/fallback artwork → `.default` (preserves today's look gracefully).

## Related Code Files
**Modify**
- `NowPlayingView.swift` — extend `loadArtwork()` to compute palette+theme; add `@State theme`; inject `.environment(\.appColorTheme,…)`; replace `:40` background with `.dynamicBackground()`; swap spring → `MotionToken`.
- `NowPlayingFullPlayerView.swift` — consume `\.appColorTheme` for text/accent; `.pressScale()`+haptics on transport buttons; **split** (see Create).
- `NowPlayingMiniPlayerView.swift` — accent tint from theme; press+haptic on play/expand; legible text.
- `MainTabView.swift` — refine `:65` player spring → `MotionToken` (only the player animation; tab-bar styling deferred to P04).

**Create (from splitting the 296-LOC full player)**
- `MusicApp/Presentation/Feature/NowPlayingScreen/Views/FullPlayerArtworkView.swift` — artwork + (optional) matchedGeometry.
- `MusicApp/Presentation/Feature/NowPlayingScreen/Views/FullPlayerControlsView.swift` — transport controls + press/haptic.
- `MusicApp/Presentation/Feature/NowPlayingScreen/Views/FullPlayerProgressView.swift` — scrubber/time (themed track).

**Delete** — none.

## Implementation Steps
1. In `NowPlayingView`: add `@State private var theme: AppColorTheme = .default`. In `loadArtwork()`, after `uiImage` set, `await PaletteProvider.shared.palette(...)` → `theme = .dynamic(from:)`; on fallback path keep `.default`.
2. Inject `.environment(\.appColorTheme, theme)` on both mini and full branches.
3. Replace full-player `.background(Color.backgroundColor.ignoresSafeArea())` (`:40`) with `.dynamicBackground().ignoresSafeArea()`.
4. Animate theme change: wrap theme assignment / background with `.animation(MotionToken.springStandard.resolved(reduceMotion:), value: theme)`.
5. Split `NowPlayingFullPlayerView` into artwork/controls/progress subviews (< 200 LOC each); pass theme via Environment, not props.
6. In controls subview: `.buttonStyle(.pressScale)` + `.sensoryFeedback` (selection for shuffle/repeat toggles, impactLight for play/next/prev).
7. Mini player: tint play button + progress with `theme.accent`; text `theme.onSurface`; press+haptic on play & expand-tap.
8. Refine `MainTabView:65` to `MotionToken.springStandard`. (Optional) `matchedGeometryEffect(id: "artwork", …)` between mini and full artwork for hero transition — gate behind Reduce Motion (skip if reduced).
9. Build + run on device/simulator; verify gradient changes per song, text legible on light artwork, controls feel responsive.
10. **APPROVAL GATE:** present to user. Confirm: gradient richness (average vs histogram — see P02 risk), accent saturation, haptic intensity, transition feel. Lock decisions before P04.

## Todo List
- [ ] `loadArtwork()` computes palette+theme; `@State theme`
- [ ] Environment injection on player subtree
- [ ] Full-player background → `.dynamicBackground()`
- [ ] Theme cross-fade animation (Reduce-Motion aware)
- [ ] Split full player into artwork/controls/progress (<200 LOC each)
- [ ] Press+haptic on full + mini controls
- [ ] Mini player accent tint + legible text
- [ ] `MotionToken` spring on mini↔full (+ optional matchedGeometry hero)
- [ ] Device verification (per-song color, legibility, perf)
- [ ] User approval of visual language

## Success Criteria
- Background gradient visibly changes per song; transitions smoothly on track change.
- White/onSurface text remains legible on bright AND dark artwork (eyeball + P02 contrast guarantee).
- Controls give press scale + haptic; mini↔full feels springy, not janky.
- Reduce Motion ON → no scale/hero; cross-fade becomes instant; still fully usable.
- No scroll/transition frame drops attributable to color extraction (cached).
- Full-player files all < 200 LOC.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Gradient too dull/washed (single-average) | Med | Med | Decision at approval gate; upgrade P02 to histogram only if user dislikes |
| matchedGeometry causes layout jump | Med | Med | Optional; gate behind Reduce-Motion; fall back to existing move+opacity transition if glitchy |
| Splitting 296-LOC view breaks layout | Med | High | Split by visual region, keep identical modifiers; compile + visual diff each step |
| Theme leaks to non-player UI | Low | High | Inject via scoped `.environment` on player subtree only — verified single injection point |
| Extra await in loadArtwork delays first paint | Low | Med | Show artwork immediately; theme applies when ready; `.default` until then |

## Security / Accessibility Considerations
- VoiceOver: control labels unchanged; ensure press-scale/haptic do not alter accessibility traits. Gradient is decorative (`.accessibilityHidden(true)` on background layer).
- Reduce Motion honored via `MotionToken.resolved`. Dynamic Type: text uses `AppFont` (fixed sizes — full Dynamic-Type pass deferred to P09, note any clipping seen here).
- Increase Contrast: rely on P02 `ContrastGuard`; spot-check here.

## Next Steps
- On approval, unblocks **P04** (shared components) and the screen sweeps P05–P08.
- Record approval-gate decisions (algorithm, accent saturation, haptic level) into `plan.md` notes so later phases stay consistent.
