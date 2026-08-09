# Phase 02 — Artwork Color-Extraction Engine

## Context Links
- Overview: [plan.md](plan.md) · Depends on: [phase-01](phase-01-foundation-color-motion-tokens.md)
- Artwork load point: `MusicApp/Presentation/Feature/NowPlayingScreen/NowPlayingView.swift:52` (`loadArtwork()`), produces `uiImage: UIImage?`
- Process-wide cache pattern: `MusicApp/Core/ImageCache/ImageCacheFactory.swift` (`.shared` singleton, keyed by URL string)
- Image entity: `MusicApp/Domain/Entities/AudioImage.swift` (`imageData: Data`)
- Skills: `/ck:ios-swiftui-modern`, `/ck:ios-hig-accessibility`

## Overview
- **Priority:** P1 (blocks P03+)
- **Status:** pending
- **Description:** Build the artwork → dominant-color utility from scratch (none exists — verified: no `averageColor`/`CIAreaAverage`/`CIFilter`). Output an `ExtractedPalette` and map it to `AppColorTheme.dynamic`. Must be **off main thread**, **cached per song**, and **legibility-guaranteed** (extracted color clashing with white text is the core risk).

## Key Insights
- Verified: artwork enters the UI as `UIImage` only inside `NowPlayingView.loadArtwork()`. That is the single producer — extraction should hang off the same async load to avoid a second decode.
- Verified: `ImageCacheFactory.shared` is a process-wide singleton keyed by URL string. Reuse the **same key** for a parallel palette cache so palette lifetime tracks artwork lifetime.
- Extraction must not run on `body`/redraw. SwiftUI re-evaluates `body` frequently; computing CoreImage there would tank scroll/transition perf.
- Legibility: a bright/light dominant color makes white text invisible. Must compute a contrast-safe `onSurface` and/or darken+scrim the gradient. WCAG AA (4.5:1 normal text) is the target.

## Requirements
**Functional**
- `ArtworkColorExtractor`: `func palette(from: UIImage) async -> ExtractedPalette`.
- `ExtractedPalette`: dominant color + secondary (for gradient stops) + a boolean/luminance so the theme can pick light vs dark text.
- A **per-song palette cache** keyed identically to the image cache (URL string) — extract once per song, reuse on revisit.
- Mapping: `AppColorTheme.dynamic(from: ExtractedPalette)` → produces gradientStops (dominant→darker), accent (saturated dominant), `onSurface` (contrast-checked white or near-black).
- Contrast guarantee: a `ContrastGuard` that, given surface luminance, returns legible text color AND, if the surface is too light, darkens gradient stops / adds scrim opacity.

**Non-functional**
- Extraction on a background queue/`Task.detached`; downscale image first (e.g. ~50×50) before averaging — cheap + stable.
- Cache hit returns synchronously-ish (await but no recompute). Bounded memory (NSCache or reuse cache infra).
- iOS 17.6 / Swift 5.0. CoreImage / `UIGraphicsImageRenderer` only — no new pods.

## Architecture
**Data flow:**
```
loadArtwork() [P03 edit] → UIImage
   → PaletteProvider.palette(forKey: urlString, image: uiImage) async
        ├── cache hit  → return ExtractedPalette
        └── cache miss → Task.detached:
              downscale 50×50 → ArtworkColorExtractor (CIAreaAverage or pixel-bucket)
              → ContrastGuard (luminance → onSurface + scrim) → ExtractedPalette
              → store in palette NSCache (key = urlString)
   → AppColorTheme.dynamic(from: palette)
   → inject via .environment(\.appColorTheme, theme) on player subtree [P03]
```
**Algorithm choice (KISS):** start with **CIAreaAverage** on a downscaled image for the dominant tone, plus a darker derived stop for the gradient. This is the simplest robust approach and avoids a k-means dependency (YAGNI). If single-average looks washed out in P03 review, escalate to a small fixed-bucket histogram — but only if the user finds the average unsatisfying. Note this as a P03 review checkpoint.

