---
phase: 00
title: "Fix Lyrics Pipeline (Make It Actually Work)"
effort: 1.5d
status: done
risk: Medium
completed: 2026-05-26
notes: |
  - Core fix shipped: stem matching (normalize + index), .lrc picker, Attach/Paste/Remove menu, activeLyricIndex intro fix.
  - DI fix: NowPlaying now shares single LyricsRepository (was 4 separate instances → stale index).
  - 11/11 unit tests pass. Build green.
  - Manual QA pending on physical device.
---

# Phase 00 — Fix Lyrics Pipeline End-to-End

## Why First
User feedback: "Lyrics phase chạy lên chưa hoạt động". Code có đủ (`LyricsRepository`, `ParseLrcContentUseCase`, MVI wiring trong NowPlaying, `LyricsView`) nhưng pipeline đứt ở 1+ chỗ thực tế. **Phải fix trước khi mở rộng feature mới** — kéo lê bug = ngăn người dùng tin tưởng.

## Suspected Root Causes (cần verify từng cái)

### RC1 — Stem mismatch (cao xác suất nhất)
- `LyricsRepository` lưu theo **stem = url.deletingPathExtension().lastPathComponent** lúc import `.lrc`.
- `NowPlayingViewModel.updateFromPlayerState` đọc stem từ `playerState.currentSong.urlStr` → `URL(fileURLWithPath: urlStr).deletingPathExtension().lastPathComponent`.
- Nếu file mp3 import qua web upload bị sanitize tên (vd `My Song.mp3` → `My_Song.mp3`) nhưng user import `My Song.lrc` → stem `My Song` ≠ `My_Song` → load = nil → state.lyrics empty → "No lyrics available".
- Cũng có thể có dấu Vietnamese, casing khác (`song.mp3` vs `Song.lrc`).

### RC2 — `urlStr` không phải absolute path
- Trong Song entity, `urlStr` có thể là **relative** (`Music/abc.mp3`) hoặc just **filename**. `URL(fileURLWithPath: urlStr).deletingPathExtension().lastPathComponent` vẫn cho ra stem đúng nếu là plain filename, nhưng cần verify.

### RC3 — User không biết cách import .lrc
- Hiện chỉ có Files document picker — user phải mò chọn file `.lrc`. Picker `UTType` filter có cho phép `.lrc` không?
- Verify: `ImportSongView.swift` supportedTypes có chứa `UTType.text` hoặc UTType cụ thể cho `.lrc`?

### RC4 — Toggle button vô hình / dễ miss
- Icon `text.quote` nhỏ trong song info row, mau không thấy. Không có badge "Has lyrics".

### RC5 — Active line index timing off
- `activeLyricIndex(for:in:)` trả về `nil` nếu time < first timestamp → line đầu không highlight. UX kỳ.

## Investigation Steps (Day 1 sáng)
1. Đọc `ImportSongView.swift` UTType filter — kiểm `.lrc` có pass picker không.
2. Đọc `AddSongUseCase` + `SongMapper` — `urlStr` lưu format gì.
3. Build app, import 1 mp3 + 1 lrc cùng stem → check Documents/Lyrics có file chưa, play song → check `lastLyricsSongStem` và `state.lyrics`.
4. Test với tên có dấu space + Vietnamese.
5. Log toàn pipeline với `Logger.debug` ở 4 điểm: import save, import result, VM stem resolved, fetchLyrics result.

## Fix Plan (Day 1 chiều + Day 2)

### Fix-1: Robust stem matching
- **`LyricsRepository.load(stem:)`** mở rộng: thử exact match → thử case-insensitive → thử normalized (strip diacritics + replace space/_/-).
- Lưu thêm 1 index map `Documents/Lyrics/_index.json` `[normalizedStem: actualStem]` để lookup nhanh không scan dir.
- Khi save, ghi cả normalized vào index.

### Fix-2: Manual "Attach lyrics" flow
- Trong NowPlaying ellipsis menu: **"Add Lyrics for This Song"** → mở document picker filter `.lrc` + `.txt` → save vào repo với stem = song's actual stem.
- Cũng có **"Paste Lyrics"** sheet: TextEditor multiline, user paste LRC content → save trực tiếp.
- Có **"Remove Lyrics"** menu item.

### Fix-3: Document picker accept .lrc
- Thêm `UTType.text` + `UTType(filenameExtension: "lrc")` vào ImportSongView supportedTypes nếu chưa có.
- Verify import .lrc xong có UI feedback ("Saved lyrics for X songs").

### Fix-4: Lyrics indicator + better toggle
- Trong `songInfo` row của NowPlaying: nếu `state.lyrics.isEmpty` → toggle button mờ + disabled, tooltip "No lyrics — tap menu to add".
- Khi có lyrics → button sáng + nhẹ nhàng "pulse" 1 lần khi song mới load → user thấy có.
- Thêm 1 entry trong song long-press context menu ở Library: "Has lyrics ✓" / "Add lyrics".

