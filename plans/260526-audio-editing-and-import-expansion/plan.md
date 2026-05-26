---
title: "MusicApp — Audio Editing & Import Expansion"
description: "Mở rộng app nghe nhạc offline với audio editing nâng cao (10-band EQ, speed/pitch, reverb, trim, fade) và 5 phương thức import MP3 mới (Files app deep link, AirDrop, Share Extension, URL download, iTunes File Sharing UI)."
status: draft
priority: P1
effort: 14d
branch: Master
tags: [ios, swiftui, mvi, audio, dsp, import, share-extension]
created: 2026-05-26
---

# MusicApp — Audio Editing & Import Expansion

## Goal
App hiện đã có core player + 3-band EQ + smart playlist + **Lyrics đã code nhưng chưa chạy được trong tay user** + Web Upload + Files import.

Plan này gồm 3 mảng theo thứ tự ưu tiên:

0. **Fix Lyrics pipeline** (bắt buộc làm trước) — kết nối stem matching + UX import + ellipsis menu để lyrics **thực sự** hoạt động end-to-end. Không có lý do mở rộng feature mới khi feature cũ user không chạm được.
1. **Audio Editing** — biến app thành "personal mastering tool" cho thư viện offline: 10-band EQ chuyên nghiệp, speed/pitch độc lập, reverb, trim/crop track, fade in/out, normalize loudness, save edited copy.
2. **Import Expansion** — hiện chỉ có Web Upload + Files (UIDocumentPicker). Thêm 5 đường vào: AirDrop nhận file, Share Extension (nhận từ Safari/Mail/Telegram), URL Download (paste link MP3), iTunes File Sharing tự động scan, Open-in từ Files app deep link.

## Phase Index

| # | Phase | Effort | Risk | File |
|---|-------|--------|------|------|
| **00** | **Fix Lyrics Pipeline (Make It Actually Work)** ✅ DONE | **1.5d** | **Medium** | [phase-00-fix-lyrics-pipeline.md](phase-00-fix-lyrics-pipeline.md) |
| 01 | 10-Band EQ + Preset Manager ✅ DONE | 2d | Medium | [phase-01-eq-10band-presets.md](phase-01-eq-10band-presets.md) |
| 02 | Speed / Pitch / Reverb (AVAudioUnit*) ✅ DONE | 2d | Medium | [phase-02-speed-pitch-reverb.md](phase-02-speed-pitch-reverb.md) |
| 03 | Trim / Fade / Normalize + Export ✅ DONE | 3d | **High** | [phase-03-trim-fade-export.md](phase-03-trim-fade-export.md) |
| 04 | Share Extension + AirDrop nhận file ⚠️ PARTIAL (AirDrop+OpenIn done; ShareExt deferred) | 2d | Medium | [phase-04-share-extension-airdrop.md](phase-04-share-extension-airdrop.md) |
| 05 | URL Download (paste link MP3) ✅ DONE | 1.5d | Low | [phase-05-url-download.md](phase-05-url-download.md) |
| 06 | iTunes File Sharing auto-scan + Open-in ✅ DONE (with P04) | 1d | Low | [phase-06-itunes-sharing-openin.md](phase-06-itunes-sharing-openin.md) |
| 07 | Import Hub UI + onboarding ✅ DONE | 1.5d | Low | [phase-07-import-hub-ui.md](phase-07-import-hub-ui.md) |
| 08 | QA pass + docs + journal ⏳ manual QA pending | 1d | Low | [phase-08-qa-docs.md](phase-08-qa-docs.md) |

**Tổng effort:** ~15.5 ngày dev (1 người).

## Dependency Graph
```
P00 (Lyrics fix) ──> mọi thứ khác

P01 (10-band EQ) ──┐
                   ├──> P02 (Speed/Pitch/Reverb) ──> P03 (Trim/Fade/Export)
                   │
P04 (Share Ext) ──┬┴──> P07 (Import Hub UI) ──> P08 (QA + docs)
P05 (URL DL)  ───┤
P06 (iTunes)  ───┘
```

**Tracks song song:**
- Audio editing track (P01 → P02 → P03) độc lập với Import track (P04 / P05 / P06).
- Có thể chạy 2 dev song song nếu muốn.
- P07 chỉ block khi 2 track đều xong (cần list các method để build hub UI).

