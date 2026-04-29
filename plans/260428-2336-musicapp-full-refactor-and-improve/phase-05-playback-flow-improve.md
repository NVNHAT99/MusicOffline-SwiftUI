# Phase 05 - Improve Playback Flow

**Priority:** P1 | **Status:** ✅ Complete | **Depends on:** Phase 03 complete  
**⚠️ Clear context before starting this phase**

## Context Links
- Current: `MusicApp/Core/PlayerManager.swift`
- Current: `MusicApp/Core/AudioEngineService.swift`
- Current: `MusicApp/Utilities/ProgressTimerService.swift`
- Current: `MusicApp/Presentation/Feature/NowPlayingScreen/NowPlayingView.swift`
- Current: `MusicApp/Presentation/Feature/NowPlayingScreen/NowPlayingState.swift`
- Current: `MusicApp/Presentation/Feature/NowPlayingScreen/NowPlayingIntent.swift`
- Current: `MusicApp/Commons/CustomViews/CustomSliderView.swift`

## Overview

Improve the playback experience for 4 key areas:

1. **Play/Pause** — ensure state correctly reflects audio engine, handle edge cases (empty playlist, deleted song file)
2. **Shuffle** — proper Fisher-Yates shuffle, don't replay current song, smart re-shuffle when playlist changes
3. **Repeat modes** — none / repeat-all / repeat-one — all 3 modes visually distinct and correct
4. **Seek by drag** — `CustomSliderView` drag should: pause timer during drag, seek audio on release (not during drag), show live time during drag

**Current issues identified:**
- `loadAndPlay(song:)` calls `progressTimerService.start(interval: 1, from: 0)` but doesn't account for seek position — seek then play from 0
- `NowPlayingState.isDraging` exists but need to verify seek is only committed on `DragGesture.onEnded` not `onChanged`
- `progressTimerService.seek(to:)` immediately sends tick but `PlayerManager.seek(to:)` calls `engine.seek()` — need to ensure timer and engine are in sync
- Shuffle order not regenerated when songs are added/removed from current playlist
- `handleSongFinished()`: `repeatMode == .none` falls to `await next()` which does nothing if at last song — correct but UI doesn't visually reset to "stopped" state
- `PlayerManager.play(_ playlistId:, songs:, songPlay:)` rebuilds full playlist each call — expensive if called frequently

## Requirements

### Functional

1. **Play/Pause**
   - Tapping play on a song already playing in NowPlaying: no state corruption
   - Empty playlist → graceful no-op with no crash
   - Song file missing/deleted → show error toast, skip to next
   - Background audio continues when screen locks (already configured via AVAudioSession)

2. **Shuffle**
   - `toggleShuffle()` when enabled: immediately reshuffle; current song stays at position 0 of shuffle order
   - `toggleShuffle()` when disabled: restore linear order with current song at its natural index
   - Playlist modified (song added/removed): regenerate shuffle order automatically
   - Shuffle state persists across app restarts (save to UserDefaults)

3. **Repeat modes** (cycle: none → all → one)
   - `none`: stop after last song, progress bar stays at end
   - `all`: wrap around to first song
   - `one`: immediately replay current song
   - Visual: 3 distinct icon states in NowPlayingView (already partially done)

4. **Seek**
   - During drag: timer paused, slider shows live dragged value, time label updates
   - On release: `engine.seek(to: value)` called, `progressTimerService.seek(to: value)` called, timer resumes
   - Seeking to 0 then play: starts from beginning
   - `currentTime` in state always matches engine position within ±1s

### Non-functional
- Seek drag gesture: 60fps smooth, no UI stutter
- State update latency: < 50ms from engine event to UI

## Architecture

### Seek flow (target)
```
CustomSliderView.DragGesture.onChange →
  NowPlayingIntent.seekDragging(Double)   [new intent] →
  ViewModel: state.isDragging = true, state.currentTime = value (visual only)

CustomSliderView.DragGesture.onEnded →
  NowPlayingIntent.seekTo(Double)         [existing] →
  ViewModel → playerManager.seek(to: value) →
    engine.seek(to: value)
    progressTimerService.seek(to: value)
    state.isDragging = false
```

### RepeatMode cycle
```swift
// In NowPlayingViewModel
case .changeRepeatMode:
    let modes: [RepeatMode] = [.none, .all, .one]
    let current = playerManager.state.repeatMode
    let next = modes[(modes.firstIndex(of: current)! + 1) % modes.count]
    await playerManager.setRepeatMode(next)
```

