# Phase 05 — Home + Library + PlaylistDetail

## Context Links
- Overview: [plan.md](plan.md) · Depends on: [phase-01](phase-01-foundation-color-motion-tokens.md), [phase-04](phase-04-shared-components-and-dedupe.md)
- `MusicApp/Presentation/Feature/Home/HomeView.swift` (170 LOC; hardcoded `.font(.system(size:24,…))` at `:31` & `:41`; uses `SongItemView` at `:128`)
- `MusicApp/Presentation/Feature/Home/HomeItemView/` — `HomeItemView.swift`(41), `HomeCardView.swift`(40), `HomeItemDetailView.swift`(40), `HomeCardSkeletonView.swift`(35)
- `MusicApp/Presentation/Feature/Libary/LibaryView.swift` (171 LOC) + `Libary/CustomView/PlayListItemView.swift` (restyled in P04)
- `MusicApp/Presentation/Feature/PlaylistDetail/PlaylistDetailView.swift` (184 LOC; `SongItemView` at `:148`)
- Skills: `/ck:ios-swiftui-modern`, `/ck:ios-hig-accessibility`

## Overview
- **Priority:** P2
- **Status:** pending
- **Description:** Apply tokens + entrance animations to the primary browse surfaces. These are scroll-heavy lists/grids — entrance staggering must be cheap and not re-fire on every scroll.

## Key Insights
- Verified: `HomeView` hardcodes section-header font at `:31`/`:41` — swap to `AppFont.sectionHeader()`. Inline `Color.backgroundColor` backgrounds → token (keep dark surface; these screens stay on `.default` theme).
- Home cards (`HomeCardView`) + Library playlist grid are the natural entrance-animation targets — use `.entrance(index:)` from P01, but cap staggering so long lists don't animate hundreds of rows.
- PlaylistDetail header is a candidate for a subtle parallax/gradient header sourced from the playlist's representative artwork — OPTIONAL, gate behind user interest (YAGNI for v1; note only).

## Requirements
**Functional**
- Replace hardcoded fonts/colors in HomeView with `AppFont`/token equivalents.
- Add `.entrance(index:)` to Home cards + Library grid items + PlaylistDetail rows (staggered, first ~8–12 items only).
- Press+haptic already inherited via restyled `SongItemView`/`PlayListItemView` (P04) — verify it flows here.
- Pull-to-refresh / section transitions use `MotionToken` where present.

**Non-functional**
- Entrance must not re-trigger on scroll recycling — apply on first appear per item id, not on every `onAppear`.
- Touched files kept < 200 LOC (HomeView 170, Library 171, PlaylistDetail 184 — close; extract sub-sections if edits push over).

## Architecture
```
HomeView: AppFont headers + token bg + .entrance on HomeCardView grid (index-capped)
LibaryView: token bg + .entrance on playlist grid items
PlaylistDetailView: token bg + .entrance on SongItemView rows (cap first N)
(all on \.appColorTheme = .default — no per-song color here)
```

## Related Code Files
**Modify**
- `HomeView.swift` — fonts→`AppFont`, colors→tokens, `.entrance(index:)` on cards.
- `HomeItemView/HomeCardView.swift`, `HomeItemView.swift`, `HomeItemDetailView.swift` — token colors/fonts, press where tappable.
- `LibaryView.swift` — token bg, `.entrance` on grid, press on items.
- `PlaylistDetailView.swift` — token bg, `.entrance` on song rows, header polish.

**Create** — only if a view exceeds 200 LOC after edits (e.g. extract `PlaylistDetailHeaderView.swift`).

**Delete** — none.

## Implementation Steps
1. HomeView: swap `:31`/`:41` to `AppFont.sectionHeader()`; replace inline `Color.backgroundColor` usages with token reference (no visual change, just centralization).
2. Add `.entrance(index:)` to Home card grid; cap so only first visible batch animates (e.g. `index < 12`).
3. Library: token bg + `.entrance` on playlist grid; verify `PlayListItemView` press/haptic from P04.
4. PlaylistDetail: token bg + `.entrance` on rows; optional subtle header gradient (defer unless approved).
5. Build; scroll-test for jank; verify entrance fires once per item, Reduce Motion collapses to fade.

## Todo List
- [ ] HomeView fonts/colors → tokens
- [ ] Entrance on Home cards (index-capped)
- [ ] Library grid tokens + entrance
- [ ] PlaylistDetail rows tokens + entrance
- [ ] HomeItemView family tokenized
- [ ] Compiles + scroll-tested

## Success Criteria
- No hardcoded `.system(size:)` or inline hex left in these files (use `AppFont`/tokens).
- Cards/rows fade+slide in on first appearance; smooth, no scroll stutter.
- Reduce Motion → opacity-only entrance; Dynamic Type → headers scale without clipping (note issues for P09).
- Files < 200 LOC.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Entrance re-fires on scroll (flicker) | Med | Med | Key entrance to item id + first-appear flag; cap index |
| HomeView/Library/PlaylistDetail exceed 200 LOC after edits | Med | Low | Extract header/section subviews |
| Token swap changes a color unintentionally | Low | Med | Map old hex → equivalent token; visual diff |

## Security / Accessibility Considerations
- VoiceOver: entrance animation must not delay accessibility availability; ensure elements are focusable immediately.
- Reduce Motion + Dynamic Type honored; color stays decorative.

## Next Steps
- Pattern (token swap + entrance + inherited press/haptic) repeats in P06–P08.
