# Phase 06 — Playlist Editors + Import + Transfer

## Context Links
- Overview: [plan.md](plan.md) · Depends on: [phase-01](phase-01-foundation-color-motion-tokens.md), [phase-04](phase-04-shared-components-and-dedupe.md)
- `MusicApp/Presentation/Feature/AddNewsPlaylist/AddNewPlayListView.swift` (99)
- `MusicApp/Presentation/Feature/AddNewSongs/EditPlaylistView.swift` (96) + `AddNewSongs/views/SelectedSongItemView.swift` (50)
- `MusicApp/Presentation/Feature/SmartPlaylistEditor/SmartPlaylistEditorView.swift` (142)
- `MusicApp/Presentation/Feature/ImportHub/ImportHubView.swift` (116)
- `MusicApp/Presentation/Feature/ImportSong/ImportSongView.swift` (137) + `CloudImportGuideSheetView.swift` (83)
- `MusicApp/Presentation/Feature/Import/UrlDownload/UrlDownloadView.swift` (148)
- `MusicApp/Presentation/Feature/TransferView/TransferView.swift` (188) + `TransferGuideView.swift` (99) + `GuideTransferView/GuideTransferView.swift` (40)
- Skills: `/ck:ios-swiftui-modern`, `/ck:ios-hig-accessibility`

## Overview
- **Priority:** P2
- **Status:** pending
- **Description:** Apply tokens + entrance/press motion to the create/import/transfer flows. These are form- and action-heavy; emphasis on button press feedback, input field styling, and progress/state transitions.

## Key Insights
- These screens are mostly forms + lists + action buttons → biggest wins are token colors/fonts, `.pressScale()`+haptic on primary actions, and smooth state transitions (e.g. import progress, transfer connecting states).
- `TransferView` (188 LOC) is close to the limit — extract status/section subviews if edits push over 200.
- `EditPlaylistView` uses `SelectedSongItemView` (50 LOC) — restyle that small row too; it mirrors `SongItemView` but for selected-state.
- Success/error states (import done, transfer connected) are good `.sensoryFeedback(.success/.error)` moments.

## Requirements
**Functional**
- Token colors/fonts across all listed views; remove inline hex/`.system(size:)`.
- Primary action buttons (`Create`, `Add`, `Import`, `Download`, `Start Transfer`): `.pressScale()` + impact haptic; success/error feedback on completion.
- Entrance animation on lists (selectable songs, import sources, transfer steps), index-capped.
- Progress indicators / state changes animate with `MotionToken`.

**Non-functional**
- Keep files < 200 LOC; extract where needed (TransferView).
- Screens stay on `.default` theme.

## Architecture
```
For each view: inline colors/fonts → tokens/AppFont
Primary buttons → .pressScale + Haptics (impact on tap, success/error on result)
Lists → .entrance(index:) capped
State transitions (idle→loading→done) → MotionToken cross-fade
```

## Related Code Files
**Modify**
- `AddNewPlayListView.swift`, `EditPlaylistView.swift`, `SelectedSongItemView.swift`
- `SmartPlaylistEditorView.swift`
- `ImportHubView.swift`, `ImportSongView.swift`, `CloudImportGuideSheetView.swift`, `UrlDownloadView.swift`
- `TransferView.swift`, `TransferGuideView.swift`, `GuideTransferView.swift`

**Create** — `TransferStatusView.swift` (or similar) only if `TransferView` exceeds 200 LOC after edits.

**Delete** — none.

## Implementation Steps
1. Sweep each view: replace inline colors→tokens, fonts→`AppFont`.
2. Wrap primary CTAs in `.pressScale()` + impact haptic; add `.sensoryFeedback(.success, …)` on import/transfer completion and `.error` on failure (drive off existing State enums).
3. Add `.entrance(index:)` to selectable-song lists, import-source lists, transfer step lists (cap first N).
4. Animate loading/progress/connection state transitions with `MotionToken`.
5. If `TransferView` > 200 LOC, extract status section.
6. Build; exercise each flow (create playlist, import, transfer connect) on device.

## Todo List
- [ ] AddNewPlaylist + EditPlaylist + SelectedSongItemView tokens/press
- [ ] SmartPlaylistEditor tokens/press/entrance
- [ ] ImportHub + ImportSong + CloudImportGuide + UrlDownload tokens/press/feedback
- [ ] TransferView (+ guides) tokens/press/state-feedback; extract if >200 LOC
- [ ] Compiles + flows exercised

## Success Criteria
- No inline hex/`.system(size:)` left in listed files.
- Primary actions give press + haptic; completion gives success/error feedback.
- Lists animate in; state transitions smooth.
- Reduce Motion respected; files < 200 LOC.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Haptic on every list interaction = annoying | Med | Med | Reserve haptics for primary actions + state results, not every row |
| Success/error feedback fires multiple times | Med | Med | Trigger on State enum transition (value change), not on body re-eval |
| TransferView refactor breaks GCD web-server wiring | Low | High | UI-only edits; do not touch transfer logic/VM; visual diff |

## Security / Accessibility Considerations
- Transfer involves local web server — **UI-only changes here**, no protocol/security edits.
- VoiceOver: form fields keep labels; progress announces via `.accessibilityValue`. Reduce Motion + Dynamic Type honored.

## Next Steps
- Leaves Settings/Equalizer/AudioEditor (P07) and sheets (P08).
