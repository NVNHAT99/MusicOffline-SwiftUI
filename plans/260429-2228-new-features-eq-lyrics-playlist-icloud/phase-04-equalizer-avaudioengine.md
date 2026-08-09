# Phase 04 — Equalizer + AVAudioEngine Migration

## Context Links
- `MusicApp/Data/Service/AVAudioPlayerEngineService.swift`
- `MusicApp/Domain/Service/AudioEngineProtocol.swift`
- `MusicApp/Presentation/Manager/PlayerManager.swift`
- `MusicApp/Presentation/Feature/Setting/*`
- `MusicApp/Navigation/AppRoute.swift`

## Overview
- **Priority:** P2
- **Status:** ✅ complete
- **Effort:** 5 days (3d migration, 1d EQ UI, 1d test)
- **Risk:** **High** — touches every playback path.

Migrate audio backend from `AVAudioPlayer` to `AVAudioEngine + AVAudioPlayerNode + AVAudioUnitEQ` to enable runtime EQ. Preserve ALL existing behavior: seek, play/pause, shuffle/repeat, background audio, NowPlayingInfo (lock screen / control center), interruption handling, route change.

## Requirements
### Functional
- 3-band parametric EQ: Bass 60Hz, Mid 1kHz, Treble 14kHz; gain range -12dB..+12dB.
- 6 presets: Flat, Bass Boost, Pop, Rock, Classical, Jazz.
- Persist active preset + custom slider state to UserDefaults.
- Settings → General → "Equalizer" row → routes to `EqualizerView`.
- `EqualizerView`: 3 sliders + horizontal preset chip row.
- Selecting preset updates sliders; moving slider switches to "Custom".
- EQ effective immediately on currently-playing track.

### Non-Functional
- No audible glitch when toggling presets mid-playback.
- Playback latency unchanged (< few ms).
- Background audio session continues working (`.playback` category, mixWithOthers off).
- Lock-screen NowPlayingInfo + remote commands still functional.

## Architecture

### Audio Graph
```
AVAudioFile → AVAudioPlayerNode → AVAudioUnitEQ(3 bands) → engine.mainMixerNode → output
```

### Components
- `AVAudioPlayerEngineService` (rewrite): conforms to existing `AudioEngineProtocol`. Internally manages `AVAudioEngine`, `AVAudioPlayerNode`, `AVAudioUnitEQ`, current `AVAudioFile`, current frame position for seek.
- `EQService` (singleton, injected): owns reference to the EQ node + persisted preset; exposes `applyPreset(EQPreset)`, `setBandGain(index:dB:)`, `currentGains: [Float]`.
- `EQPreset` enum: cases + static `gains` table.
- `EqualizerView` MVI: state holds gains/preset, intents change them, reducer updates state, view-model calls `EQService`.

### Seek Strategy (critical)
`AVAudioPlayerNode` has no native seek. Implement via:
1. Compute target frame = `time * sampleRate`.
2. Call `playerNode.stop()`.
3. `playerNode.scheduleSegment(file, startingFrame:targetFrame, frameCount:remaining, at:nil)`.
4. `playerNode.play()`.
5. Track `seekOffsetFrames` to compute correct `currentTime` (since `playerNode.currentTime` is relative to schedule).

### Time Calc
```swift
var currentTime: TimeInterval {
    guard let nodeTime = playerNode.lastRenderTime,
          let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
        return Double(seekOffsetFrames) / sampleRate
    }
    return Double(seekOffsetFrames + playerTime.sampleTime) / sampleRate
}
```

### Engine Lifecycle
- Start engine lazily on first `prepare(url:)`.
- Restart engine on AVAudioSession `.interruptionTypeEnded` with `.shouldResume`.
- On route change `.oldDeviceUnavailable` → pause.
- On `.mediaServicesWereReset` → tear down + rebuild graph.

### Presets Table (gains for [bass, mid, treble])
- Flat: `[0, 0, 0]`
- Bass Boost: `[+6, 0, 0]`
- Pop: `[+2, +4, +2]`
- Rock: `[+5, -2, +4]`
- Classical: `[+3, 0, +3]`
- Jazz: `[+3, +2, +3]`

## Related Code Files
### Create
- `MusicApp/Domain/Entity/EQPreset.swift`
- `MusicApp/Domain/Service/EQServiceProtocol.swift`
- `MusicApp/Data/Service/EQService.swift`
- `MusicApp/Presentation/Feature/Equalizer/EqualizerView.swift`
- `MusicApp/Presentation/Feature/Equalizer/State/EqualizerState.swift`
- `MusicApp/Presentation/Feature/Equalizer/State/EqualizerIntent.swift`
- `MusicApp/Presentation/Feature/Equalizer/State/EqualizerStateAction.swift`
- `MusicApp/Presentation/Feature/Equalizer/State/EqualizerStateReducer.swift`
- `MusicApp/Presentation/Feature/Equalizer/EqualizerViewModel.swift`

### Modify (high impact)
- `MusicApp/Data/Service/AVAudioPlayerEngineService.swift` — **major rewrite** to AVAudioEngine.
- `MusicApp/Domain/Service/AudioEngineProtocol.swift` — verify protocol covers needs (likely no changes; if seek/duration semantics shift, document).
- `MusicApp/Presentation/Manager/PlayerManager.swift` — adjust if it relied on AVAudioPlayer-specific API; route EQService injection.
- `MusicApp/Navigation/AppRoute.swift` — add `.equalizer`.
- `MusicApp/Presentation/Feature/Setting/State/SettingViewIntent.swift` — `openEqualizer`.
- `MusicApp/Presentation/Feature/Setting/SettingView.swift` — add row.
- `MusicApp/DI/DIContainer*.swift` — register EQService singleton; ensure same EQ node referenced by audio engine service AND EQService (shared instance via DI).

