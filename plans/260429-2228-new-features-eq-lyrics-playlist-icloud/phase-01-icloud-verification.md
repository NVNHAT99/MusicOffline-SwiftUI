# Phase 01 — iCloud Drive Verification & Entitlements

## Context Links
- `MusicApp/Domain/UseCase/ImportSongFromFilesUseCase.swift`
- `MusicApp/Info.plist`
- `MusicApp/MusicApp.entitlements`

## Overview
- **Priority:** P2
- **Status:** ✅ complete
- **Effort:** 0.5 day
- **Risk:** Low

Verify and formalize iCloud Drive import. `UIDocumentPickerViewController` already surfaces iCloud locations when user has iCloud Drive enabled — task is to confirm, add capability, document.

## Requirements
### Functional
- User picks .mp3/.m4a from iCloud Drive via existing import flow.
- File downloads (if not local) and imports into app sandbox.
- UI copy mentions "iCloud Drive" support.

### Non-Functional
- No regression on local Files / On-My-iPhone import.
- No background sync required v1 (user-initiated only).

## Architecture
```
User taps "Import" → UIDocumentPickerViewController (asInCopy)
  → iCloud file selected → coordinator triggers download
  → file copied into app Documents/ → CoreData Song row created
```
No code-level changes needed if entitlement present; coordinator already handles `startAccessingSecurityScopedResource`.

## Related Code Files
### Modify
- `MusicApp/Domain/UseCase/ImportSongFromFilesUseCase.swift` — add `NSFileCoordinator` download wait if file is `.icloud` placeholder.
- `MusicApp/Info.plist` — add `NSUbiquitousContainers` if background download desired.
- `MusicApp/MusicApp.entitlements` — add `com.apple.developer.icloud-container-identifiers` + `com.apple.developer.icloud-services` = `CloudDocuments`.
- User-facing import button label/help text (locate in import view).

### Create
- None.

## Implementation Steps
1. Open Xcode → Signing & Capabilities → add iCloud → check "iCloud Documents".
2. Verify entitlements file gains `iCloud.{bundleID}` container.
3. Add `NSUbiquitousContainers` dict to Info.plist with `NSUbiquitousContainerIsDocumentScopePublic=YES`, name="MusicApp".
4. In `ImportSongFromFilesUseCase`, wrap copy in `NSFileCoordinator.coordinate(readingItemAt:)` to force iCloud materialization for placeholder files.
5. Add `URLResourceValues` check for `.ubiquitousItemDownloadingStatusKey`; if not downloaded, call `FileManager.startDownloadingUbiquitousItem`.
6. Update import button subtitle copy: "Import from Files or iCloud Drive".
7. Manual test matrix.

## Todo List
- [ ] Enable iCloud Documents capability
- [ ] Update entitlements file
- [ ] Add NSUbiquitousContainers to Info.plist
- [ ] Wrap file copy in NSFileCoordinator
- [ ] Add download materialization for placeholder files
- [ ] Update import UI copy
- [ ] Manual test: import .mp3 from iCloud Drive (downloaded)
- [ ] Manual test: import .mp3 from iCloud Drive (placeholder, not downloaded)
- [ ] Manual test: import from On-My-iPhone (regression)
- [ ] Build + compile clean

## Success Criteria
- iCloud Drive folder visible in document picker.
- Placeholder file imports correctly (downloads first).
- No regression on local Files import.
- Entitlement appears in build product `embedded.mobileprovision`.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Provisioning profile lacks iCloud entitlement | Medium | Build fail | Regenerate profile after capability add |
| Large iCloud file blocks UI during download | Low | UX | Show progress/spinner during NSFileCoordinator |
| User has no iCloud account | Low | Feature unavailable | Picker still shows local locations — acceptable |

## Next Steps
- Unblocks: P02 (lyrics import reuses same flow).
