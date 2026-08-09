# Phase 01 — Foundation: Color + Motion Tokens

## Context Links
- Overview: [plan.md](plan.md)
- Existing tokens: `MusicApp/DesignSystem/DesignToken.swift`, `AppColor.swift`, `AppFont.swift`
- Monotone driver: `MusicApp/Commons/Extension/UIColor + Ext.swift:87` (`Color.backgroundColor = #1C1C1E`)
- Button styles: `MusicApp/Commons/Button + Style.swift`
- Skills: `/ck:design-system-architect`, `/ck:ios-swiftui-modern`, `/ck:ios-hig-accessibility`

## Overview
- **Priority:** P1 (blocks all other phases)
- **Status:** pending
- **Description:** Extend the design system with (a) a COLOR token layer (semantic + dynamic-from-artwork support types), (b) MOTION presets (springs/durations + haptic helpers honoring Reduce Motion), and (c) reusable view modifiers (press-scale, entrance, dynamic-background). **No screen is changed in this phase** — pure additive infrastructure so it ships safely and reviews in isolation.

## Key Insights
- Verified: `AppColor.swift` has only white/grey semantics + one **unused** coral `accentPrimary #FF6B6B`. No dynamic color support, no gradient types.
- Verified: `DesignToken.Animation` has only 3 raw `Double` durations — no `SwiftUI.Animation` presets, no spring tokens.
- Verified: **zero** `.sensoryFeedback` / `UIImpactFeedbackGenerator` / Reduce-Motion / Dynamic-Type usage in the codebase. All net-new.
- Verified: `Color.backgroundColor` (`#1C1C1E`) is referenced in **29 files** — this phase must NOT touch those call sites (that is P03–P08). Keep `backgroundColor` intact; add new tokens alongside.
- `AppFont` uses fixed `.system(size:)` (no `relativeTo:` Dynamic Type scaling) — note for P09; do not change signatures here to avoid churn across all callers.

## Requirements
**Functional**
- A semantic color model with: surface/background, content (primary/secondary/muted text), accent, and an **app-wide "dynamic theme"** carrier that can be overridden per-song.
- Motion presets as `SwiftUI.Animation` values (named springs + curves) reusable by name.
- Haptic helper: thin wrapper that prefers iOS 17 `.sensoryFeedback` and is a no-op under Reduce Motion's audio/haptic intent where appropriate.
- View modifiers: `.pressScale()` (button press scale+haptic), `.entrance(index:)` (staggered list/card appear), `.dynamicBackground(theme:)` (gradient + scrim wrapper).

**Non-functional**
- iOS 17.6 / Swift 5.0 compatible. No new pods.
- Each new file < 200 LOC, kebab-case-described purpose, `.swift` PascalCase types.
- Reduce Motion: motion presets expose a `reduced` variant; modifiers read `@Environment(\.accessibilityReduceMotion)` and collapse to fade/none.

## Architecture
**New token surface (data flow):**
```
AppColorTheme (value type: surface, accent, onColor[s], gradientStops)
   ├── .default  → derived from current static palette (grey/white) = safe fallback
   └── .dynamic(from: ExtractedPalette) ← produced in P02, injected via EnvironmentKey
EnvironmentKey: \.appColorTheme  (default = .default)
   → read by .dynamicBackground() modifier and accent-consuming views
MotionToken (SwiftUI.Animation presets) + Haptics (sensoryFeedback wrapper)
ViewModifiers: PressScale, Entrance, DynamicBackground
```
- The **theme is carried via Environment**, not global mutable state — so per-song override in P03 is a localized `.environment(\.appColorTheme, theme)` on the player subtree, and the rest of the app uses `.default` until later phases opt in. This avoids leaking one song's color into unrelated screens.
- `AppColorTheme` is a plain `struct` (`Equatable`) so SwiftUI can diff/animate `foregroundColor`/background transitions.

## Related Code Files
**Create**
- `MusicApp/DesignSystem/AppColorTheme.swift` — `AppColorTheme` struct + `.default`; `onColor` (text color guaranteed to contrast its surface).
- `MusicApp/DesignSystem/AppColorThemeEnvironment.swift` — `EnvironmentKey` + `\.appColorTheme` accessor.
- `MusicApp/DesignSystem/MotionToken.swift` — named `SwiftUI.Animation` presets (springStandard, springBouncy, springSnappy, fade, plus `.reduced` fallbacks).
- `MusicApp/DesignSystem/Haptics.swift` — `enum Haptics` + `.sensoryFeedback` View helper wrapper; trigger types (impactLight/selection/success).
- `MusicApp/DesignSystem/Modifiers/PressScaleModifier.swift` — `ButtonStyle` + `.pressScale()` (scale 0.96 + light haptic).
- `MusicApp/DesignSystem/Modifiers/EntranceModifier.swift` — `.entrance(index:)` staggered opacity+offset, Reduce-Motion → opacity-only.
- `MusicApp/DesignSystem/Modifiers/DynamicBackgroundModifier.swift` — `.dynamicBackground()` reads `\.appColorTheme`, renders gradient + legibility scrim.