## Implementation Steps

### Stage A — Engine Migration (3d)
1. Create EQ node placeholder + `EQService` skeleton (returns shared `AVAudioUnitEQ` with 3 bands configured).
2. In `AVAudioPlayerEngineService`, replace AVAudioPlayer with engine graph: attach `playerNode`, attach `eqService.eqNode`, connect player → eq → mainMixer.
3. Reimplement `prepare(url:)`: open `AVAudioFile`, schedule from frame 0, stop engine before reschedule.
4. Reimplement `play()`, `pause()`, `stop()` against `playerNode` and `engine.start()/pause()`.
5. Reimplement `seek(to:)` using `scheduleSegment` strategy above.
6. Reimplement `currentTime`/`duration` using sample-time math.
7. Wire AVAudioSession setup (category .playback, activate on play, deactivate on stop with `.notifyOthersOnDeactivation`).
8. Wire interruption + route-change notifications.
9. Verify NowPlayingInfo still updated (likely from PlayerManager — confirm time/rate values still correct).
10. Verify background audio works (Capabilities → Background Modes → Audio).

### Stage B — EQ Service (0.5d)
11. Configure 3 bands on init: type `.parametric`, freq 60/1000/14000, bandwidth ~1.0 octave, gain 0.
12. `applyPreset(_:)` — set 3 band gains; persist preset rawValue + gains to UserDefaults.
13. `setBandGain(index:dB:)` — update node + mark preset as `.custom`.
14. On app launch, read persisted state, apply to node.

### Stage C — UI (1d)
15. Build `EqualizerView` MVI: 3 vertical sliders (-12..+12), preset chip row.
16. Slider change → intent → service → state.
17. Preset chip tap → service.applyPreset → state.
18. Add row to `SettingView`; wire AppRoute.

### Stage D — Test & Harden (0.5d)
19. Manual test matrix below.
20. Fix regressions.

## Todo List
### Engine Migration
- [ ] Add EQService skeleton (shared EQ node)
- [ ] Rewrite AVAudioPlayerEngineService with engine graph
- [ ] Implement prepare/play/pause/stop
- [ ] Implement seek via scheduleSegment
- [ ] Implement currentTime/duration via sample-time
- [ ] Wire AVAudioSession lifecycle
- [ ] Handle interruption notifications
- [ ] Handle route change notifications
- [ ] Handle mediaServicesReset
- [ ] Verify NowPlayingInfo updates
- [ ] Verify background audio capability

### EQ
- [ ] EQPreset enum + gains table
- [ ] EQService implementation
- [ ] Persist/restore from UserDefaults
- [ ] EqualizerView UI (sliders + chips)
- [ ] EqualizerView MVI files
- [ ] Wire AppRoute.equalizer
- [ ] Add Setting row
- [ ] DIContainer registration

### Test Matrix
- [ ] Play song → audible
- [ ] Pause/resume mid-track
- [ ] Seek forward/backward
- [ ] Skip next/prev preserves shuffle/repeat
- [ ] Background play (lock screen)
- [ ] Lock screen play/pause/seek/skip
- [ ] Phone call interruption → resume
- [ ] Headphone unplug → auto-pause
- [ ] AirPlay route change
- [ ] App backgrounded for >5min → still plays
- [ ] EQ preset toggle live
- [ ] EQ slider change live
- [ ] EQ persists across app restart
- [ ] CarPlay (if supported)
- [ ] Crash-free under repeated seek/skip stress

## Success Criteria
- All test matrix items pass.
- No audible artifact when changing EQ.
- Seek precision within 100ms of target.
- App resumes correctly after interruption + route change.
- NowPlayingInfo reflects accurate time/rate on lock screen.

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Seek implementation drifts time | High | UX | Track seekOffsetFrames meticulously; unit-test math |
| Background audio breaks | Medium | **High** | Verify Background Modes; check `engine.start()` not called from BG |
| Lock-screen controls break | Medium | High | Keep MPRemoteCommandCenter wiring untouched; verify time/rate in NowPlayingInfo |
| Engine fails to start after interruption | Medium | High | Listen `.interruptionEnded` with shouldResume; restart engine before player |
| Memory leak from retained file/buffer | Low | Medium | Nil out file on stop; profile with Instruments |
| Format mismatch (44.1kHz vs 48kHz mix) | Medium | Crash | Use file.processingFormat for connect; engine handles SRC |
| EQ node reset on engine restart | Medium | UX | EQService holds reference; reattach on engine rebuild |
| Regression in shuffle/repeat | Medium | High | Keep PlayerManager logic intact; only swap underlying service |

## Security Considerations
- None new; same file access model.

## Rollback
- Keep prior `AVAudioPlayer`-based service on a branch tag.
- DIContainer can swap `AudioEngineProtocol` binding back if critical regression.
- Disable Settings → Equalizer entry to neutralize EQ UI without reverting engine.

## Next Steps
- After ship: monitor crash rates, audio session errors.
- Future: 5/10 band EQ, reverb effect, gapless playback (now feasible with AVAudioEngine).
