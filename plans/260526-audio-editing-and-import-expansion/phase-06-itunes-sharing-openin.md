---
phase: 06
title: "iTunes File Sharing auto-scan + Open-in deep link"
effort: 1d
status: todo
risk: Low
---

# Phase 06 — iTunes File Sharing auto-scan + Open-in

## Overview
Hai phương thức nhỏ nhưng đáng có:
1. **iTunes File Sharing:** user kéo file vào app qua Finder/iTunes → file nằm trong Documents/ → app tự scan và import.
2. **Open-in deep link** từ Files app: user trong Files app long-press file mp3 → "Open in MusicApp" → app import.

(2) phần lớn đã có nhờ Phase 04 `CFBundleDocumentTypes`, nhưng phase này verify + đảm bảo UX hoàn chỉnh.

## Key Insights
- **iTunes File Sharing:** thêm `UIFileSharingEnabled = YES` và `LSSupportsOpeningDocumentsInPlace = YES` vào Info.plist. Files user thả vào sẽ nằm root Documents/.
- App scan Documents/ root khi launch + foreground → file nào audio chưa import → import.
- **Open-in:** đã có `onOpenURL` từ Phase 04 → reuse coordinator.

## Requirements
**Functional:**
- Khi user thả 5 file mp3 vào Documents qua Finder → mở app → 5 song tự xuất hiện trong Library.
- Trong Files app: long-press `.mp3` → menu "Share" → "MusicApp" → app mở + import. Hoặc "Open in MusicApp" qua quick action.
- Avoid duplicate: nếu file đã trong Documents/Music/ với cùng filename → skip.

**Non-functional:**
- Scan nhanh: 100 file < 2s.
- Không block UI.

## Architecture
```
Core/Application/
└── DocumentsRootScanner.swift
    └── scanAndImportLooseFiles() async
    └── filters: audio extensions only, skip subdirs (Music/, Lyrics/), skip already-imported

Existing ExternalFileImportCoordinator (Phase 04)
└── reuse for both scan + open-in routes
```

## Related Code Files
**Modify:**
- `MusicApp/Info.plist` — `UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`
- `MusicApp/Core/Application/SystemEventsHandler.swift` — call scanner on foreground
- `MusicApp/Core/Application/ExternalFileImportCoordinator.swift` (từ phase 04) — wire scanner

**Create:**
- `MusicApp/Core/Application/DocumentsRootScanner.swift`

## Implementation Steps
1. **Info.plist:** thêm 2 keys.
2. **`DocumentsRootScanner.swift`**: list Documents/ root, filter file extension audio, exclude items trong `Music/` và `Lyrics/`. So sánh với CoreData Song.urlStr → bỏ trùng. Trả về URLs cần import.
3. **Wire vào foreground** trong `SystemEventsHandler`: gọi coordinator.scanRootAndImport on `willEnterForeground` (debounce 2s).
4. **Avoid race với App Group inbox scan** (Phase 04): chạy tuần tự, App Group inbox xong → Documents root scan.
5. **Test:**
   - macOS Finder: kéo 3 mp3 vào MusicApp container.
   - iOS Files app: copy mp3 vào MusicApp folder.
   - Long-press file trong Files → "Share" → MusicApp.
   - Verify song hiện, không duplicate khi scan lại.

## Todo List
- [ ] Info.plist 2 keys
- [ ] DocumentsRootScanner impl
- [ ] Duplicate check vs CoreData
- [ ] Wire foreground scan
- [ ] Order: inbox scan → root scan
- [ ] Manual test 3 đường vào

## Success Criteria
- Finder thả file → mở app → import.
- Files app "Open in MusicApp" → import.
- Mở app nhiều lần không tạo duplicate.

## Risk Assessment
- **Slow scan với 1000+ file:** *Mitigation:* async + chỉ scan root depth-1, không recurse vào subdirs đã quản lý.
- **User file lẫn lộn:** nếu user để random PDF trong Documents → scanner bỏ qua nhờ extension filter.

## Security
- Extension whitelist (audio only).
- Không touch subdirs Music/ và Lyrics/ vì là area của app.

## Next
→ Phase 07 (Import Hub UI).
