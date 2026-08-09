# Phase 04 — Shared Components + Dedupe

## Context Links
- Overview: [plan.md](plan.md) · Depends on: [phase-01](phase-01-foundation-color-motion-tokens.md), [phase-03](phase-03-now-playing-showcase.md) approval
- Tab bar (REAL): inline `customTabBar` in `MusicApp/Presentation/Feature/Main/MainTabView.swift:107` + `tabButton:120` (hardcoded `.white`/`.gray`, `.font(.system(size:24/10))`, `Color.backgroundColor` bg `:115`)
- Tab bar (ORPHANED — verified zero instantiations): `MusicApp/Commons/Tabars/CustomTabBar.swift` (311 LOC), `MusicApp/Commons/CustomViews/CustomTabar.swift` (9 LOC)
- SongItemView (REAL): `MusicApp/Commons/CustomViews/SongItemView.swift` (69 LOC) — used by `HomeView.swift:128`, `PlaylistDetailView.swift:148`
- SongItemView (ORPHANED — verified only self-`#Preview` ref): `MusicApp/Commons/SongItemView.swift` (48 LOC)
- Other shared: `MusicApp/Commons/CustomViews/CustomNavigationBar.swift`, `MusicApp/Commons/CustomViews/CustomSliderView.swift`, `MusicApp/Commons/Button + Style.swift`, `MusicApp/Commons/Modifiers.swift`, `MusicApp/Commons/CustomViews/PlayListItemView.swift` (`Libary/CustomView/`)
- Skills: `/ck:design-system-architect`, `/ck:ios-swiftui-modern`, `/ck:ios-hig-accessibility`

## Overview
- **Priority:** P1 (shared components touch every screen — restyle once, propagate everywhere)
- **Status:** pending
- **Description:** Remove dead duplicate components, then restyle the live shared components with new tokens + press feedback/haptics. This is the highest-leverage phase: the tab bar and SongItemView appear on most screens.

## Key Insights
- **Verified dead code** (safe to delete — no instantiations): `Commons/Tabars/CustomTabBar.swift`, `Commons/CustomViews/CustomTabar.swift`, `Commons/SongItemView.swift`. Deleting de-risks future confusion ("which tab bar is real?") and shrinks the surface. Confirm with `gh`/grep one more time at execution, then delete.
- The **real** tab bar is inline in `MainTabView` — restyle there, not in the orphaned files.
- `AnimationPressStyle` in `Button + Style.swift` literally sets background to `Color.red` on press (placeholder) — replace with the P01 `.pressScale` approach.
- SongItemView currently uses `Color.cyan` for "current song" highlight — replace with theme-aware accent (but SongItem lists live on `.default`-theme screens, so accent = static accent token unless a list opts into per-row artwork color, which we DEFER — YAGNI).

## Requirements
**Functional**
- Delete the 3 orphaned files; confirm build still green.
- Restyle inline tab bar: tokens for color/font/spacing; active = accent token (not plain white); selection haptic on tab change; subtle scale/indicator on active tab.
- Restyle live `SongItemView`: token colors/fonts, `.pressScale()` + light haptic on tap, current-song highlight uses accent token + optional now-playing equalizer-bars affordance (keep simple).
- Restyle `CustomNavigationBar`, `CustomSliderView` (themed track/thumb), `PlayListItemView`.
- Replace `AnimationPressStyle` red-flash with real press style; keep `NoAnimationButtonStyle` (still used).

**Non-functional**
- `MainTabView` is 173 LOC; extracting the restyled tab bar into its own file keeps it < 200 and self-documents.
- Each new/edited file < 200 LOC, kebab-described.

