---
phase: 04
title: "Share Extension + AirDrop nhận file"
effort: 2d
status: todo
risk: Medium
---

# Phase 04 — Share Extension + AirDrop

## Overview
Cho phép user gửi file audio **vào** app từ ngoài: AirDrop, Share Sheet trong Safari/Mail/Telegram/Drive/Dropbox. Đây là đường vào nhanh nhất user mong đợi.

## Key Insights
- **AirDrop nhận file:** chỉ cần app khai báo `CFBundleDocumentTypes` + `UTExportedTypeDeclarations` trong `Info.plist` cho `public.audio`, `public.mp3`, `com.apple.m4a-audio`. Sau đó iOS tự gửi file qua `application(_:open:options:)`.
- **Share Extension:** target riêng (`UIViewController` subclass `SLComposeServiceViewController`). Cần App Group để share file giữa extension và host app (`group.<bundleId>.shared`).
- **Container:** Extension copy file vào App Group container → host app khi mở scan App Group inbox → move sang main Library.

## Requirements
**Functional:**
- AirDrop: nhận `.mp3 .m4a .wav .flac .aac`, app tự mở → import flow → toast "Imported 1 song".
- Share Extension: user trong Safari long-press link audio / file → Share Sheet hiện "MusicApp" → tap → save xong dismiss.
- Cả 2 đường vào reuse `ImportSongFromFilesUseCase`.

**Non-functional:**
- Extension memory budget thấp (24MB) — chỉ copy + queue, không decode.

## Architecture
```
ShareExtension target (new)
└── ShareViewController.swift
    └── inheritsFrom SLComposeServiceViewController
    └── didSelectPost(): loop NSItemProvider → loadFileRepresentation
        → copy to App Group inbox dir → completeRequest

Host App
└── MusicApp.swift
    └── .onOpenURL { url in handleOpenInURL(url) }
└── AppEnvironment.bootstrap()
    └── scanAppGroupInbox() — chạy on launch + on foreground
└── new: ExternalFileImportCoordinator
    └── enqueueFromOpenURL(url)
    └── enqueueFromAppGroupInbox()
    → forward to ImportSongFromFilesUseCase
```

## Related Code Files
**Modify:**
- `MusicApp/Info.plist` — `CFBundleDocumentTypes` cho audio UTType
- `MusicApp/MusicApp.swift` — `.onOpenURL` modifier
- `MusicApp/MusicApp.entitlements` — App Group capability
- `MusicApp/Core/Application/RootView.swift` + `SystemEventsHandler.swift` — foreground scan inbox
- `MusicApp/Core/DI/AppEnvironment.swift` — wire coordinator

**Create:**
- `ShareExtension/` (new Xcode target)
  - `ShareExtension/ShareViewController.swift`
  - `ShareExtension/Info.plist`
  - `ShareExtension/ShareExtension.entitlements`
- `MusicApp/Core/Application/ExternalFileImportCoordinator.swift`

## Implementation Steps
1. **Add Xcode target** "MusicAppShareExt" type Share Extension. Configure bundle id `com.<...>.MusicApp.ShareExt`.
2. **App Group**: tạo `group.com.<...>.MusicApp.shared` cho cả 2 targets. Enable trong entitlements.
3. **`ShareViewController`**: filter `NSExtensionActivationRule` chỉ accept `public.audio`. Trong `didSelectPost`, lặp `NSItemProvider`, load file rep với UTI `public.audio`, copy vào `containerURL(forSecurityApplicationGroupIdentifier:).appendingPathComponent("Inbox")`. Gọi `completeRequest`.
4. **Info.plist host app**: thêm `CFBundleDocumentTypes` với UTI audio + `LSHandlerRank Owner`.
5. **`onOpenURL` handler**: nhận URL → `ExternalFileImportCoordinator.enqueueFromOpenURL`.
6. **`ExternalFileImportCoordinator`**: scan App Group inbox dir, move file sang Documents/Music, gọi `ImportSongFromFilesUseCase` để add vào CoreData. Show toast qua AppState global event.
7. **Scan on foreground**: `SystemEventsHandler.willEnterForeground` → coordinator.scanInbox.
8. **Toast notification**: AppState publisher → RootView listen → show toast "Imported X songs".
9. **Test**: AirDrop từ MacBook 1 mp3 → app tự mở, song hiện trong Library. Share từ Safari file mp3 link → MusicApp xuất hiện trong Share Sheet → tap → save → mở app thấy song.

## Todo List
- [ ] Xcode target Share Extension
- [ ] App Group capability cả 2 target
- [ ] ShareViewController với NSItemProvider handling
- [ ] CFBundleDocumentTypes Info.plist
- [ ] onOpenURL trong MusicApp.swift
- [ ] ExternalFileImportCoordinator
- [ ] Foreground scan hook
- [ ] Toast global event
- [ ] AirDrop manual test
- [ ] Share Sheet manual test (Safari + Mail)

## Success Criteria
- AirDrop 1 file → import xong < 5s.
- Share Sheet "MusicApp" hiện trong Safari/Mail.
- Multi-select 5 file share cùng lúc → import đủ.
- Toast feedback rõ.

## Risk Assessment
- **Share Extension memory crash:** nếu user share file 100MB → load full vào memory crash. *Mitigation:* dùng `loadFileRepresentation` ghi thẳng ra disk, không `loadDataRepresentation`.
- **App Group ID phải đúng cả 2 target** — config sai = silent fail. *Mitigation:* hardcode constant trong shared `Constants.swift`.

## Security
- Validate UTType audio trong host app trước khi import (phòng trường hợp extension bỏ qua).

## Next
→ Phase 05 (URL Download).
