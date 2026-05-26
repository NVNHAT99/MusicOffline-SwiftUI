---
phase: 01
title: "10-Band EQ + Preset Manager"
effort: 2d
status: todo
risk: Medium
---

# Phase 01 — 10-Band Parametric EQ + Preset Manager

## Context Links
- `MusicApp/Core/AudioEngineService.swift` (graph chain hiện có `playerNode → eqNode → mainMixer`)
- `MusicApp/Domain/Entities/EQPreset.swift` (enum hiện 3-band, gains: [Float] length 3)
- `MusicApp/Presentation/Feature/Equalizer/*` (đã có UI MVI cho 3-band)
- `MusicApp/Core/DI/DIContainer.swift` (Services struct chứa EQService)
- Prior phase: `plans/260429-2228-new-features-eq-lyrics-playlist-icloud/phase-04-equalizer-avaudioengine.md`

## Overview
Hiện app dùng 3 band fixed (60Hz/1kHz/14kHz). User pro/audiophile mong 10 band ISO chuẩn để chỉnh chi tiết hơn. Phase này:
- Mở rộng `EQService` lên 10 band parametric.
- Migrate `EQPreset` từ `[Float]` length 3 → length 10.
- Migrate user data (UserDataDefault) — preset custom cũ map sang 10 band.
- Thêm "Preset Manager": user lưu custom preset với tên (Save/Load/Delete/Rename).
- UI redesign: 10 vertical sliders với labels Hz, +/- 12dB range.

## Key Insights
- `AVAudioUnitEQ(numberOfBands: 10)` — mỗi band có `frequency`, `bandwidth`, `gain`, `bypass`, `filterType`.
- Filter type: `.parametric` cho 10 mid bands, `.lowShelf` cho band 1 (31Hz), `.highShelf` cho band 10 (16kHz).
- ISO frequencies: 31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000 Hz.
- Bandwidth (Q) khoảng 1.0 octave là sweet spot cho music (không quá sharp, không quá broad).
- Preset persistence: JSON-encode array `[UserEQPreset]` vào UserDefaults key `user_eq_presets_v2`.

## Requirements
**Functional:**
- 10 band slider control, drag realtime apply gain.
- 6 built-in preset (Flat/Bass/Pop/Rock/Classical/Jazz) — values redesign cho 10 band.
- Custom preset CRUD: Save (with name), Load, Rename, Delete.
- "Reset" button → all bands về 0 dB.
- A/B compare: long-press toggle bypass entire EQ để so sánh.
- Migrate user data: nếu phát hiện key cũ `user_eq_preset_v1` (3-band) → map qua 10-band → ghi key mới → xoá key cũ.

**Non-functional:**
- Realtime, no audio glitch khi drag slider.
- File <200 LOC mỗi file.
- Compatible với existing AudioEngineService graph.

## Architecture
```
DIContainer.Services
└── eqService: EQServiceProtocol  // 10-band
    └── eqNode: AVAudioUnitEQ(numberOfBands: 10)
    └── setGain(band: Int, gain: Float)
    └── apply(preset: EQPreset | UserEQPreset)
    └── currentGains: [Float] (length 10)

DIContainer.UseCases
├── savePresetUseCase: SaveUserEQPresetUseCase
├── loadPresetsUseCase: LoadUserEQPresetsUseCase
├── deletePresetUseCase: DeleteUserEQPresetUseCase
└── migrateEQPresetUseCase: MigrateEQPresetV1ToV2UseCase  // chạy 1 lần khi app boot

Domain/Entities/
├── EQPreset.swift              // refactor: gains: [Float] length 10
└── UserEQPreset.swift          // new: id, name, gains, createdAt
```

## Related Code Files
**Modify:**
- `MusicApp/Domain/Entities/EQPreset.swift` — gains length 3 → 10, redesign preset values
- `MusicApp/Core/Player/EQService.swift` (hoặc trong AudioEngineService) — 10-band setup
- `MusicApp/Presentation/Feature/Equalizer/EqualizerView.swift` — 10 sliders horizontal scrollable
- `MusicApp/Presentation/Feature/Equalizer/EqualizerState.swift` — `gains: [Float]` length 10, `userPresets: [UserEQPreset]`
- `MusicApp/Presentation/Feature/Equalizer/EqualizerIntent.swift` — thêm `.savePreset`, `.loadPreset`, `.deletePreset`, `.renamePreset`, `.toggleBypass`
- `MusicApp/Presentation/Feature/Equalizer/EqualizerStateReducer.swift` — handle new intents
- `MusicApp/Presentation/Feature/Equalizer/EqualizerViewModel.swift` — wire use cases
- `MusicApp/Core/DI/DIContainer.swift` — register new use cases
- `MusicApp/Core/DI/DIContainer+UseCases.swift` — factory cho user preset use cases
- `MusicApp/Core/UserDataDefault.swift` — keys mới

