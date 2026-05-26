---
phase: 03
title: "Trim / Fade In-Out / Normalize + Export"
effort: 3d
status: todo
risk: High
---

# Phase 03 — Trim / Fade / Normalize + Export (AVAssetExportSession)

## Context Links
- Phase 02 done (Speed/Pitch/Reverb realtime).
- Existing: `MusicApp/Domain/UseCases/SongUseCases/AddSongUseCase.swift` (thêm song vào Library CoreData).
- Existing: `MusicApp/Core/DocumentFileManager.swift` (lưu file vào Documents).

## Overview
Cho phép user cắt khúc đầu/cuối (trim), thêm fade in/out, normalize loudness (peak), rồi **export** ra file mới (M4A AAC) lưu vào Library. Bản gốc không bị ghi đè.

⚠️ AVFoundation **không encode MP3 native** — output sẽ là M4A (AAC 256kbps). UI ghi rõ "Export as M4A".

## Key Insights
- `AVAssetExportSession` + `AVMutableAudioMix` cho trim + fade chuyên dụng.
- Trim: set `timeRange` trên export session.
- Fade: `AVMutableAudioMixInputParameters.setVolumeRamp(fromStartVolume:toEndVolume:timeRange:)`.
- Normalize peak: phải scan toàn file trước qua `AVAudioFile` (read buffer chunks → tìm max |sample|) → tính gain = 0.95 / peak → áp vào `setVolume` của mixInput trước khi ramp fade. (V1 dùng peak normalize đơn giản, không phải LUFS.)
- Export format: `.m4a` preset `AVAssetExportPresetAppleM4A`.
- Export là async, có progress; phải chạy background task để user navigate đi không cancel.

## Requirements
**Functional:**
- Editor screen accessed từ song long-press menu hoặc NowPlaying ellipsis: "Edit Audio".
- **Waveform view** (compact, không cần precise): scan 1 lần render 200-300 sample point.
- **Trim handles** 2 đầu, drag để chọn start/end. Hiển thị thời gian `mm:ss.s`.
- **Fade in** slider 0–10s, **Fade out** slider 0–10s.
- **Normalize toggle** (peak-based).
- **Preview button**: chạy nội bộ playback đoạn đã chọn với fade applied (không export, dùng AVAudioPlayer với `volume` ramp).
- **Save** button: chạy export, progress bar, complete → AddSongUseCase ghi vào Library với title = "{originalTitle} (Edit)".
- Background safe: app suspended export tiếp tục (UIBackgroundTask).

**Non-functional:**
- Export 4-phút song: < 15s trên iPhone 12.
- Không crash khi export trùng tên file → auto-suffix `(1)`, `(2)`.
- File <200 LOC.

## Architecture
```
Domain/UseCases/AudioEditor/
├── ScanWaveformUseCase.swift            // input URL → [Float] samples (peak per bucket)
├── ExportEditedAudioUseCase.swift       // input EditConfig → output URL
└── ComputeNormalizationGainUseCase.swift // input URL → peakGain Float

Domain/Entities/
└── AudioEditConfig.swift  // sourceURL, trimStart, trimEnd, fadeIn, fadeOut, normalize, outputTitle

Presentation/Feature/AudioEditor/
├── AudioEditorView.swift
├── AudioEditorState.swift
├── AudioEditorIntent.swift
├── AudioEditorStateAction.swift
├── AudioEditorStateReducer.swift
├── AudioEditorViewModel.swift
└── Views/
    ├── WaveformView.swift
    ├── TrimHandlesView.swift
    └── FadeControlsView.swift
```

## Related Code Files
**Modify:**
- `MusicApp/Core/Router/AppRoute.swift` — case `.audioEditor(song:)`
- `MusicApp/Core/Router/ViewFactory.swift` — factory cho AudioEditorView
- `MusicApp/Core/DI/DIContainer+UseCases.swift` — register 3 use cases
- `MusicApp/Presentation/Feature/NowPlayingScreen/...` — add menu item "Edit Audio"
- `MusicApp/Presentation/Feature/Libary/...` — context menu "Edit Audio"
- `MusicApp/Core/DocumentFileManager.swift` — helper `uniqueURL(forFilename:)`

