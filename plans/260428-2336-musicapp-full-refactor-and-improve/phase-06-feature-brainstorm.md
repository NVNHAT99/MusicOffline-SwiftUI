# Phase 06 - Feature Brainstorm + Gemini Research

**Priority:** P2 | **Status:** ⬜ Todo | **Depends on:** Phase 05 complete  
**⚠️ Clear context before starting this phase**

## Context Links
- Skills to activate: `brainstorm`, `ai-multimodal` (Gemini), `docs-seeker`
- Apple Developer docs for feasibility cross-check
- SPM repository lookup for any third-party libs

## Overview

After completing the refactor + core improvements, brainstorm new feature ideas, research technical feasibility with Gemini, cross-check Apple APIs/guidelines, and identify SPM packages where needed.

## Process

### Step 1 — Brainstorm (use `/ck:brainstorm`)
Generate feature ideas across these categories:

| Category | Ideas to explore |
|----------|-----------------|
| Discovery | Smart auto-playlist by mood/BPM, Recently played history screen |
| Social | Share playlist as file export (m3u/json) |
| Audio | Equalizer (EQ) with presets, pitch/speed control |
| Import | iCloud Drive sync, AirDrop receive, Shortcuts integration |
| UI/UX | Lyrics display (local .lrc file), waveform visualization, album grid view |
| Widget | Lock screen widget (iOS 16+), home screen Now Playing widget |
| Accessibility | VoiceOver improvements, Dynamic Type |
| Sleep | Enhanced sleep timer with fade out |

### Step 2 — Gemini Research (use `/ck:ai-multimodal` with Gemini)
For each shortlisted feature, research:
1. Which Apple framework/API to use
2. iOS version requirement
3. Complexity estimate (S/M/L/XL)
4. Any SPM package needed (with exact GitHub repo URL)

### Step 3 — Apple Cross-Check
Verify against:
- App Store Review Guidelines (no features that violate policy)
- iOS 15+ compatibility (project minimum target)
- Privacy requirements (microphone, camera permissions if needed)

## Feature Research Template

For each feature, capture:
```
Feature: [name]
Apple API: [framework + class]
Min iOS: [version]
Complexity: [S/M/L/XL]
SPM package: [repo URL or "none"]
Feasibility: [High/Medium/Low]
Notes: [caveats]
```

## Candidate Features (Pre-brainstorm list)

### High Priority Candidates

**1. Audio Equalizer**
- API: `AVAudioEngine` + `AVAudioUnitEQ`
- Note: Current app uses `AVAudioPlayer`, not `AVAudioEngine` — would require switching audio engine
- SPM: None (native framework)
- Complexity: XL (requires audio engine rewrite)

**2. Lock Screen / Home Screen Widget (WidgetKit)**
- API: `WidgetKit` (iOS 14+), `AppIntents` for interactive controls (iOS 17+)
- Share state: via App Group + shared UserDefaults
- SPM: None
- Complexity: M

**3. Lyrics Display (.lrc file)**
- API: `FileManager` + custom LRC parser
- Import .lrc alongside audio file
- SPM: Could use `LyricsX/LyricsCore` on GitHub if available
- Complexity: M

**4. Waveform Visualization**
- API: `AVAssetReader` + `vDSP` for audio samples, `Canvas` for drawing
- SPM: `AudioWaveform` — check https://github.com/dmrschmidt/DSWaveformImage
- Complexity: L

**5. iCloud Drive Sync**
- API: `NSFileProviderExtension` or `UIDocumentPickerViewController` with iCloud scope
- Min iOS: 15 ✅
- SPM: None
- Complexity: L

**6. Shortcut / AppIntents**
- API: `AppIntents` (iOS 16+) — note: project targets iOS 15, need conditional
- SPM: None
- Complexity: M

**7. Speed/Pitch Control**
- API: `AVAudioPlayer.rate` (speed, built-in ✅), `AVAudioUnitTimePitch` for pitch without speed change
- Note: `AVAudioPlayer.rate` works but requires `enableRate = true` before play
- SPM: None
- Complexity: S for speed, M for independent pitch

**8. AirDrop Receive**
- API: Register UTI types in Info.plist, handle via `application(_:open:options:)` — already done for web upload
- Complexity: S (just register audio UTI types)
- SPM: None

## Output Format

After research, produce a ranked feature table:
```
| Rank | Feature | iOS Min | Complexity | SPM? | Recommendation |
|------|---------|---------|------------|------|----------------|
```

Then create a new plan file `phase-07-feature-roadmap.md` with the top 3-5 approved features and their implementation plans.

## Todo List
- [ ] Activate `brainstorm` skill — generate feature ideas with trade-off analysis
- [ ] Activate `ai-multimodal` (Gemini) — research each candidate feature
- [ ] Cross-check shortlist against Apple guidelines + iOS 15 min target
- [ ] For each feature needing SPM: find exact GitHub repo, verify last commit < 2 years, check Swift 5.5+ support
- [ ] Produce ranked feature table
- [ ] Create `phase-07-feature-roadmap.md` for top 3-5 approved features

## Success Criteria
- Ranked feature table produced with feasibility assessment
- At least 3 features fully researched with Apple API + SPM details
- `phase-07-feature-roadmap.md` created with actionable implementation plans for top features

## Notes
- EQ feature is XL complexity (requires AVAudioEngine migration) — likely Phase 8+
- Widget is best bang-for-buck (visible, native, M complexity)
- Speed control is easiest quick win (S complexity, `AVAudioPlayer.rate`)
- AirDrop receive is also quick win (S, just UTI registration)
