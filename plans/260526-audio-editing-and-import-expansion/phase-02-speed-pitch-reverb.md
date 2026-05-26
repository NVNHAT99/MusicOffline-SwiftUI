---
phase: 02
title: "Speed / Pitch / Reverb Realtime Effects"
effort: 2d
status: todo
risk: Medium
---

# Phase 02 — Speed / Pitch / Reverb (AVAudioUnitTimePitch + Reverb)

## Context Links
- Phase 01 done (10-band EQ).
- `MusicApp/Core/AudioEngineService.swift` — graph: `playerNode → eqNode → mainMixer`
- Sau phase này graph thành: `playerNode → timePitchNode → reverbNode → eqNode → mainMixer`

## Overview
Bổ sung 3 hiệu ứng realtime audiophile mong:
- **Speed:** 0.5x – 2.0x (time stretch, không đổi pitch — karaoke/practice mode).
- **Pitch:** ±12 semitones (transpose, không đổi tempo).
- **Reverb:** 12 preset (smallRoom, mediumHall, cathedral…) + wet/dry 0–100%.

Tất cả realtime, bypass-able độc lập.

## Key Insights
- `AVAudioUnitTimePitch` gộp cả 2: `rate` (0.25–4.0) cho speed, `pitch` (-2400 to +2400 cents) cho pitch.
- `AVAudioUnitReverb` có 12 preset enum + `wetDryMix` (0–100).
- Insert node vào graph: phải `engine.stop()` → attach + reconnect → `engine.start()` lại. Hoặc tạo node ngay từ khi build graph với bypass = true ⇒ không cần stop engine.
- ⇒ **Strategy:** attach toàn bộ node ngay từ build, bypass khi user không enable. Tránh stop/start engine runtime (gây pop sound).

## Requirements
**Functional:**
- "Audio Effects" section trong Equalizer/NowPlaying:
  - Speed slider 0.5–2.0, step 0.05, default 1.0, label "x"
  - Pitch slider -12 to +12 semitones, step 0.5, default 0, label "st"
  - Reverb: picker 12 preset + wetDryMix slider 0–100
- Mỗi effect có toggle on/off riêng (bypass).
- "Reset all effects" button.

**Non-functional:**
- Realtime, không lag, không pop khi toggle.
- Settings persist across app restart (UserDefaults).
- File <200 LOC.

## Architecture
```
AudioEngineService graph mới:
playerNode → timePitchNode → reverbNode → eqNode → mainMixerNode

DIContainer.Services
└── audioEffectsService: AudioEffectsServiceProtocol
    └── timePitchNode: AVAudioUnitTimePitch
    └── reverbNode: AVAudioUnitReverb
    └── setSpeed(_ rate: Float)
    └── setPitch(_ semitones: Float)  // convert to cents *100
    └── setReverbPreset(_ preset: AVAudioUnitReverbPreset)
    └── setReverbWetDry(_ mix: Float)
    └── setSpeedBypass(_ on: Bool)
    └── setPitchBypass(_ on: Bool)  // ⚠️ bypass cả timePitchNode khi cả speed+pitch tắt
    └── setReverbBypass(_ on: Bool)
    └── persistSettings()
    └── restoreSettings()
```

⚠️ TimePitch là 1 node — speed+pitch chia sẻ bypass. Logic: bypass node khi BOTH speed = 1.0 AND pitch = 0.

## Related Code Files
**Modify:**
- `MusicApp/Core/AudioEngineService.swift` — graph chain thêm timePitch + reverb node
- `MusicApp/Core/DI/DIContainer.swift` — register `audioEffectsService`
- `MusicApp/Presentation/Feature/Equalizer/EqualizerView.swift` — thêm tab/section "Effects"
- `MusicApp/Presentation/Feature/Equalizer/EqualizerState.swift` — speed/pitch/reverb fields
- `MusicApp/Presentation/Feature/Equalizer/EqualizerIntent.swift` — `.setSpeed`, `.setPitch`, `.setReverbPreset`, `.setReverbMix`, `.toggleEffectBypass(...)`, `.resetAllEffects`
- `MusicApp/Presentation/Feature/Equalizer/EqualizerStateReducer.swift`
- `MusicApp/Presentation/Feature/Equalizer/EqualizerViewModel.swift`
- `MusicApp/Core/UserDataDefault.swift` — keys cho settings persistence

**Create:**
- `MusicApp/Core/Player/AudioEffectsService.swift` (`AudioEffectsServiceProtocol` + impl)
- `MusicApp/Domain/Entities/ReverbPreset.swift` — Codable wrapper quanh `AVAudioUnitReverbPreset` enum
- `MusicApp/Presentation/Feature/Equalizer/Views/SpeedSliderView.swift`
- `MusicApp/Presentation/Feature/Equalizer/Views/PitchSliderView.swift`
- `MusicApp/Presentation/Feature/Equalizer/Views/ReverbControlView.swift`
- `MusicApp/Presentation/Feature/Equalizer/Views/EffectsSectionView.swift` (gộp 3 sub view)

## Implementation Steps
1. **`AudioEffectsService.swift`**: protocol + impl, owns timePitchNode + reverbNode. Init bypass = true.
2. **Refactor `AudioEngineService.swift` `buildGraph()`**: attach + connect theo chain mới. Inject `AudioEffectsServiceProtocol` qua init.
3. **`ReverbPreset.swift`**: enum mirror `AVAudioUnitReverbPreset`, displayName, Codable, default `mediumHall`.
4. **DI register**: `Services.audioEffectsService` + inject vào audio engine init.
5. **Settings persistence**: trong `AudioEffectsService` — load on init từ UserDefaults, save on every change (debounced 0.3s nếu cần).
6. **MVI updates**: state thêm fields, intent/action/reducer xử lý.
7. **Build UI components**: SpeedSliderView/PitchSliderView/ReverbControlView — mỗi file <100 LOC.
8. **Layout Equalizer**: dùng `Picker` segmented "EQ | Effects" để chuyển tab, hoặc cuộn dài.
9. **Manual test**: chỉnh speed 0.7 nghe rock, pitch +5 nghe ballad, reverb cathedral nghe piano. Verify no pop, persist sau restart.

## Todo List
- [ ] `AudioEffectsService` (protocol + impl, <200 LOC)
- [ ] Refactor graph chain trong AudioEngineService
- [ ] `ReverbPreset` entity
- [ ] DI register
- [ ] Settings persistence (load/save UserDefaults)
- [ ] MVI updates (state/intent/action/reducer/VM)
- [ ] UI sub-views (Speed/Pitch/Reverb)
- [ ] Effects section layout trong EqualizerView
- [ ] Reset-all button + per-effect bypass
- [ ] Manual smoke test

## Success Criteria
- Speed 0.5–2.0 hoạt động, pitch giữ nguyên.
- Pitch ±12st hoạt động, tempo giữ nguyên.
- Reverb thay preset realtime, wetDry slider mượt.
- Toggle bypass không pop.
- Settings persist.
- 4+ files mới, mỗi file <200 LOC.

## Risk Assessment
- **Pop sound khi attach node:** *Mitigation:* attach từ đầu graph build, không runtime.
- **CPU spike khi reverb cathedral:** đo trên iPhone 8 sim — nếu >40% CPU thì hạ default preset xuống mediumRoom.
- **AVAudioUnitTimePitch latency:** có ~ 32–64 samples buffer extra → có thể desync nhẹ với progress slider. *Mitigation:* không bù trừ ở v1, user không cảm nhận được.

## Security Considerations
N/A.

## Next Steps
→ Phase 03 (Trim/Fade/Normalize Export).