## Cross-Phase Constraints
- **MVI strict:** State/Intent/Action/Reducer/ViewModel cho mọi screen mới.
- **DI:** mọi service/use case mới đăng ký trong `DIContainer+UseCases.swift` hoặc `DIContainer.swift` (Services struct).
- **File size:** <200 LOC/file. Module split theo logic concern.
- **No third-party libs** — chỉ AVFoundation + native iOS.
- **Persistence:** edits không destructive — luôn lưu bản gốc, edit produce copy mới (Phase 03 export).
- **AudioEngineProtocol mở rộng:** thêm node vào graph chain hiện tại trong `AVAudioPlayerEngineService` — KHÔNG rewrite engine.
- **EQ hiện tại 3-band → migrate sang 10-band:** giữ EQPreset enum nhưng đổi `gains: [Float]` từ 3 phần tử sang 10. Bản preset cũ user lưu cần migrate (Phase 01 viết migration UserDataDefault).

## Rollback Strategy
- **P01:** giữ `EQService` cũ behind protocol — flag `useTenBandEQ` trong AppState, default true, có thể flip false để fallback 3-band.
- **P02:** mỗi unit (Speed/Pitch/Reverb) bypass-able qua `bypass` flag trên `AVAudioUnit*`. UI có toggle.
- **P03:** export operation chạy background — fail không ảnh hưởng playback. Edit không lưu lại file gốc.
- **P04:** Share Extension là target riêng — disable trong Info.plist nếu lỗi.
- **P05:** URL download là feature optional — UI button có thể ẩn qua remote flag (UserDataDefault).
- **P06:** iTunes scan là addition, không ghi đè.

## Success Criteria
- Mọi phase merge độc lập, không regression NowPlaying / Playlist / Library.
- 10-band EQ thay được 3-band cũ, user preset cũ vẫn load (migration ok).
- Speed 0.5x–2.0x, Pitch ±12 semitones, Reverb 0–100% wet — tất cả realtime, không glitch.
- Trim + Fade export thành MP3 (hoặc M4A AAC) ghi đúng vào Documents, hiện trong Library.
- Share Extension nhận file từ Safari/Mail/Telegram → tự lưu vào Library + show notification.
- URL Download HTTPS-only, content-type validate, max 200MB, progress visible.
- Manual test matrix: iPhone 15 sim + 1 device, iOS 16/17/18.

## Tech-stack Decisions
| Component | Choice | Why |
|-----------|--------|-----|
| 10-band EQ | `AVAudioUnitEQ(numberOfBands: 10)` | Native, parametric, free CPU. ISO standard bands: 31/62/125/250/500/1k/2k/4k/8k/16k Hz. |
| Speed (no pitch shift) | `AVAudioUnitTimePitch.rate` | Time-stretch, giữ pitch. |
| Pitch (no speed shift) | `AVAudioUnitTimePitch.pitch` | Cents (1 semitone = 100 cents). |
| Reverb | `AVAudioUnitReverb` | 12 built-in presets + wetDryMix. |
| Trim / Fade export | `AVAssetExportSession` + `AVMutableAudioMix` | Native, hỗ trợ M4A (AAC). MP3 encode không có native → output M4A. |
| Normalize loudness | Pre-scan peak qua `AVAudioFile.read` → apply gain qua `AVAudioMixerNode.outputVolume` trước export | Đủ tốt cho v1 (peak normalize, không EBU R128). |
| Share Extension | `NSExtensionPrincipalClass` UIViewController + App Group | Standard iOS pattern. |
| URL Download | `URLSession.shared.download` + `URLSessionDownloadDelegate` cho progress | Native. |
| Open-in handler | `Application(_:open:options:)` trong `MusicApp.swift` + `LSItemContentTypes` Info.plist | Standard. |

## Unresolved Questions
1. **Export format:** M4A (AAC) vs giữ MP3? AVFoundation không encode MP3 native — user OK với M4A output? *Default plan: M4A, ghi rõ trong UI.*
2. **Share Extension App Group ID:** đặt là `group.com.musicapp.shared` hay match bundle prefix khác? Cần biết bundle id thực tế.
3. **URL Download whitelist:** chấp nhận mọi HTTPS hay chỉ một số domain (archive.org, dropbox direct link…)? *Default: mọi HTTPS, content-type audio/* hoặc extension check.*
4. **EQ 3→10 migration:** user nào có preset "custom" với 3-band cũ → map sang 10-band thế nào? *Đề xuất: bass 60→[31,62,125], mid 1k→[500,1k,2k], treble 14k→[8k,16k], 3 band giữa interpolate linear.*
5. **Audio editing realtime vs offline:** edits apply trong khi đang play (realtime) hay phải nhấn "preview" rồi "apply"? *Default: realtime cho Speed/Pitch/Reverb/EQ; Trim/Fade phải Export.*
