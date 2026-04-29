# Development Roadmap

High-level plan for MusicOffline-SwiftUI features and improvements.

## Current Status

**Latest Phase:** Phase 04 - Playlist Management Improvements ✅ Complete
**Current Version:** 1.3.0
**Last Updated:** 2026-04-29

## Phase Overview

| Phase | Focus | Status | Est. Duration |
|-------|-------|--------|-----------------|
| **Phase 01** | DI Architecture Refactor | ✅ Complete | 1 week |
| **Phase 02** | File Structure & Layers | ✅ Complete | 1 week |
| **Phase 03** | Modularization & Splitting | ✅ Complete | 1 week |
| **Phase 04** | Playlist Management | ✅ Complete | 2 weeks |
| **Phase 05** | Playback Improvements | 📋 Planned | 2 weeks |
| **Phase 06** | Feature Brainstorm | 🔮 Research | 1 week |

---

## Phase 05: Playback Flow Improvements

**Priority:** P1 | **Status:** 📋 Planned | **Depends on:** Phase 04 complete

**Target Date:** 2026-05-13 (2 weeks from Phase 04)

### Objectives

Improve audio playback experience with enhanced queue management, intelligent shuffle, and robust repeat modes.

### Requirements

#### Functional
1. **Queue Management**
   - View upcoming songs in queue (next 10 songs)
   - Jump to any song in queue
   - Clear queue
   - Save queue as playlist

2. **Shuffle Enhancement**
   - Smart shuffle (avoid playing same artist consecutively)
   - Shuffle with seeding (reproducible randomization)
   - Shuffle toggle vs. complete re-shuffle

3. **Repeat Modes**
   - None (play once, stop)
   - One (loop single song)
   - All (loop entire playlist/queue)
   - Shuffle + Repeat combinations

4. **Playback Progress**
   - Current position indicator
   - Remaining time display
   - Scrubbing timeline
   - Playback speed control (0.75x, 1x, 1.25x, 1.5x)

5. **Now Playing Context**
   - Show current playlist/album context
   - Show position in queue (3 of 50)
   - Show total duration
   - Show album artwork in full screen

#### Non-functional
- Playback state persists across app restarts
- Queue operations < 100ms
- Memory-efficient queue (no full song data duplication)
- Battery-optimized (no unnecessary processing)

### Architecture Changes

**New Use Cases:**
- `GetPlaybackQueueUseCase` — Fetch upcoming songs
- `ShufflePlaylistUseCase` — Generate smart shuffle order
- `SetPlaybackSpeedUseCase` — Change playback speed
- `SaveQueueAsPlaylistUseCase` — Persist current queue

**Modified Components:**
- `PlayerManager` — Add speed control, queue management
- `NowPlayingViewModel` — New state for queue, speed
- `NowPlayingView` — Queue preview, speed selector

**New State Properties (NowPlaying):**
```swift
struct NowPlayingState {
    var currentSong: Song?
    var upcomingQueue: [Song] = []
    var playbackSpeed: PlaybackSpeed = .normal
    var repeatMode: RepeatMode = .none
    var isShuffleEnabled: Bool = false
    var currentPosition: Double = 0
    var duration: Double = 0
}

enum PlaybackSpeed: Float {
    case slow = 0.75
    case normal = 1.0
    case fast = 1.25
    case faster = 1.5
}

enum RepeatMode {
    case none
    case one
    case all
}
```

### Implementation Steps

1. Add `playbackSpeed`, `repeatMode`, `isShuffleEnabled` to PlayerManager
2. Create `ShufflePlaylistUseCase` with smart shuffling algorithm
3. Enhance `NowPlayingState` with queue + speed properties
4. Add queue preview UI to NowPlayingView
5. Add speed selector menu to playback controls
6. Test shuffle distribution (no artist repetition)
7. Test speed control with various audio formats

### Success Criteria

- Queue view shows accurate upcoming songs
- Shuffle algorithm avoids same artist 95%+ of the time
- Speed control adjusts playback within 100ms
- Repeat modes toggle correctly
- Queue persists on app backgrounding/foregrounding

### Known Unknowns

- AVAudioEngine speed control limitations (may require resampling)
- Whether smart shuffle should consider albums too

---

## Phase 06: Feature Brainstorm & Prioritization

**Priority:** P2 | **Status:** 🔮 Research | **Depends on:** Phase 05 complete

**Target Date:** 2026-05-20 (1 week from Phase 05)

### Objectives

Evaluate and prioritize new features for future development.

### Candidate Features

#### A. Equalizer
- User-customizable EQ presets (Rock, Pop, Classical, etc.)
- Saved presets
- Manual frequency adjustment
- **Complexity:** High (DSP knowledge required)
- **Priority:** Medium
- **Effort:** 2-3 weeks

#### B. Lyrics Display
- Sync lyrics with playback
- Lyrics database integration
- Manual lyrics editing
- **Complexity:** Medium (timing synchronization)
- **Priority:** Medium
- **Effort:** 2 weeks

#### C. Social Features
- Share playlists (via link/QR)
- Collaborative playlists
- User profiles
- **Complexity:** Very High (requires backend)
- **Priority:** Low (offline-first design conflict)
- **Effort:** 4+ weeks

#### D. Smart Playlists
- Auto-generated playlists (recent, favorites, most played)
- Smart filtering (by artist, genre, year, duration)
- Playlist rules/conditions
- **Complexity:** Medium
- **Priority:** High
- **Effort:** 2 weeks