## Architecture
```
Delete orphans → grep-confirm no refs → build
Inline tab bar → extract to MainTabBarView.swift (consumes tokens + haptics)
  active tab: AppColor accent + scale/indicator; selection haptic on change
SongItemView (CustomViews) → tokens + .pressScale + accent highlight for current song
CustomSliderView → themed track (progressTrack) + fill (accent) + thumb
Button+Style → AnimationPressStyle reimplemented atop P01 PressScale
```
- Tab bar stays on `.default` theme (does not adopt per-song color — confirmed scope decision: dynamic color is the player's hero; spreading it to chrome risks visual noise + legibility churn. Revisit only if user asks.)

## Related Code Files
**Delete**
- `MusicApp/Commons/Tabars/CustomTabBar.swift` (orphan, 311 LOC)
- `MusicApp/Commons/CustomViews/CustomTabar.swift` (orphan, 9 LOC)
- `MusicApp/Commons/SongItemView.swift` (orphan, 48 LOC)

**Create**
- `MusicApp/Presentation/Feature/Main/MainTabBarView.swift` — extracted, restyled tab bar (tokens + active accent + selection haptic + active scale/indicator).

**Modify**
- `MainTabView.swift` — replace inline `customTabBar`/`tabButton`/`iconName`/`tabTitle` with `MainTabBarView`; remove now-dead helpers; selection haptic.
- `MusicApp/Commons/CustomViews/SongItemView.swift` — tokens, fonts, press+haptic, accent highlight.
- `MusicApp/Commons/CustomViews/CustomNavigationBar.swift` — tokens + press on back/actions.
- `MusicApp/Commons/CustomViews/CustomSliderView.swift` — themed track/fill/thumb (accent), drag haptic optional.
- `MusicApp/Presentation/Feature/Libary/CustomView/PlayListItemView.swift` — tokens + press+haptic.
- `MusicApp/Commons/Button + Style.swift` — reimplement `AnimationPressStyle` via P01 press-scale; remove red flash.

## Implementation Steps
1. Re-grep each orphan to reconfirm zero references (`grep -rn "CustomTabBar(\|CustomTabar(\|SongItemView(" MusicApp`); remove orphan files from Xcode project + disk. Build green.
2. Create `MainTabBarView` consuming `MainTab.allCases`, `AppFont.tabLabel()`, accent token for active, `.gray`→`tabInactive` token; add active-tab scale (`MotionToken`) + thin indicator.
3. Add `.sensoryFeedback(.selection, trigger: currentTab)` (or via Haptics helper) on tab change.
4. Replace inline tab bar in `MainTabView` with `MainTabBarView(currentTab: $currentTab)`; delete dead helper funcs; verify safe-area padding math preserved.
5. Restyle `SongItemView`: swap inline colors→tokens, fonts→`AppFont`, wrap tap in `.pressScale` + light haptic, current-song highlight → accent token.
6. Restyle `CustomNavigationBar`, `CustomSliderView` (track=`progressTrack`, fill/thumb=accent), `PlayListItemView`.
7. Fix `Button + Style.swift` `AnimationPressStyle`.
8. Build; visually verify tab bar, a song row tap, slider drag, nav bar across Home/Library.

## Todo List
- [ ] Re-grep + delete 3 orphan files; build green
- [ ] `MainTabBarView.swift` (restyled, accent active, haptic)
- [ ] `MainTabView` swapped to `MainTabBarView`, dead helpers removed
- [ ] `SongItemView` restyled + press/haptic + accent highlight
- [ ] `CustomNavigationBar` restyled
- [ ] `CustomSliderView` themed
- [ ] `PlayListItemView` restyled
- [ ] `AnimationPressStyle` fixed
- [ ] Compiles + visual check

## Success Criteria
- 3 orphan files gone; project builds and runs identically functionally.
- Tab bar: active tab in accent color with subtle motion; switching taps gives haptic.
- Song rows + playlist rows: press feedback + haptic; current song clearly highlighted via accent.
- Slider track/fill/thumb use tokens; nav bar consistent.
- All touched files < 200 LOC; no remaining `Color.red` press flash.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Deleting "orphan" that is actually referenced via storyboard/string | Low | High | Re-grep at execution incl. non-`(` refs; build after each delete; revert if link error |
| Tab-bar safe-area math breaks on extraction | Med | High | Preserve exact `bottomSafeArea` padding/frame logic in `MainTabBarView`; test on notch + non-notch |
| Over-animating chrome (distracting) | Med | Med | Keep tab/active motion subtle; honor Reduce Motion; user can veto at review |
| SongItemView used in more places than grepped | Low | Med | Full grep (6 refs counted) before edit; tokens are backward-compatible |

## Security / Accessibility Considerations
- VoiceOver: tab buttons keep labels/traits; active state must set `.accessibilityAddTraits(.isSelected)`. Slider keeps `.accessibilityValue`.
- Reduce Motion: active-tab scale/indicator collapses to color-only change.
- Contrast: accent-on-tabbar-background must pass WCAG (tab bar stays on dark surface — verify accent token contrast in P09).

## Next Steps
- Unblocks all screen sweeps (P05–P08) which lean on restyled `SongItemView`, tab bar, slider, nav bar.
