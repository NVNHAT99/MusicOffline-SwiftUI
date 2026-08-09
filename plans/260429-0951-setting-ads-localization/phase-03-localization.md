# Phase 03 — Localization (EN + VI)

## Context Links
- Phase 1 stub: `SettingViewIntent.showLanguagePicker`
- `MusicApp/Core/UserDataDefault.swift`
- `MusicApp/Presentation/Feature/Setting/SettingView.swift`
- Apple xcstrings docs (use `docs-seeker` if needed)

## Overview
- **Priority:** P2
- **Status:** pending (depends on Phase 1)
- **Description:** Add iOS-native localization via `Localizable.xcstrings`, support EN (default) + VI, custom `LanguageManager` for in-app switching without restart.

## Key Insights
- iOS doesn't natively switch language without restart unless we override `Bundle.main` lookup OR use `String(localized:bundle:)` with custom bundle per locale
- Common pattern: `LanguageManager` swaps a `@Published` `Locale`/`Bundle`, views use environment-injected wrapper to re-render
- xcstrings (Xcode 15+) replaces .strings files — single file, JSON-backed, supports plurals/variations
- Scope this phase: localize **Setting screen + Tab bar + common shared strings only** (~30 keys); other screens follow incrementally
- Persist selection in `UserDataDefault` (already exists)

## Requirements

### Functional
- Language picker sheet (Setting → General → Language) lists: English, Tiếng Việt
- Current selection shown as accessory text on Language row
- Tap language → save to UserDefaults → notify LanguageManager → all `LocalizedStringKey` views in Setting re-render
- Default to system language if EN or VI; else fall back to EN
- Persists across app restart

### Non-functional
- No app restart required for language switch
- All Setting screen text uses localized keys
- Tab bar titles localized

## Architecture

### Data Flow
```
LanguagePickerSheet tap
   ↓
LanguageManager.shared.setLanguage(.vi)
   ├─ UserDataDefault.savedLanguage = "vi"
   ├─ self.currentLanguage = .vi (Published)
   └─ self.bundle = Bundle(path: vi.lproj) (Published)
        ↓
@EnvironmentObject LanguageManager triggers re-render
   ↓
Text(L10n.settings_language) reads from current bundle
```

### Components
- `Localizable.xcstrings` — string catalog (Xcode auto-creates lproj folders on build)
- `LanguageManager.swift` — ObservableObject, manages current language + bundle
- `L10n.swift` — type-safe key constants (enum with static lets) — DRY for repeated keys
- `LanguagePickerSheet.swift` — sheet view bound to ViewModel

## Related Code Files

### Modify
- `MusicApp/Presentation/Feature/Setting/SettingView.swift` — replace literals with `L10n.*`; add language picker sheet
- `SettingViewIntent.swift` — add `.selectLanguage(AppLanguage)`
- `SettingViewState.swift` — add `isShowLanguagePicker: Bool`, replace `selectedLanguageDisplay` derivation from `LanguageManager`
- `SettingStateAction.swift` / `SettingStateReducer.swift` — handle new actions
- `MusicApp/Core/UserDataDefault.swift` — add `var savedLanguage: String?`
- `MusicApp/Presentation/Feature/App/MusicApp.swift` — inject `LanguageManager` into environment
- `MusicApp/Presentation/Feature/Main/MainTabView.swift` (or equivalent) — localize tab labels

### Create
- `MusicApp/Resources/Localizable.xcstrings` (or wherever resources live; check project structure)
- `MusicApp/Core/Localization/LanguageManager.swift`
- `MusicApp/Core/Localization/AppLanguage.swift` (enum: en, vi)
- `MusicApp/Core/Localization/L10n.swift` (type-safe key registry)
- `MusicApp/Presentation/Feature/Setting/Components/LanguagePickerSheet.swift`

### Delete
- None

## Implementation Steps

1. **AppLanguage enum**
   ```swift
   enum AppLanguage: String, CaseIterable, Identifiable {
     case en, vi
     var id: String { rawValue }
     var displayName: String {
       switch self { case .en: "English"; case .vi: "Tiếng Việt" }
     }
     var bundleCode: String { rawValue }
   }
   ```

2. **LanguageManager**
   - `@MainActor final class LanguageManager: ObservableObject`
   - `@Published private(set) var current: AppLanguage`
   - `@Published private(set) var bundle: Bundle`
   - `init` reads UserDataDefault.savedLanguage or system locale; resolves bundle
   - `func setLanguage(_ lang: AppLanguage)` — saves + updates published
   - `func localized(_ key: String) -> String` — `bundle.localizedString(forKey: key, value: nil, table: nil)`
   - Provide static `.shared` for non-SwiftUI usage; also inject as EnvironmentObject

