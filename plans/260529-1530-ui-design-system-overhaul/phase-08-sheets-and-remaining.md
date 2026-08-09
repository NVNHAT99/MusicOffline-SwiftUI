# Phase 08 — Sheets + Remaining Surfaces

## Context Links
- Overview: [plan.md](plan.md) · Depends on: [phase-01](phase-01-foundation-color-motion-tokens.md), [phase-04](phase-04-shared-components-and-dedupe.md)
- NowPlaying sheets: `Views/LyricsView.swift` (64), `LyricsFilePickerView.swift` (38), `PasteLyricsSheetView.swift` (40), `SetupTimerSheetView.swift` (50)
- `Equalizer/Views/SavePresetSheetView.swift` (42) [if not done in P07], `ImportSong/CloudImportGuideSheetView.swift` [if not done in P06]
- Shared overlays: `MusicApp/Commons/CustomViews/ToastView.swift`, `SearchView.swift`, `TimerPickerView.swift`, `SongSkeletonItemView.swift` (+ `ShimmerViewModifier.swift`)
- Presentation modifier: `MusicApp/Commons/Modifiers/Private/PresentationModifier.swift`
- Skills: `/ck:ios-swiftui-modern`, `/ck:ios-hig-accessibility`

## Overview
- **Priority:** P3
- **Status:** pending
- **Description:** Final token + transition sweep over sheets, overlays, and small shared views not covered by earlier phases. Ensures no surface is left on the old monotone styling.

## Key Insights
- Sheets are short-lived modals → token sweep + presentation transition polish + press/haptic on their actions. Low risk.
- `ToastView` is app-wide feedback → restyle to use accent/semantic tokens; entrance/exit transition via `MotionToken`; optional success/error haptic at show time.
- `SongSkeletonItemView` + `.shimmer()` already exist — verify shimmer color still reads well on token surfaces; align shimmer base/highlight to tokens.
- `SearchView`, `TimerPickerView` are shared custom inputs → token sweep + focus/press feedback.
- This phase is a cleanup net: grep for any remaining inline `Color.backgroundColor`/hex/`.system(size:)` not yet migrated and fix.

## Requirements
**Functional**
- Token sweep across all listed sheets/overlays; press+haptic on their action buttons.
- `ToastView`: tokenized, animated in/out, success/error variant feedback.
- Shimmer/skeleton colors aligned to tokens.
- Sheet presentation transitions consistent (via `PresentationModifier` if it controls them).
- Final grep sweep: zero stray `Color.backgroundColor` inline / hardcoded hex / `.system(size:)` left outside the design system.

**Non-functional**
- All files < 200 LOC (most already small).

## Architecture
```
Each sheet/overlay → tokens + AppFont + press/haptic on actions
ToastView → token style + MotionToken in/out + optional haptic
Shimmer/skeleton → token-aligned base/highlight
Final sweep: grep residual inline colors/fonts → migrate
```

## Related Code Files
**Modify**
- `LyricsView.swift`, `LyricsFilePickerView.swift`, `PasteLyricsSheetView.swift`, `SetupTimerSheetView.swift`
- `SavePresetSheetView.swift` / `CloudImportGuideSheetView.swift` (only if deferred from P06/P07)
- `ToastView.swift`, `SearchView.swift`, `TimerPickerView.swift`, `SongSkeletonItemView.swift`, `ShimmerViewModifier.swift`
- `Modifiers/Private/PresentationModifier.swift` (only if it governs sheet animation)
- Any file flagged by the final residual-color grep

**Create** — none expected.

**Delete** — none.

## Implementation Steps
1. Sweep each sheet: tokens, `AppFont`, `.pressScale()`+haptic on confirm/cancel.
2. Restyle `ToastView`: token bg/accent, `MotionToken` in/out transition, success/error variant + optional haptic on show.
3. Align shimmer base/highlight to tokens; verify skeleton reads on dark surface.
4. Sweep `SearchView`/`TimerPickerView` for tokens + focus/press feedback.
5. Run residual grep: `grep -rn "Color.backgroundColor\|\.system(size:\|hexString:" MusicApp/Presentation MusicApp/Commons` → migrate any stragglers (excluding the token definitions themselves).
6. Build; open each sheet/toast; verify transitions + Reduce Motion.

## Todo List
- [ ] Lyrics/PasteLyrics/Timer/FilePicker sheets tokenized + press/haptic
- [ ] ToastView restyled + animated + feedback
- [ ] Shimmer/skeleton token-aligned
- [ ] SearchView + TimerPickerView tokenized
- [ ] Residual inline-color/font grep clean
- [ ] Compiles + sheets/toasts verified

## Success Criteria
- Every sheet/overlay uses tokens + consistent presentation transition.
- Toast animates in/out, optional haptic, legible.
- Residual grep returns only token-definition files — no stray inline styling app-wide.
- Reduce Motion respected; files < 200 LOC.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Shimmer becomes invisible on new surfaces | Low | Low | Tune base/highlight against token surface; visual check |
| Changing `PresentationModifier` affects all sheets at once | Med | Med | Prefer per-sheet transition; only touch shared modifier if clearly safe; test broadly |
| Missed surfaces remain monotone | Med | Low | Final residual grep is the safety net |

## Security / Accessibility Considerations
- Toast/announcements should post `.accessibilityNotification` where they convey status to VoiceOver users.
- Reduce Motion: toast/sheet transitions degrade to fade. Dynamic Type in sheet bodies.

## Next Steps
- Whole app now on the new design system → final QA (P09).