**Create:**
- `MusicApp/Domain/Entities/UserEQPreset.swift`
- `MusicApp/Domain/UseCases/Equalizer/SaveUserEQPresetUseCase.swift`
- `MusicApp/Domain/UseCases/Equalizer/LoadUserEQPresetsUseCase.swift`
- `MusicApp/Domain/UseCases/Equalizer/DeleteUserEQPresetUseCase.swift`
- `MusicApp/Domain/UseCases/Equalizer/MigrateEQPresetV1ToV2UseCase.swift`
- `MusicApp/Presentation/Feature/Equalizer/Views/EQBandSliderView.swift` — 1 slider per band
- `MusicApp/Presentation/Feature/Equalizer/Views/PresetPickerSheetView.swift` — save/load sheet

**No delete** — refactor in place.

## Implementation Steps
1. **Update `EQPreset.swift`**: gains length 10, redesign values cho 6 preset built-in (research các DAW có giá trị reference).
2. **Refactor EQ setup trong `AudioEngineService.swift`** (hoặc tách `EQService.swift` riêng nếu chưa có): `AVAudioUnitEQ(numberOfBands: 10)`, set filterType + frequency cho 10 band.
3. **`UserEQPreset.swift`**: struct Codable, Identifiable.
4. **Use cases**: Save/Load/Delete/Migrate — đọc/ghi UserDefaults key `user_eq_presets_v2`. Migration đọc key cũ nếu có, map gains, ghi key mới, xoá key cũ.
5. **Wire migration run-once** trong `AppEnvironment.bootstrap()` (sau khi DI init).
6. **Update Equalizer MVI**: state thêm `gains: [Float]`, `userPresets: [UserEQPreset]`, `isBypassed: Bool`. Intent + Action + Reducer xử lý các action mới.
7. **Redesign `EqualizerView.swift`**: ScrollView horizontal chứa 10 `EQBandSliderView`. Header thêm preset picker button (mở sheet). Long-press EQ icon → toggle bypass.
8. **`PresetPickerSheetView`**: list built-in + user presets, action save (with TextField name), rename, delete.
9. **Test manual**: load preset, save custom, verify migration từ v1 (cài app cũ → upgrade), check no glitch khi drag.

## Todo List
- [ ] Refactor `EQPreset.swift` length 10 + 6 preset values
- [ ] EQ node 10-band setup trong audio engine
- [ ] `UserEQPreset` entity
- [ ] 4 use cases (Save/Load/Delete/Migrate)
- [ ] Wire migration vào AppEnvironment bootstrap
- [ ] MVI updates (State/Intent/Action/Reducer/VM)
- [ ] `EQBandSliderView` component (<200 LOC)
- [ ] `PresetPickerSheetView` sheet
- [ ] Redesign `EqualizerView` horizontal scroll
- [ ] Toggle bypass A/B compare
- [ ] Manual smoke test + verify v1→v2 migration

## Success Criteria
- 10 band điều chỉnh realtime, không glitch.
- Built-in preset apply tức thì.
- User save custom preset, app restart vẫn còn.
- App cũ với 3-band custom preset → upgrade → preset hiện trong list, gains phân bổ hợp lý.
- File size mọi file <200 LOC.

## Risk Assessment
- **Migration data loss:** nếu logic map 3→10 sai, custom preset cũ mất chất. *Mitigation:* unit test migration với 3-4 sample gain set.
- **Audio glitch khi reconfigure EQ:** thay đổi numberOfBands của AVAudioUnitEQ runtime không support — phải khởi tạo node mới. *Mitigation:* tạo node 10-band ngay từ đầu, không re-create.
- **UI cramped:** 10 slider trên 1 màn iPhone nhỏ. *Mitigation:* horizontal scroll với snap, hoặc 2-row layout (5+5).

## Security Considerations
N/A — pure local audio config.

## Next Steps
→ Phase 02 (Speed/Pitch/Reverb) — chèn thêm node vào graph chain.