3. **UserDataDefault extension**
   - Add `savedLanguage: String?` getter/setter using existing UserDefaults wrapper

4. **Localizable.xcstrings**
   - Create via Xcode (File → New → String Catalog)
   - Add base keys (English):
     - `setting.title` = "Setting"
     - `setting.section.general` = "General"
     - `setting.section.about` = "About"
     - `setting.section.dangerZone` = "Danger Zone"
     - `setting.transferMp3` = "Transfer MP3 files"
     - `setting.language` = "Language"
     - `setting.rateApp` = "Rate App"
     - `setting.shareApp` = "Share App"
     - `setting.privacy` = "Privacy Policy"
     - `setting.terms` = "Terms of Use"
     - `setting.appVersion` = "App Version"
     - `setting.deleteAllSongs` = "Delete all songs"
     - `setting.deleteConfirm.title` = "Delete all songs?"
     - `setting.deleteConfirm.message` = "This cannot be undone."
     - `common.cancel` = "Cancel"
     - `common.delete` = "Delete"
     - `tab.home` = "Home"
     - `tab.library` = "Library"
     - `tab.transfer` = "Transfer"
     - `tab.setting` = "Setting"
   - Add Vietnamese translations in same catalog

5. **L10n.swift**
   ```swift
   enum L10n {
     static let settingTitle = "setting.title"
     // ... etc
   }
   ```
   Helper extension on `String`:
   ```swift
   extension String {
     func localized(using lm: LanguageManager) -> String {
       lm.bundle.localizedString(forKey: self, value: nil, table: nil)
     }
   }
   ```

6. **Inject LanguageManager**
   - In `MusicApp.swift`: `.environmentObject(LanguageManager.shared)`
   - SettingView: `@EnvironmentObject var lm: LanguageManager`
   - Replace `Text("Setting")` with `Text(L10n.settingTitle.localized(using: lm))`

7. **LanguagePickerSheet**
   - List of `AppLanguage.allCases` with checkmark on current
   - Tap → `viewModel.send(.selectLanguage(lang))` → reducer updates `isShowLanguagePicker = false`; ViewModel calls `LanguageManager.shared.setLanguage(lang)`
   - Bind `.sheet(isPresented: ...)` in SettingView

8. **Tab bar localization**
   - Locate `MainTabView` (likely `MusicApp/Presentation/Feature/Main/`)
   - Replace tab label literals with localized keys

9. **Verify**
   - Compile
   - Switch language → Setting screen text + tab bar update without restart
   - Restart app → selection persists

## Todo List

- [ ] Create `AppLanguage` enum
- [ ] Create `LanguageManager` ObservableObject
- [ ] Extend `UserDataDefault` with `savedLanguage`
- [ ] Create `Localizable.xcstrings` with EN keys
- [ ] Add Vietnamese translations
- [ ] Create `L10n.swift` with key constants + String extension
- [ ] Inject `LanguageManager` in `MusicApp.swift`
- [ ] Replace SettingView literals with localized strings
- [ ] Create `LanguagePickerSheet`
- [ ] Wire `selectLanguage` intent
- [ ] Localize tab bar labels in MainTabView
- [ ] Update Setting Language row to show current language
- [ ] Verify switch + persistence

## Success Criteria
- Tap Language → sheet appears with EN + VI options
- Selecting language updates Setting + tab bar instantly (no restart)
- Selection persists across cold launch
- Default = system language if supported, else EN
- All Setting screen strings localized (zero hardcoded literals)
- No file exceeds 200 LOC

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| SwiftUI doesn't re-render when bundle swaps | High | High | Use `@EnvironmentObject LanguageManager` and reference `lm.current` (or `.id(lm.current)` view modifier) to force redraw |
| xcstrings requires Xcode 15+ | Low | High | Verify dev Xcode version; fallback to .strings + .stringsdict if needed |
| Vietnamese diacritics break UI layout | Low | Low | Use `.minimumScaleFactor(0.8)` on tight rows |
| Other screens still hardcoded → mixed UX | High | Med | Document as known limitation; future tickets per screen |
| Language change doesn't propagate to UIKit views (e.g. UIActivityViewController) | Med | Low | Acceptable; share sheet uses system locale |

## Security Considerations
- N/A (UI only)

## Next Steps (post-phase)
- Localize Home, Library, NowPlaying, Transfer screens
- Add more languages (es, fr, ja) by extending xcstrings
- Consider RTL support if adding Arabic/Hebrew