#### E. Backup & Restore
- iCloud backup (metadata only, not files)
- Encrypted local backup
- Restore from backup
- **Complexity:** Medium
- **Priority:** High
- **Effort:** 1.5 weeks

#### F. Podcast Support
- Podcast file import
- Episode tracking (played/unplayed)
- Auto-skip intros
- **Complexity:** Low-Medium
- **Priority:** Medium
- **Effort:** 1 week

#### G. Offline Sync
- Sync library across devices
- Conflict resolution
- **Complexity:** Very High
- **Priority:** Low
- **Effort:** 3+ weeks

#### H. Gesture Controls
- Swipe gestures for next/previous
- Swipe to seek
- Pinch for volume
- **Complexity:** Low
- **Priority:** Low
- **Effort:** 3 days

### Prioritization Criteria

| Criterion | Weight | Rationale |
|-----------|--------|-----------|
| User requests | 25% | Aligns with actual needs |
| Implementation complexity | 20% | Simpler = faster ROI |
| Maintenance burden | 20% | Prefer low-upkeep features |
| Alignment with vision | 20% | Offline-first design |
| Market differentiation | 15% | What makes us unique |

### Recommendation

**Phase 07 Focus (Next Quarter):**
1. **Smart Playlists** (High priority, high impact)
2. **Backup & Restore** (High priority, reliability)
3. **Gesture Controls** (Quick win, good UX)

**Defer to Future:**
- Social features (conflicts with offline design)
- Offline sync (requires architecture redesign)
- Lyrics (nice-to-have, lower demand)

---

## Completed Phases

### Phase 04: Playlist Management Improvements ✅

**Completed:** 2026-04-29

**Features Delivered:**
- Reorder songs via drag & drop
- Import audio files from Files app
- Sort playlists (name, date, count)
- Enhanced playlist validation
- Bulk delete songs

**Metrics:**
- 2 new use cases implemented
- 1 new feature module (ImportSong)
- 5 playlistDetail enhancements
- 100% test coverage for new code

### Phase 03: Modularization & Splitting ✅

**Completed:** 2026-04-28

**Focus:** Reduce file complexity
- Split large feature files into State/Intent/ViewModel/View
- Max file size reduced from 500+ LOC to ~200 LOC
- Improved code readability

### Phase 02: File Structure & Layers ✅

**Completed:** 2026-04-27

**Focus:** Clean Architecture implementation
- Created Domain, Data, Presentation layers
- Separated use cases from repositories
- Established protocol-based contracts

### Phase 01: DI Architecture Refactor ✅

**Completed:** 2026-04-26

**Focus:** Removed singleton pattern
- Replaced AppDependencies singleton with DIContainer
- Implemented environment-based injection
- Improved testability

---

## Long-Term Vision (6-12 Months)

### Quarter 2 (May - July)
- Phase 05: Playback improvements
- Phase 06: Feature brainstorm
- Phase 07: Smart playlists + backup/restore

### Quarter 3 (Aug - Oct)
- Advanced search filters
- Performance optimization
- Bug fixes & refinements

### Quarter 4 (Nov - Jan)
- Gesture controls
- Podcast support (optional)
- Year-end polish & stability

---

## Risk Assessment

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| AVAudioEngine speed control | Medium | High | Research feasibility early; have fallback |
| CoreData migration at scale | Low | High | Test with 1000+ songs before release |
| Memory with large queues | Low | Medium | Lazy-load queue items; limit cache |
| iOS version compatibility | Low | Medium | Test on iOS 15-17 devices |

### Schedule Risks

| Risk | Mitigation |
|------|-----------|
| Scope creep in Phase 05 | Use strict Definition of Done; defer nice-to-haves |
| Team availability | Cross-training; document decisions in ADRs |
| Integration bugs | Comprehensive integration tests before phase end |

---

## Metrics & Success Criteria

### Phase Completion
- All acceptance criteria met
- 100% code coverage for business logic
- Zero critical bugs at release
- Performance benchmarks pass

### Code Quality
- Max 200 LOC per file
- <5% code duplication
- 100% protocol coverage for external dependencies
- All errors domain-specific enums

### User Experience
- < 500ms for all operations
- No jank in animations
- Battery impact < 5% over baseline

---

## How to Contribute

1. **Choose a Phase:** Check roadmap for status and priorities
2. **Read Phase Plan:** Full implementation details in `plans/` directory
3. **Follow Code Standards:** Use patterns from `docs/code-standards.md`
4. **Create Feature Branch:** Use descriptive names (`feature/playlist-reorder`)
5. **Write Tests:** Target 80%+ coverage for business logic
6. **Update Docs:** Add to changelog, architecture docs
7. **Submit PR:** Include test results and performance impact

---

## Decision Log

**2026-04-29:** Deferred social features to Phase 8+. Reason: Offline-first design doesn't align with real-time sync/collaboration.

**2026-04-28:** Chose MVI pattern over Redux for state management. Reason: Simpler for team, fewer boilerplate abstractions.

**2026-04-26:** Removed AppDependencies singleton. Reason: Improved testability, follows dependency injection best practices.

---

## References

- **Architecture:** `docs/system-architecture.md`
- **Code Standards:** `docs/code-standards.md`
- **Changelog:** `docs/project-changelog.md`
- **Codebase Summary:** `docs/codebase-summary.md`
- **Phase Plans:** `plans/260428-2336-musicapp-full-refactor-and-improve/phase-XX-*.md`

---

**Last Updated:** 2026-04-29
**Next Review:** 2026-05-13 (Phase 05 kickoff)
**Maintained by:** Development Team
