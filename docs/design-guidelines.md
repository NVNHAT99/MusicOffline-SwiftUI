# Design Guidelines

The app's visual language: a dynamic, artwork-driven color system layered on a
dark base, with tasteful motion (press feedback, haptics, entrance animations).
All UI should consume the design-system tokens — avoid inline colors/fonts.

## Color

### Tokens (`MusicApp/DesignSystem/AppColor.swift`, `Commons/Extension/UIColor + Ext.swift`)
| Token | Use |
|-------|-----|
| `Color.backgroundColor` (#1C1C1E) | Default screen surface (dark) |
| `Color.accentPrimary` (#FF6B6B coral) | Brand accent: active controls, FABs, highlights, current item |
| `Color.primaryText` (white) | Primary text/icons |
| `Color.secondaryText` (white 70%) | Secondary/supporting text |
| `Color.mutedText` (white 40%) | De-emphasized text, placeholders |
| `Color.separator` (white 12%) | Divider lines |

**Gotcha:** `.foregroundStyle(.tokenName)` does NOT compile (it infers `ShapeStyle`).
Use `.foregroundStyle(Color.tokenName)`. `.foregroundColor(.tokenName)` is fine.
`Color.separator` collides with SwiftUI's built-in `.separator` — always qualify with `Color.`.

### Dynamic per-song theme (`MusicApp/DesignSystem/Color/`, `AppColorTheme.swift`)
The Now Playing screen derives a per-song color theme from album artwork:
- `ArtworkColorExtractor` — downscales the artwork (50×50) and runs CoreImage
  `CIAreaAverage` to get a dominant color (saturation-boosted for vibrancy).
- `PaletteProvider.shared` — async, off-main-thread, **cached per song URL** (NSCache,
  count limit 60). Never recompute on redraw.
- `ContrastGuard` — WCAG luminance math. Guarantees legible text (pure black/white,
  whichever wins AA ≥ 4.5:1) and a scrim that grows with surface lightness.
- `AppColorTheme.dynamic(from:)` → gradient (dominant → darker → near-black), accent,
  contrast-checked `onSurface`.
- Injected via `.appColorTheme(theme)` Environment on the **player subtree only** —
  does not leak to other screens (they stay `.default`).
- `.dynamicBackground()` renders the gradient + legibility scrim.

The default accent for any non-themed surface is coral `#FF6B6B`.

## Typography (`AppFont.swift`)
Use `AppFont.*` (largeTitle/title/headline/body/callout/caption/sectionHeader,
plus player-specific). All scale with **Dynamic Type** (`.system(.textStyle)` relative
sizing), `design: .rounded` for the friendly look. Do not use inline `.system(size:N)`
for text (icon sizing via `DesignToken.IconSize` is fine).

## Motion (`MotionToken.swift`, `Haptics.swift`, `DesignSystem/Modifiers/`)
| Helper | Use |
|--------|-----|
| `MotionToken.springStandard/springSnappy/springBouncy` | Named spring presets |
| `MotionToken.colorShift` | Cross-fade when the per-song theme changes |
| `.buttonStyle(.pressScale)` | Scale-down + light haptic on press (honors Reduce Motion) |
| `.entrance(index:)` | Staggered fade+slide for list/card rows (capped at 12, fade-only under Reduce Motion) |
| `.dynamicBackground()` | Paints the active theme gradient + scrim |
| `.haptic(_:trigger:)` / `.sensoryFeedback(...)` | iOS 17 declarative haptics |

**Haptic discipline:** reserve haptics for primary actions, state results
(success/error), tab changes, and detents/grab-release — never on every continuous
gesture tick or every row.

## Accessibility
- **Contrast:** dynamic colors enforce WCAG AA via `ContrastGuard` (unit-tested in
  `ArtworkColorThemeTests`). Decorative gradients are `.accessibilityHidden(true)`.
- **Reduce Motion:** `MotionToken.resolved(_:reduceMotion:)` + modifiers read
  `\.accessibilityReduceMotion`; motion collapses to fade/instant.
- **Dynamic Type:** `AppFont` scales with the user's text-size setting.
- Color is never the sole information carrier (controls keep SF Symbols + labels).

## Adding new UI
1. Use `AppFont` + color tokens; never inline hex or `.system(size:)` for text.
2. Primary buttons → `.buttonStyle(.pressScale)`. Lists → `.entrance(index:)`.
3. New `.swift` files must be registered in `MusicApp.xcodeproj/project.pbxproj`
   (classic groups — 4 spots: PBXBuildFile, PBXFileReference, group child, Sources phase).
4. Keep files < 200 LOC; validate with a real `xcodebuild` (SourceKit cross-file
   diagnostics are unreliable).