**Modify**
- `MusicApp/DesignSystem/AppColor.swift` — ADD (do not remove existing): semantic aliases that the theme falls back to; keep current names for compatibility.
- `MusicApp/DesignSystem/DesignToken.swift` — ADD a `Motion` nested enum referencing `MotionToken` (or leave Animation durations; add spring tokens). Keep existing values.

**Delete** — none.

## Implementation Steps
1. Add `AppColorTheme` struct: `surface: Color`, `accent: Color`, `onSurface: Color` (contrast-guaranteed text), `gradientStops: [Color]`. Provide static `.default` mapping to current grey/white palette (`backgroundColor`, `.white`, accent = existing cyan/coral — pick coral `#FF6B6B` per existing token, confirm with user if ambiguous).
2. Add `\.appColorTheme` EnvironmentKey defaulting to `.default`.
3. Add `MotionToken` presets as `static let` `Animation` values; include `func resolved(reduceMotion:)` returning `.none`/fade when reduced.
4. Add `Haptics` helper + a `View.haptic(_:trigger:)` convenience using `.sensoryFeedback(_, trigger:)`.
5. Add `PressScaleModifier` (`ButtonStyle`) — scale + light haptic on press; expose `.buttonStyle(.pressScale)` or `.pressScale()`.
6. Add `EntranceModifier` — `.entrance(index:)` staggered appear with `MotionToken`; Reduce-Motion collapses offset to 0.
7. Add `DynamicBackgroundModifier` — `.dynamicBackground()` builds `LinearGradient` from `theme.gradientStops` + bottom scrim ensuring text contrast; falls back to `theme.surface` flat color if `gradientStops.count < 2`.
8. Wire `DesignToken.Motion` aliases (optional thin indirection) so callers can use either entry point consistently.
9. Compile: `xcodebuild -workspace MusicApp.xcworkspace -scheme MusicApp -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build` (or build in Xcode). Fix any errors before handing to user.
10. Provide a tiny `#Preview` in each modifier file demonstrating it on a sample card (preview-only, not wired into app).

## Todo List
- [ ] `AppColorTheme.swift` + `.default`
- [ ] `AppColorThemeEnvironment.swift` (`\.appColorTheme`)
- [ ] `MotionToken.swift` presets + reduced variants
- [ ] `Haptics.swift` (`.sensoryFeedback` wrapper)
- [ ] `PressScaleModifier.swift`
- [ ] `EntranceModifier.swift`
- [ ] `DynamicBackgroundModifier.swift`
- [ ] Additive edits to `AppColor.swift` + `DesignToken.swift`
- [ ] Per-file `#Preview` smoke
- [ ] Compiles clean

## Success Criteria
- Project builds with new files; **no existing screen changed visually** (regression-safe).
- `AppColorTheme.default` renders identical to today's grey/white look when applied.
- Each modifier demonstrable in its `#Preview`.
- `accessibilityReduceMotion` env collapses entrance/press motion (verify in preview with the env override).
- All new files < 200 LOC.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Token API churn forces rework in P03+ | Med | Med | Lock the `AppColorTheme` shape + Environment approach here; P02/P03 only consume, never reshape |
| Color tokens collide with existing `Color` extension names | Low | Med | Namespace new semantics under `AppColorTheme`/`AppColor`, do not redefine `backgroundColor` |
| Reduce-Motion API misused | Low | Low | Centralize via `MotionToken.resolved` + modifier env reads; single source |

## Security / Accessibility Considerations
- No data/security surface (pure UI tokens).
- Accessibility is first-class here: `onSurface` text color guaranteed to contrast `surface`; motion presets honor Reduce Motion; modifiers must not block VoiceOver focus (purely visual). Dynamic Type gap in `AppFont` is recorded for P09.

## Next Steps
- Unblocks **P02** (extractor produces `ExtractedPalette` → `AppColorTheme.dynamic`).
- Unblocks all later phases (modifiers + tokens consumed there).
