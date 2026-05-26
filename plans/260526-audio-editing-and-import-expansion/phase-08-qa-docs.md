---
phase: 08
title: "QA pass + docs + journal"
effort: 1d
status: todo
risk: Low
---

# Phase 08 — Final QA, Documentation, Journal

## Overview
Sau khi 7 phase trước merge, làm 1 pass tổng:
- Manual QA matrix 30+ cases.
- Update `docs/codebase-summary.md`, `docs/system-architecture.md`, `docs/development-roadmap.md`, `docs/project-changelog.md`.
- Write journal entry vào `docs/journals/`.

## QA Matrix (manual)

### Lyrics (P00)
- [ ] Exact stem match
- [ ] Vietnamese diacritics
- [ ] Casing mismatch
- [ ] Space ↔ underscore
- [ ] Paste lyrics inline
- [ ] Remove lyrics
- [ ] Toggle button disabled state when empty
- [ ] activeLyricIndex when time < first

### EQ 10-band (P01)
- [ ] All 10 slider realtime
- [ ] 6 built-in preset apply
- [ ] Save custom preset
- [ ] Load custom preset post-restart
- [ ] Migrate v1 (3-band) → v2 (10-band)
- [ ] A/B bypass

### Effects (P02)
- [ ] Speed 0.5x audible
- [ ] Pitch +5st audible, tempo same
- [ ] Reverb cathedral wet 50%
- [ ] Bypass each independently
- [ ] Persist post-restart

### Audio Editor Export (P03)
- [ ] Trim 30s file
- [ ] Trim 4-min file
- [ ] Fade in 5s + fade out 5s
- [ ] Normalize quiet file
- [ ] Cancel export mid-way
- [ ] Background export survives backgrounding

### Share Ext + AirDrop (P04)
- [ ] AirDrop từ Mac 1 file mp3
- [ ] Share Sheet trong Safari
- [ ] Share Sheet trong Mail
- [ ] Multi-file share 5 file

### URL Download (P05)
- [ ] archive.org direct mp3
- [ ] Dropbox direct link
- [ ] Invalid URL rejected
- [ ] Background download
- [ ] Cancel mid-download

### iTunes Sharing + Open-in (P06)
- [ ] Finder drag 3 file
- [ ] Files app "Open in MusicApp"
- [ ] No duplicate on rescan

### Import Hub (P07)
- [ ] First-launch routes to Hub
- [ ] All 6 method tap actions
- [ ] Tutorial sections render

### Regression
- [ ] Playback existing song
- [ ] Create playlist
- [ ] Smart playlist
- [ ] Background audio
- [ ] Sleep timer

## Docs Updates
- `docs/codebase-summary.md`: thêm section "Audio Effects Chain", "Import Methods", "Lyrics System". List files mới + responsibility.
- `docs/system-architecture.md`: update audio engine diagram (graph chain với timePitch + reverb), import flow diagram (6 entry → coordinator → use case).
- `docs/development-roadmap.md`: mark Phase 00-08 complete với date.
- `docs/project-changelog.md`: entry "v?.?.0 — Audio Editing + Import Expansion" liệt kê 8 phase features.

## Journal
- `docs/journals/2026-MM-DD-audio-editing-import-expansion.md`: write learnings:
  - Lyrics fix root cause analysis
  - AVAudioEngine graph reconfigure pitfalls
  - AVAssetExportSession edge cases
  - Share Extension memory budget surprises
  - Decision rationale: M4A vs MP3 output, peak vs LUFS normalize

## Todo List
- [ ] Manual QA matrix run (toàn bộ)
- [ ] Fix critical bug nếu QA tìm thấy
- [ ] Update 4 docs files
- [ ] Write journal entry
- [ ] Tag release `v2.0.0-audio-editing-import`
- [ ] Final PR review checklist

## Success Criteria
- ≥ 90% QA case pass (fail < 3 case minor).
- Docs cập nhật phản ánh đúng codebase.
- Journal capture được lessons-learned.

## Risk Assessment
- **QA tìm bug critical:** *Mitigation:* dành 0.5d buffer fix nhanh trong phase này.

## Next
→ Plan complete. Đề xuất phase tiếp theo (không trong plan này): CarPlay, AirPlay 2, lossless toggle, podcast support.
