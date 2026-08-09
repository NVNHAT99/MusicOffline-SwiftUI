# Phase 01 — Setting UI Refactor

## Context Links
- `MusicApp/Presentation/Feature/Setting/SettingView.swift`
- `MusicApp/Presentation/Feature/Setting/SettingViewViewModel.swift`
- `MusicApp/Presentation/Feature/Setting/SettingViewIntent.swift`
- `MusicApp/Presentation/Feature/Setting/SettingViewState.swift`
- `MusicApp/Presentation/Feature/Setting/SettingStateAction.swift`
- `MusicApp/Presentation/Feature/Setting/SettingStateReducer.swift`
- `MusicApp/Core/Router/AppRoute.swift`

## Overview
- **Priority:** P1 (foundation for Phase 3 language picker)
- **Status:** ✅ Complete
- **Description:** Restructure flat list into 3 sections: **General / About / Danger Zone**. Add Rate App, Share App, Privacy, Terms, App Version, Language placeholder.

## Key Insights
- Existing MVI structure already separates Action/Reducer cleanly — extend, don't rewrite
- `AppRoute` is enum-based; URL opening can stay outside router (use `UIApplication.shared.open`)
- `delete all songs` currently no-op (TODO comment); wire via `DeleteSongUseCase` already in DIContainer
- SKStoreReviewController is fire-and-forget; no callback handling needed
- UIActivityViewController must be presented from a `UIWindowScene` root — use `UIViewControllerRepresentable` wrapper or `Helper` accessor

## Requirements

### Functional
- **General** section
  - Transfer MP3 files → routes to `.transferAudio`
  - Language → opens picker sheet (Phase 1 shows disabled label "English"; Phase 3 wires real picker)
- **About** section
  - Rate App → `SKStoreReviewController.requestReview(in: scene)`
  - Share App → `UIActivityViewController` with App Store URL (placeholder)
  - Privacy Policy → `UIApplication.shared.open(privacyURL)`
  - Terms of Use → `UIApplication.shared.open(termsURL)`
  - App Version → display `CFBundleShortVersionString (CFBundleVersion)`, non-interactive
- **Danger Zone** section
  - Delete all songs → confirmation alert → `DeleteSongUseCase.executeAll()` → toast result

### Non-functional
- Each row uses consistent `SettingRowView` component (reusable)
- Section headers styled consistently with existing dark theme
- File size: extract `SettingRowView`, `SettingSection` if SettingView exceeds 200 LOC

## Architecture

### Data Flow
```
User tap → SettingView.send(intent) → ViewModel.send(intent)
   ↓
   ├─ Side effect (open URL / present sheet / call usecase)
   └─ Reducer.reduce(state, action) → @Published state → View
```

### New Components
- `SettingConstants.swift` — placeholder URLs, App Store ID
- `SettingRowView.swift` — reusable row (icon + title + accessory)
- `ShareSheet.swift` — UIActivityViewController wrapper (UIViewControllerRepresentable)
- `RateAppHelper.swift` — wraps SKStoreReviewController call

## Related Code Files

### Modify
- `SettingView.swift` — restructure to 3 sections
- `SettingViewIntent.swift` — add new intents
- `SettingViewState.swift` — add `appVersion`, `selectedLanguage`, `isShowDeleteConfirm`, `isShowShareSheet`
- `SettingStateAction.swift` — add corresponding actions
- `SettingStateReducer.swift` — handle new actions
- `SettingViewViewModel.swift` — implement new intent handlers; inject `DeleteSongUseCase`
- `MusicApp/Core/DI/DIContainer+ViewFactory.swift` — pass `deleteSongUseCase` to factory

### Create
- `MusicApp/Presentation/Feature/Setting/Components/SettingRowView.swift`
- `MusicApp/Presentation/Feature/Setting/Components/ShareSheet.swift`
- `MusicApp/Presentation/Feature/Setting/Helpers/RateAppHelper.swift`
- `MusicApp/Presentation/Feature/Setting/SettingConstants.swift`

### Delete
- None

## Implementation Steps

