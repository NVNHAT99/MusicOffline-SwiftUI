# Phase 09 — QA Pass + Docs

## Context Links
- Overview: [plan.md](plan.md) · Depends on: ALL prior phases (P01–P08)
- Contrast engine: `MusicApp/DesignSystem/Color/ContrastGuard.swift` (P02)
- Motion presets: `MusicApp/DesignSystem/MotionToken.swift` (P01)
- Typography: `MusicApp/DesignSystem/AppFont.swift` (fixed sizes — Dynamic Type gap)
- Docs: `docs/code-standards.md`, `docs/system-architecture.md`, `docs/design-guidelines.md` (create if absent), `docs/project-changelog.md`, `docs/development-roadmap.md`
- Skills: `/ck:ios-hig-accessibility` (primary), `/ck:design-system-architect`

## Overview
- **Priority:** P2
- **Status:** pending
- **Description:** Full accessibility + performance QA across the redesigned app, then document the new design system. This is the "done means observable" gate: contrast measured, Reduce Motion verified, Dynamic Type checked, VoiceOver navigable, no perf regressions.

## Key Insights
- The single biggest accessibility risk is the dynamic-color legibility on the player (P02/P03). QA must verify across a spread of real artworks (light, dark, saturated, low-contrast).
- `AppFont` uses fixed point sizes (no `relativeTo:`) — Dynamic Type currently NOT supported. Decide here: (a) document as known limitation, or (b) small follow-up to make `AppFont` scale. **Ask user** which scope they want — do not silently expand.
- Color must never be the sole information carrier (HIG): current-song highlight pairs accent with position/icon; verify.

## Requirements
**Functional / Verification**
- **Contrast audit:** sample N artworks (≥8 varied), confirm player text ≥ WCAG AA (4.5:1) via `ContrastGuard` + visual check. Check Increase Contrast setting.
- **Reduce Motion:** toggle ON system-wide; verify every animation (entrance, press-scale, mini↔full, gradient cross-fade, toast) degrades to fade/instant and app stays usable.
- **Dynamic Type:** step through sizes (incl. accessibility sizes); note clipping/overlap; decide scope on `AppFont`.
- **VoiceOver:** navigate each screen; verify labels/traits/values; current-tab `.isSelected`; sliders announce values; toasts announce.
- **Performance:** scroll Home/Library/PlaylistDetail and switch songs rapidly; confirm no frame drops from color extraction (cache working); Instruments time-profiler spot check if jank seen.

**Docs**
- Update/create `docs/design-guidelines.md` (color theme system, motion tokens, haptics, accessibility rules).
- Update `docs/code-standards.md` (use tokens not inline colors/fonts; <200 LOC; modifier usage).
- Update `docs/system-architecture.md` (artwork→color→theme→Environment flow + PaletteProvider cache).
- Update `docs/project-changelog.md` + `docs/development-roadmap.md`.

## Architecture
```
QA matrix (manual + assert):
  Contrast → ContrastGuard unit tests (P02) + 8-artwork visual sweep + Increase Contrast
  Motion   → Reduce Motion ON: entrance/press/mini-full/gradient/toast all fade/instant
  Type     → Dynamic Type sweep across all screens (clipping log)
  VoiceOver→ per-screen label/trait/value audit
  Perf     → scroll + rapid song-switch; Instruments if needed
Docs sync → design-guidelines / code-standards / system-architecture / changelog / roadmap
```

## Related Code Files
**Modify (only QA-driven fixes)**
- Any view with a contrast/clipping/VoiceOver defect found during audit (targeted fixes, < 200 LOC).
- `AppFont.swift` — ONLY if user approves Dynamic Type scope expansion.

**Create**
- `docs/design-guidelines.md` (if absent).

**Delete** — none.

## Implementation Steps
1. Run P02 contrast unit tests; add any missing edge-case colors.
2. Visual contrast sweep over ≥8 varied artworks on the player; log failures; tune `ContrastGuard`/scrim if any fail.
3. Toggle Reduce Motion ON; walk every screen; fix any animation that ignores it.
4. Dynamic Type sweep; log clipping; **ask user** whether to fix `AppFont` now or document as limitation.
5. VoiceOver pass per screen; fix labels/traits/values.
6. Perf: rapid song-switch + long-list scroll; confirm cache prevents recompute; profile if jank.
7. Write/update the five docs files; describe the theme system, tokens, motion, haptics, accessibility contract.
8. Update changelog + roadmap entries; final full build.

## Todo List
- [ ] Contrast unit tests green + 8-artwork visual sweep
- [ ] Increase Contrast setting checked
- [ ] Reduce Motion full-app verification + fixes
- [ ] Dynamic Type sweep + user decision on AppFont scope
- [ ] VoiceOver per-screen audit + fixes
- [ ] Performance / cache verification (no recompute on redraw)
- [ ] `docs/design-guidelines.md` written
- [ ] code-standards / system-architecture / changelog / roadmap updated
- [ ] Final clean build

## Success Criteria
- All sampled artworks yield WCAG AA player text (measured, not eyeballed alone).
- Reduce Motion ON → zero non-essential motion; app fully usable.
- VoiceOver can operate every screen; current tab/song states announced.
- No measurable frame drop attributable to color extraction.
- Design system documented; future contributors have a single reference.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Some artworks still fail contrast | Med | High | Tighten scrim/darkening in `ContrastGuard`; worst-case force dark overlay + white text |
| Dynamic Type scope creep | Med | Med | **Ask user** before touching `AppFont`; default = document limitation |
| QA finds defects late requiring multi-phase rework | Med | Med | Earlier phases each self-verified; P09 is confirmation not discovery |
| Docs drift from code | Low | Low | Write docs from final code state, not the plan |

## Security / Accessibility Considerations
- This phase IS the accessibility gate — full HIG/WCAG verification.
- No security surface touched; transfer/web-server logic untouched throughout the overhaul (UI-only).

## Next Steps
- Overhaul complete. Optional future work (NOT in scope, note only): per-row artwork color in lists, PlaylistDetail parallax header, histogram-based palette, full Dynamic Type support — pursue only on explicit user request.

## Unresolved Questions
- Dynamic Type: fix `AppFont` to scale now, or document as a known limitation and defer? (decide in this phase with user)
