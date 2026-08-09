# Phase 07 — Settings + Equalizer + AudioEditor

## Context Links
- Overview: [plan.md](plan.md) · Depends on: [phase-01](phase-01-foundation-color-motion-tokens.md), [phase-04](phase-04-shared-components-and-dedupe.md)
- `MusicApp/Presentation/Feature/Setting/SettingView.swift` (135) + `Setting/Components/SettingRowView.swift` (39)
- `MusicApp/Presentation/Feature/Equalizer/EqualizerView.swift` (200 — AT limit) + `Equalizer/Views/EffectsSectionView.swift` (188), `EQBandSliderView.swift` (46), `SavePresetSheetView.swift` (42)
- `MusicApp/Presentation/Feature/AudioEditor/AudioEditorView.swift` (199 — AT limit) + `AudioEditor/Views/TrimHandlesView.swift` (72), `WaveformView.swift` (32)
- Skills: `/ck:ios-swiftui-modern`, `/ck:ios-hig-accessibility`, `/ck:design-system-architect`

## Overview
- **Priority:** P2
- **Status:** pending
- **Description:** Apply tokens + tasteful motion to the utility/tool screens. Equalizer and AudioEditor are interaction-rich (sliders, waveform, trim handles) — good candidates for value-change haptics and live-feedback motion, but must not interfere with precise dragging.

## Key Insights
- `EqualizerView` (200) and `AudioEditorView` (199) are **already at/over the 200-LOC limit** — any edits here MUST extract subviews, not append. Both already have `Views/` subfolders to extend.
- EQ band sliders: a light `.sensoryFeedback(.selection)` at detents (e.g. 0 dB center) adds polish — but throttle; no haptic on every continuous value tick.
- AudioEditor trim handles: haptic on grab/release + snap; waveform color → accent token.
- SettingView: straightforward token sweep + row press feedback; `SettingRowView` is the shared row.

## Requirements
**Functional**
- Token colors/fonts across Settings, Equalizer, AudioEditor and their subviews.
- `SettingRowView`: `.pressScale()` + light haptic on tap; chevrons/icons themed.
- EQ sliders: themed track/thumb (accent); selection haptic at center detent only.
- AudioEditor: themed waveform + trim handles; grab/release/snap haptics; trim transitions via `MotionToken`.

**Non-functional**
- EqualizerView/AudioEditorView already at limit → extract before adding.
- Continuous-gesture haptics throttled to avoid buzz storms.

## Architecture
```
SettingView → tokens + SettingRowView press/haptic
EqualizerView → tokens; EQBandSliderView themed + detent haptic; extract a section if >200 LOC
AudioEditorView → tokens; WaveformView accent; TrimHandlesView grab/snap haptics; extract if >200 LOC
```

## Related Code Files
**Modify**
- `SettingView.swift`, `Setting/Components/SettingRowView.swift`
- `EqualizerView.swift`, `Equalizer/Views/EffectsSectionView.swift`, `EQBandSliderView.swift`, `SavePresetSheetView.swift`
- `AudioEditor/AudioEditorView.swift`, `AudioEditor/Views/TrimHandlesView.swift`, `WaveformView.swift`

**Create** — extract subviews from `EqualizerView`/`AudioEditorView` if edits push past 200 LOC (e.g. `EqualizerHeaderView.swift`, `AudioEditorToolbarView.swift`).

**Delete** — none.

## Implementation Steps
1. SettingView: token sweep; `SettingRowView` press+haptic; section headers via `AppFont`.
2. Equalizer: token sweep; theme `EQBandSliderView` track/thumb; add detent-only selection haptic (compare value crossing 0 dB). Extract a subview if file grows beyond 200.
3. AudioEditor: token sweep; `WaveformView` fill → accent; `TrimHandlesView` grab/release/snap haptics; animate trim region changes with `MotionToken`. Extract if needed.
4. Build; test EQ drag (no haptic storm), trim drag precision retained.

## Todo List
- [ ] SettingView + SettingRowView tokens/press
- [ ] Equalizer tokens + themed sliders + detent haptic (extract if >200 LOC)
- [ ] AudioEditor tokens + waveform accent + trim haptics (extract if >200 LOC)
- [ ] SavePresetSheet tokens
- [ ] Compiles + interaction-tested

## Success Criteria
- No inline hex/`.system(size:)` in listed files.
- Sliders/waveform use accent token; haptics fire at detents/grab/release only (not continuously).
- Dragging precision unaffected by added motion.
- Reduce Motion respected; all files < 200 LOC.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Haptic storm on continuous slider drag | High if naive | Med | Trigger only on detent crossing / grab / release, throttle |
| Editing 200-LOC views appends past limit | High | Low | Extract subviews first, then edit |
| Animation interferes with precise trim | Med | High | Keep trim handle motion to release-snap only; no animation during active drag |

## Security / Accessibility Considerations
- VoiceOver: EQ sliders + trim handles expose `.accessibilityValue` (dB / timestamp); haptics supplement, never replace, value announcement.
- Reduce Motion: disable snap animations; keep functional behavior. Dynamic Type on settings rows.

## Next Steps
- Only sheets + remaining surfaces (P08) then QA (P09).