**Create:**
- `MusicApp/Domain/Entities/AudioEditConfig.swift`
- 3 use case files trong `MusicApp/Domain/UseCases/AudioEditor/`
- 6 view + MVI files trong `MusicApp/Presentation/Feature/AudioEditor/`

## Implementation Steps
1. **`AudioEditConfig.swift`** struct với mọi tham số edit.
2. **`ScanWaveformUseCase`**: open AVAudioFile, đọc theo chunk, compute peak per bucket, return `[Float]`. Run on background queue. Cache result theo songId.
3. **`ComputeNormalizationGainUseCase`**: tương tự, tìm peak toàn file, return `0.95 / peak` (clamped 0.5–3.0).
4. **`ExportEditedAudioUseCase`**: build `AVMutableComposition`, set timeRange (trim), build `AVMutableAudioMix` với input params (volume + ramp fade in/out + base volume = normGain), tạo `AVAssetExportSession` preset M4A, async export với progress callback. Background task wrap.
5. **MVI Audio Editor**: state chứa `waveform`, `trimStart`, `trimEnd`, `fadeIn`, `fadeOut`, `normalize`, `isExporting`, `exportProgress`, `exportedSong`.
6. **WaveformView**: Canvas render từ `[Float]`, vertical bars centered.
7. **TrimHandlesView**: overlay 2 handle drag-gesture, clamp đụng vào nhau min 1s.
8. **FadeControlsView**: 2 slider + Toggle normalize.
9. **Compose AudioEditorView**: waveform + handles overlay, controls section, Preview button, Save button (button disabled khi exporting, hiện progress).
10. **Preview**: dùng existing AudioEngineProtocol seek trimStart → play → tự seek về sau trimEnd. Fade tự tay set engine.mainMixer.outputVolume ramp Timer-based.
11. **Save flow**: gọi ExportEditedAudioUseCase, nhận output URL, AddSongUseCase với title suffix, navigate back.
12. **Test export**: với 30s + 3min + 7min sample; verify M4A play được trong app; verify file size hợp lý.

## Todo List
- [ ] AudioEditConfig entity
- [ ] ScanWaveformUseCase + chunk reading
- [ ] ComputeNormalizationGainUseCase
- [ ] ExportEditedAudioUseCase + composition + mix + session
- [ ] Background task wrapping
- [ ] DI register
- [ ] AppRoute + ViewFactory
- [ ] MVI files
- [ ] WaveformView render
- [ ] TrimHandlesView gesture
- [ ] FadeControlsView
- [ ] Compose AudioEditorView
- [ ] Preview playback
- [ ] Save → add to Library flow
- [ ] Entry point from NowPlaying menu + Library context menu
- [ ] Unique filename helper
- [ ] Manual test: trim, fade, normalize, export 3 size khác nhau

## Success Criteria
- Trim chính xác, end-start ≥ 1s.
- Fade in/out audible khi play preview + export.
- Normalize peak làm file đều âm lượng (test 2 file levels khác).
- Export 4-min < 15s iPhone 12, không crash.
- File mới hiện trong Library, play được.
- Cancel export giữa chừng cleanup file dở.
- Mọi file <200 LOC.

## Risk Assessment
- **AVAssetExportSession crash on edge inputs:** WAV/FLAC import có thể fail. *Mitigation:* validate UTType.audio.compatible(with: .audio) trước; fail gracefully với alert.
- **Memory spike khi scan waveform file lớn:** stream chunk, không load whole file.
- **Background export bị OS kill:** dùng BeginBackgroundTask, fallback save partial nếu lỡ kill.
- **MP3 output không có:** UI clearly nói "Output: M4A (AAC)".
- **Concurrency Swift 6:** ExportSession callback có thể không trên main — wrap @MainActor cho state updates.

## Security Considerations
- Output ghi vào sandbox Documents/, không expose ra ngoài.
- Không có URL external trong flow này.

## Next Steps
Audio Editing track done. → Phase 04 (Share Extension + AirDrop) khởi động Import Expansion track.