### Shuffle persistence
```swift
// In PlayerManager
func toggleShuffle() async {
    let newState = !state.shuffleEnabled
    state.shuffleEnabled = newState
    UserDefaults.standard.set(newState, forKey: "shuffleEnabled")
    if newState {
        await regenerateShuffleOrder(anchoringAt: currentIndex)
    }
}
```

## Related Code Files

**Modify:**
- `MusicApp/Core/PlayerManager.swift` — fix seek sync, shuffle persistence, error handling for missing files
- `MusicApp/Core/AudioEngineService.swift` — add `currentTime: TimeInterval` getter from AVAudioPlayer
- `MusicApp/Utilities/ProgressTimerService.swift` — add `pause()/resume()` during seek (already exists ✅)
- `MusicApp/Presentation/Feature/NowPlayingScreen/NowPlayingIntent.swift` — add `.seekDragging(Double)`
- `MusicApp/Presentation/Feature/NowPlayingScreen/NowPlayingState.swift` — verify isDragging usage
- `MusicApp/Presentation/Feature/NowPlayingScreen/NowPlayingViewModel.swift` — handle seekDragging intent
- `MusicApp/Presentation/Feature/NowPlayingScreen/NowPlayingStateReducer.swift` — reduce seekDragging
- `MusicApp/Commons/CustomViews/CustomSliderView.swift` — confirm onChanged vs onEnded dispatch

## Implementation Steps

1. **Audit `CustomSliderView.swift`**: Confirm it calls completion handler on `DragGesture.onEnded` only. If `.onChange` also calls it, split into two callbacks: `onDragging: (Double) -> Void` and `onCommit: (Double) -> Void`

2. **Add `seekDragging` intent**: In `NowPlayingIntent.swift`, add `.seekDragging(Double)`. In `NowPlayingViewModel`, handle by updating `state.currentTime` and `state.isDragging = true` without calling `playerManager.seek`. In `NowPlayingStateReducer`, reduce with `.setCurrentTime`.

3. **Fix `PlayerManager.seek(to:)`**: Currently only calls `engine.seek(to:)`. Add `progressTimerService.seek(to: duration)` call. Add pause/resume of progress timer during seek drag.

4. **Add `currentTime` to `AVAudioPlayerEngineService`**: Expose `player?.currentTime` as a readable property so PlayerManager can sync state.

5. **Fix shuffle persistence**: Save `shuffleEnabled` to `UserDefaults` in `toggleShuffle()`. Load on init. Regenerate shuffle order on toggle-on, anchoring current song.

6. **Fix shuffle regeneration on playlist change**: In `reloadPlaylist(id:)`, if shuffle is enabled, call `regenerateShuffleOrder(anchoringAt: currentIndex)` after updating `self.playlist`.

7. **Fix "stopped" UI state**: When `repeatMode == .none` and last song finishes, set `state.currentSong` to remain set (don't nil it) but `state.isPlaying = false` and reset `state.currentTime = 0`. NowPlayingView shows paused state at song start.

8. **Add missing file error handling**: In `loadAndPlay(song:)`, catch file-not-found and publish an error event. NowPlayingView subscribes to show toast and PlayerManager auto-advances to next.

9. **Build + test all playback scenarios**: play, pause, seek, shuffle on/off, repeat none/all/one, end of playlist

## Todo List
- [x] Audit `CustomSliderView.swift` — confirm onEnded-only dispatch
- [x] Add `seekDragging` intent + reducer action
- [x] Fix `NowPlayingViewModel` — handle seekDragging (visual-only, no engine call)
- [x] Fix `PlayerManager.seek` — sync progressTimerService
- [x] Add `currentTime` getter to `AVAudioPlayerEngineService`
- [x] Fix shuffle: persist to UserDefaults, regenerate on toggle and playlist change
- [x] Fix stopped-state UI when repeatMode == .none and playlist ends
- [x] Add missing-file error handling in `loadAndPlay`
- [x] Test: play/pause/seek/shuffle/repeat all modes
- [x] Build verify

## Success Criteria
- Seek drag: slider tracks finger, time label updates; on release audio jumps to correct position
- Shuffle on: current song stays, next songs are randomized; persists after app restart
- Repeat one: song restarts immediately on finish
- Repeat all: wraps to first song after last
- Repeat none: stops cleanly at end of playlist, UI shows paused at beginning
- No crash when song file is missing

## Risk Assessment
- **Medium** — `AVAudioPlayer.seek` (via `currentTime` setter) is synchronous but may have slight delay; ensure timer and engine are aligned
- **Low** — Repeat mode cycling is pure logic, no framework risk
- **Mitigation**: Test seek on a long track (5+ min) to verify timer/engine sync
