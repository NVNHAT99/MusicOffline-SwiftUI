---
phase: 05
title: "URL Download (paste link MP3)"
effort: 1.5d
status: todo
risk: Low
---

# Phase 05 — URL Download

## Overview
User paste 1 URL trực tiếp `.mp3 .m4a` (vd archive.org, Dropbox direct link) → app tải về Documents/Music → import. Đường vào quan trọng cho user muốn tải nhạc free.

## Key Insights
- `URLSession.shared.downloadTask` với `URLSessionDownloadDelegate` cho progress.
- Background download: cấu hình `URLSessionConfiguration.background(withIdentifier:)` để tiếp tục khi app suspended.
- Content-Type check: chấp nhận `audio/*` hoặc extension `.mp3|.m4a|.wav|.aac|.flac|.ogg` (case-insensitive).
- HTTPS-only (App Transport Security default).
- Max size 200MB (cấu hình constant).

## Requirements
**Functional:**
- "Download from URL" sheet: TextField paste URL, button "Download".
- Validate: scheme https, host non-empty, response Content-Type audio/* hoặc URL có extension audio.
- Progress bar inline (download bytes / total).
- Cancel button.
- On finish → ImportSongFromFilesUseCase.
- Lưu URL gốc vào Song metadata? *(v1: không, chỉ giữ tên file từ URL last component).*

**Non-functional:**
- Background-safe (continues khi app vào background).
- Multiple downloads queued, max 3 concurrent.

## Architecture
```
Domain/UseCases/Import/
└── DownloadAudioFromURLUseCase.swift
    └── execute(url: URL, onProgress: (Double) -> Void) async throws -> URL

Core/
└── BackgroundDownloadService.swift
    └── URLSession bg config
    └── delegate handles progress + completion
    └── publishes events qua Combine subject

Presentation/Feature/Import/UrlDownload/
├── UrlDownloadSheetView.swift
├── UrlDownloadState.swift
├── UrlDownloadIntent.swift
├── UrlDownloadStateAction.swift
├── UrlDownloadStateReducer.swift
└── UrlDownloadViewModel.swift
```

## Related Code Files
**Modify:**
- `MusicApp/Core/DI/DIContainer.swift` — register service
- `MusicApp/Core/DI/DIContainer+UseCases.swift` — download use case
- `MusicApp/Core/Router/AppRoute.swift` — `.urlDownloadSheet`
- `MusicApp/Core/Router/ViewFactory.swift` — factory
- Entry point: add button trong existing ImportSong screen hoặc Settings → "Download from URL"

**Create:**
- `MusicApp/Core/BackgroundDownloadService.swift`
- `MusicApp/Domain/UseCases/Import/DownloadAudioFromURLUseCase.swift`
- 6 MVI files trong `Presentation/Feature/Import/UrlDownload/`

## Implementation Steps
1. **`BackgroundDownloadService`**: singleton, URLSession bg config, delegate impl, Combine publisher events `(taskId, .progress(Double) | .completed(URL) | .failed(Error))`.
2. **`DownloadAudioFromURLUseCase`**: validate URL → start task → bridge progress callback → khi complete, move temp file → call AddSongUseCase.
3. **MVI sheet**: TextField bind, Validate button enable khi URL parsable, progress bar khi downloading, error alert.
4. **Background completion handler** trong `MusicApp.swift` AppDelegate adapter (SwiftUI: `UIApplicationDelegateAdaptor`).
5. **Entry point**: button "Download from URL" trong existing AddSongs screen + Settings.
6. **Test**: thử URL archive.org direct mp3, Dropbox direct link, fake URL không phải audio (expect reject), URL có redirect.

## Todo List
- [ ] BackgroundDownloadService với URLSession bg
- [ ] DownloadAudioFromURLUseCase
- [ ] URL validation logic
- [ ] MVI sheet
- [ ] Progress UI + Cancel
- [ ] Background completion handler wire
- [ ] DI register
- [ ] Entry point UI
- [ ] Manual test 3 source

## Success Criteria
- Paste archive.org URL → tải về < 30s cho file 5MB → hiện Library.
- Background: lock screen vẫn tải xong.
- URL không hợp lệ → error message rõ.
- Cancel hủy task, dọn file dở.

## Risk Assessment
- **CORS/redirect chains:** site redirect 302 → URLSession tự follow nhưng có thể mất content-type. *Mitigation:* check cả URL extension fallback.
- **Memory cho large file:** dùng downloadTask (file-based) chứ không dataTask.
- **Pháp lý:** user tải nhạc bản quyền? Không phải vấn đề app — app chỉ là tool. Disclaimer trong sheet.

## Security
- HTTPS-only check.
- Whitelist file size 200MB max.
- Validate Content-Type response trước khi save.
- Không exec, không tải arbitrary file extension.

## Next
→ Phase 06 (iTunes Sharing + Open-in).