1. **State / Intent / Action expansion**
   - `SettingViewIntent`: add `.rateApp`, `.shareApp`, `.openPrivacy`, `.openTerms`, `.showLanguagePicker`, `.confirmDeleteAllSongs`, `.cancelDeleteAllSongs`
   - `SettingViewState`: add `appVersion: String`, `selectedLanguageDisplay: String = "English"`, `isShowDeleteConfirm: Bool`, `isShowShareSheet: Bool`
   - `SettingStateAction`: add `.setShowDeleteConfirm(Bool)`, `.setShowShareSheet(Bool)`, `.setLanguageDisplay(String)`
   - `SettingStateReducer`: handle new actions

2. **Constants**
   - Create `SettingConstants.swift`:
     ```swift
     enum SettingConstants {
       static let privacyURL = URL(string: "https://example.com/privacy")!
       static let termsURL = URL(string: "https://example.com/terms")!
       static let appStoreID = "0000000000" // placeholder
       static var shareURL: URL { URL(string: "https://apps.apple.com/app/id\(appStoreID)")! }
     }
     ```

3. **Components**
   - `SettingRowView`: title, optional subtitle, optional accessory chevron, tap closure
   - `ShareSheet`: UIViewControllerRepresentable around UIActivityViewController([shareURL])
   - `RateAppHelper.requestReview()`: get active windowScene, call `SKStoreReviewController.requestReview(in:)`

4. **ViewModel handlers**
   - `.rateApp` → `RateAppHelper.requestReview()`
   - `.shareApp` → reduce `.setShowShareSheet(true)`
   - `.openPrivacy/.openTerms` → `UIApplication.shared.open(url)`
   - `.showLanguagePicker` → no-op stub for Phase 1 (logs); Phase 3 will replace
   - `.confirmDeleteAllSongs` → `Task { try await deleteSongUseCase.executeAll(); reduce toast }`
   - Init reads `Bundle.main` to populate `state.appVersion`

5. **View restructure**
   - Replace List body with 3 sections using `SettingRowView`
   - Add `.alert(...)` bound to `isShowDeleteConfirm` for delete confirmation
   - Add `.sheet(isPresented: $isShowShareSheet) { ShareSheet(items: [...]) }`
   - Keep existing `CustomNavigationBar` and toast overlay

6. **DI wiring**
   - Add `deleteSongUseCase` to `SettingViewViewModel` init (default to existing `DeleteSongUseCase()`)
   - Update `DIContainer.makeSettingViewModel()` to pass `useCases.deleteSongUseCase`

7. **Compile + smoke test**
   - Build target
   - Manual: tap each row, verify URL open, share sheet, alert, version display

## Todo List

- [x] Expand `SettingViewIntent` with 7 new cases
- [x] Expand `SettingViewState` with 4 new fields
- [x] Expand `SettingStateAction` + `SettingStateReducer`
- [x] Create `SettingConstants.swift`
- [x] Create `SettingRowView.swift`
- [x] Create `ShareSheet.swift`
- [x] Create `RateAppHelper.swift`
- [x] Implement new intent handlers in ViewModel (incl. `DeleteSongUseCase` injection)
- [x] Restructure `SettingView` into 3 sections
- [x] Wire alert + share sheet modifiers
- [x] Update `DIContainer.makeSettingViewModel()` factory
- [x] Compile + manual verify each row

## Success Criteria
- Setting screen renders 3 sections matching spec
- All 7 actions trigger expected behavior (URL opens, sheets, alert, toast)
- App version displays correctly from Bundle
- Delete confirmation shows alert before destructive action
- No file exceeds 200 LOC
- No compile warnings/errors

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `DeleteSongUseCase.executeAll()` not implemented | Med | High | Verify protocol exposes batch delete; if missing, add minimal `executeAll()` |
| ShareSheet on iPad needs popover anchor | Low | Med | Add `.popoverPresentationController` source view fallback |
| SKStoreReviewController unavailable below iOS 14 | Low | Low | Project min iOS already ≥ 14 (verify) |
| Placeholder URLs cause user confusion in TestFlight | Med | Low | Add `// TODO: replace before release` markers |

## Security Considerations
- Privacy/ToU URLs must use HTTPS
- No user data leaks via share sheet (only app store URL)
- Delete-all action gated by confirmation alert