## Related Code Files
**Create**
- `MusicApp/DesignSystem/Color/ArtworkColorExtractor.swift` — downscale + CIAreaAverage → dominant + secondary `UIColor`.
- `MusicApp/DesignSystem/Color/ExtractedPalette.swift` — value type (dominant, secondary, luminance/isLight).
- `MusicApp/DesignSystem/Color/ContrastGuard.swift` — luminance math (WCAG relative luminance), legible text color, scrim opacity recommendation.
- `MusicApp/DesignSystem/Color/PaletteProvider.swift` — async cache facade; `.shared` keyed by URL string (mirrors `ImageCacheFactory`).
- `MusicApp/DesignSystem/Color/AppColorTheme+Dynamic.swift` — `AppColorTheme.dynamic(from: ExtractedPalette)` mapping (extends P01 type).

**Modify** — none in this phase (engine is standalone + unit-testable; P03 wires it in). Keeps this phase shippable without visible change.

**Delete** — none.

## Implementation Steps
1. `ExtractedPalette`: store `dominant: Color`, `secondary: Color`, `isLight: Bool` (+ raw luminance). `Equatable`.
2. `ArtworkColorExtractor.palette(from:)`: downscale to ~50×50 via `UIGraphicsImageRenderer`, run `CIAreaAverage` (or average pixel buffer) → dominant; derive secondary by darkening dominant ~25% for a gradient end-stop.
3. `ContrastGuard`: compute WCAG relative luminance of dominant; `legibleTextColor(on:)` → white if dark surface else near-black; `scrimOpacity(for:)` → higher when surface light.
4. `PaletteProvider.shared`: NSCache<NSString, …> keyed by URL string. `func palette(forKey:image:) async -> ExtractedPalette` — return cached or run `Task.detached` extraction then cache.
5. `AppColorTheme.dynamic(from:)`: build `gradientStops = [dominant, secondary]` (darkened to keep text legible), `accent = saturated dominant`, `onSurface = ContrastGuard.legibleTextColor`, plus scrim factor stored for `DynamicBackgroundModifier`.
6. Add unit-test target hooks (logic is pure): test `ContrastGuard` luminance + legible-color selection on known colors (white, black, #FF6B6B, mid-grey). Test `dynamic(from:)` always yields onSurface contrast ≥ 4.5:1 vs surface.
7. Compile + run the contrast unit tests. Do not wire into any view yet.

## Todo List
- [ ] `ExtractedPalette.swift`
- [ ] `ArtworkColorExtractor.swift` (downscale + CIAreaAverage)
- [ ] `ContrastGuard.swift` (WCAG luminance + legible text + scrim)
- [ ] `PaletteProvider.swift` (async per-URL cache)
- [ ] `AppColorTheme+Dynamic.swift` mapping
- [ ] Unit tests: contrast guarantee + legible color
- [ ] Compiles clean; tests green

## Success Criteria
- For any artwork, `AppColorTheme.dynamic` produces `onSurface` text with WCAG contrast ≥ 4.5:1 against the rendered surface (asserted by unit test).
- Extraction runs off main thread; a second request for the same URL key does **not** recompute (cache hit).
- Downscaled extraction completes fast (target < ~10ms for a 50×50 average; measure informally).
- No view changed → no UI regression.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Recompute on every redraw** (perf) | High if naive | High | Cache per URL key; extraction lives in `PaletteProvider`, never in `body`; tie to `loadArtwork` (one decode per song) |
| **Light artwork → invisible white text** (legibility) | High | High | `ContrastGuard` enforces WCAG; gradient stops darkened + scrim; unit-tested |
| Single average too washed-out / dull | Med | Med | Acceptable v1 (KISS); flag histogram upgrade as a P03 review decision, do not pre-build |
| Cache unbounded memory growth | Low | Med | NSCache with count/cost limits mirroring `ImageCacheManager` |
| Off-thread `UIImage` access thread-safety | Med | Med | Downscale to a detached, immutable bitmap; pass `Data`/`CGImage` into detached task, not shared mutable `UIImage` |

## Security / Accessibility Considerations
- No new data leaves the device; artwork already local.
- Accessibility: contrast guarantee is the headline accessibility feature; verify against Increase Contrast setting in P09. Color is decorative — never the sole carrier of information (controls keep their SF Symbol + label).

## Next Steps
- Unblocks **P03** (player consumes `PaletteProvider` + `AppColorTheme.dynamic`).
- Engine reusable later for SongItemView accent / cards if desired (P04+), but defer until proven on player.