### Fix-5: Active index khi time < first timestamp
- Trả về `0` thay vì `nil` nếu lyrics non-empty và `time < lines[0].timestamp` → line đầu highlight nhẹ "upcoming".

### Fix-6: Telemetry / debug
- Đặt key DEBUG flag `lyricsDebugLog` — log mọi lookup: `[Lyrics] song stem='abc def' → repo lookup → norm='abcdef' → hit='abc def.lrc' → 42 lines`.

## Related Code Files
**Modify:**
- `MusicApp/Data/Repositories/LyricsRepository.swift` — normalized matching + index map
- `MusicApp/Domain/Repositories/LyricsRepositoryProtocol.swift` — có thể thêm `loadWithFallbacks(stem:)`
- `MusicApp/Presentation/Feature/ImportSong/ImportSongView.swift` — `UTType` cho `.lrc`
- `MusicApp/Presentation/Feature/NowPlayingScreen/Views/NowPlayingFullPlayerView.swift` — disabled state cho button, ellipsis menu
- `MusicApp/Presentation/Feature/NowPlayingScreen/NowPlayingIntent.swift` — `.addLyricsFile(URL)`, `.pasteLyrics(String)`, `.removeLyrics`
- `MusicApp/Presentation/Feature/NowPlayingScreen/NowPlayingViewModel.swift` — handle new intents
- `MusicApp/Presentation/Feature/NowPlayingScreen/NowPlayingStateReducer.swift` — `activeLyricIndex` trả `0` khi `time < first`
- `MusicApp/Presentation/Feature/Libary/...` — context menu "Add Lyrics"

**Create:**
- `MusicApp/Presentation/Feature/NowPlayingScreen/Views/PasteLyricsSheetView.swift`
- `MusicApp/Domain/UseCases/Lyrics/AttachLyricsToSongUseCase.swift` — wrap repo save với normalize logic
- `MusicApp/Domain/UseCases/Lyrics/RemoveLyricsUseCase.swift`
- `MusicApp/MusicAppTests/LyricsStemMatchingTests.swift` — unit test normalize matching

## Implementation Steps
1. **Investigation** (1-2h): chạy app, repro miss-match thực tế, log để xác định chính xác stem nào sai.
2. **`LyricsRepository` refactor**: thêm `normalize(_ s: String)` helper (lowercase + strip diacritics + collapse spaces/underscores/dashes). Build in-memory index khi init (scan dir). `load(stem:)` fallback chain: exact → normalized → nil.
3. **Index persistence**: `_index.json` lưu map, regenerate nếu file thiếu.
4. **Unit tests** normalize + lookup: 8-10 case bao gồm Vietnamese, space, case.
5. **UTType picker fix**.
6. **Attach / Paste / Remove lyrics use case + UI**: sheet TextEditor cho paste, doc picker cho attach.
7. **Ellipsis menu** trong NowPlaying — list items: Add Lyrics File, Paste Lyrics, Remove Lyrics, Edit Audio (sau này phase 03 reuse).
8. **Library context menu**: long-press song row → "Add Lyrics".
9. **Indicator UX**: disabled button + pulse animation khi vừa load lyrics có.
10. **activeLyricIndex fix**: return `0` if non-empty và time < first.
11. **Manual QA matrix**: 4 case — exact stem, Vietnamese, case mismatch, no lyrics.

## Todo List
- [ ] Investigation log session — xác định RC chính xác
- [ ] `LyricsRepository.load` normalized fallback
- [ ] `_index.json` build + persist
- [ ] Unit tests stem matching (8+ case)
- [ ] UTType `.lrc` cho document picker
- [ ] Paste Lyrics sheet
- [ ] Attach Lyrics flow (doc picker)
- [ ] Remove Lyrics flow
- [ ] Use cases (Attach + Remove)
- [ ] NowPlaying ellipsis menu
- [ ] Library context menu entry
- [ ] Button disabled state + pulse
- [ ] activeLyricIndex fix
- [ ] Manual QA 4-case matrix

## Success Criteria
- Import `My Song.mp3` + `My Song.lrc` qua doc picker → play song → lyrics tự load + scroll.
- Import mp3 trước, sau đó từ NowPlaying menu Attach `.lrc` → lyrics load ngay.
- Tên có dấu Vietnamese / casing khác / space ↔ underscore — vẫn match.
- Paste lyrics inline hoạt động.
- Toggle button disabled rõ ràng khi không có lyrics.
- Test unit pass.

## Risk Assessment
- **Normalize false-positive:** 2 song stem khác nhau normalize ra cùng key → load nhầm. *Mitigation:* exact match ưu tiên; nếu normalized duy nhất 1 match thì OK; nếu 2+ match → return nil + log warning.
- **TextEditor paste UX trên iOS 15:** test trên iOS 15 sim, fallback nếu cần.

## Security Considerations
- File `.lrc` text only, không exec — safe.
- Paste sheet không upload đâu cả — local only.

## Next Steps
→ Phase 01 (10-band EQ).
