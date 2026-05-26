---
phase: 07
title: "Import Hub UI + onboarding"
effort: 1.5d
status: todo
risk: Low
---

# Phase 07 — Import Hub UI + Onboarding

## Overview
Gom 6 phương thức import (Web Upload, Files Picker, AirDrop, Share Extension, URL Download, iTunes Sharing) vào **1 màn hình duy nhất** — "Add Music Hub". Hiện tại entry points rải rác Setting + AddNewSongs + Library. Hub UI: 1 grid hoặc list các method với icon, mô tả ngắn, action.

## Requirements
**Functional:**
- 1 màn Hub access từ Library tab "+" button hoặc Setting → "Add Music".
- 6 row, mỗi row có icon + title + subtitle:
  - **Pick from Files** — "Browse iCloud Drive, Dropbox, local files"
  - **Web Upload (WiFi)** — "Upload from browser, no cable"
  - **Download from URL** — "Paste a link to download MP3"
  - **AirDrop & Share Sheet** — "Send from another device" (info-only, không action — UX hint)
  - **iTunes Sharing** — "Drag-drop in Finder" (info-only)
  - **Show Tutorial** — link đến GuideTransferView mở rộng (xem tất cả 6 phương pháp)
- First launch: nếu Library trống → tự navigate tới Hub.

**Non-functional:**
- 1 file Hub View < 200 LOC.

## Architecture
```
Presentation/Feature/ImportHub/
├── ImportHubView.swift
├── ImportHubState.swift  (minimal — chỉ navigation flags)
├── ImportHubIntent.swift
└── ImportHubViewModel.swift  (orchestrate router calls)

Reuse existing routes:
- ImportSong (files picker)
- WebTransfer screen
- UrlDownload sheet (Phase 05)
- GuideTransferView (extended)
```

## Related Code Files
**Modify:**
- `MusicApp/Core/Router/AppRoute.swift` — `.importHub`
- `MusicApp/Core/Router/ViewFactory.swift` — factory
- `MusicApp/Presentation/Feature/Libary/...` — "+" button → route to importHub
- `MusicApp/Presentation/Feature/Setting/...` — "Add Music" menu entry → importHub
- `MusicApp/Presentation/Feature/GuideTransferView/...` — extend với 6 method tutorial sections

**Create:**
- 4 MVI files trong `Presentation/Feature/ImportHub/`
- `Presentation/Feature/ImportHub/Views/ImportMethodRowView.swift`

## Implementation Steps
1. **MVI Hub**: state có flag `hasShownOnboarding: Bool` (persist UserDefaults).
2. **`ImportMethodRowView`**: icon + title + subtitle + chevron, tap action.
3. **Compose `ImportHubView`**: List 6 row. 4 row có action route, 2 row info-only mở alert.
4. **First-launch onboarding**: trong `MainTabView` hoặc `RootView`, on appear, nếu CoreData Song.count == 0 và `!hasShownOnboarding` → push importHub. Set flag.
5. **Extend `GuideTransferView`**: thêm 4 section mới (URL Download, AirDrop, Share Sheet, iTunes Sharing) với screenshot illustration đơn giản.
6. **Wire entry points**: Library "+" + Settings "Add Music" cùng route tới importHub.
7. **Test:** lần đầu open app (clear data) → tự đi tới Hub. Tap từng method → route đúng. Setting → tới Hub.

## Todo List
- [ ] MVI Hub
- [ ] ImportMethodRowView
- [ ] Hub layout 6 row
- [ ] Route registration
- [ ] First-launch onboarding logic
- [ ] Extend GuideTransferView 4 section mới
- [ ] Library + Setting entry points
- [ ] Manual test all 6 entry actions

## Success Criteria
- 1 màn Hub gom tất cả method, user không lạc đường.
- First-launch UX rõ.
- Tutorial đầy đủ.

## Risk Assessment
- **Onboarding loop:** nếu user vào Hub mà tap exit không import gì, lần sau lại push Hub. *Mitigation:* set flag ngay khi push Hub lần đầu, không cần user thực sự import.

## Security
N/A.

## Next
→ Phase 08 (QA + Docs).
