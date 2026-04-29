# Project Overview & Product Development Requirements (PDR)

## Executive Summary

**MusicOffline-SwiftUI** is a modern offline music player for iOS that empowers users to store, organize, and play their music collection locally without cloud dependency. The app combines essential music player features with powerful playlist management and file import capabilities.

**Vision:** Provide a lightweight, privacy-respecting alternative to cloud-based music services for users who want full control over their music library.

---

## Project Context

### Background

The project began as a feature-rich music player built with SwiftUI but lacked architectural cohesion. Recent refactoring phases (01-04) have established clean architecture patterns, modularized the codebase, and added advanced playlist features.

### Current State (Phase 04)

- **Architecture:** Clean Architecture + MVVM with MVI state management
- **Code Quality:** Protocol-oriented, testable, modularized
- **Features:** Core player, playlists, web upload, file import
- **Status:** Production-ready for core features

### Target Audience

- Music enthusiasts who own large personal libraries
- Privacy-conscious users avoiding cloud music services
- Users in offline-heavy environments (travel, rural areas)
- Power users wanting fine-grained playlist control

### Market Position

Unique aspects:
- 100% offline operation (no cloud, no subscriptions)
- Local file ownership (drag files in, they're yours)
- Advanced playlist management (reorder, import, sort)
- Privacy-first design

---

## Product Requirements

### Functional Requirements

#### 1. Music Playback (MVP - Complete)

| Requirement | Status | Notes |
|-------------|--------|-------|
| Play/pause control | ✅ Complete | AVPlayer-based |
| Next/previous track | ✅ Complete | Queue-based |
| Seek within track | ✅ Complete | Timeline scrubbing |
| Volume control | ✅ Complete | System volume integration |
| Shuffle mode | ✅ Complete | Basic shuffle; Phase 05 adds smart shuffle |
| Repeat modes | ✅ Complete | None, one, all |
| Background playback | ✅ Complete | Audio background mode enabled |
| Lock screen controls | ✅ Complete | NowPlayingInfoService integration |
| Control center | ✅ Complete | System integration |

#### 2. Library Management (MVP - Complete)

| Requirement | Status | Notes |
|-------------|--------|-------|
| View all songs | ✅ Complete | Paginated list view |
| Search songs | ✅ Complete | Title + artist search |
| Browse by artist | ✅ Complete | Artist grouping |
| Browse by album | ✅ Complete | Album sorting |
| View metadata | ✅ Complete | Title, artist, album, duration |
| Album artwork | ✅ Complete | Cached display |
| Song count | ✅ Complete | Library stats |

#### 3. Playlist Management (Phase 04 - Complete)

| Requirement | Status | Notes |
|-------------|--------|-------|
| Create playlist | ✅ Complete | With validation (1-50 chars) |
| List playlists | ✅ Complete | With sort options (name, date, count) |
| Add songs to playlist | ✅ Complete | Multi-select from library |
| Remove songs | ✅ Complete | Swipe-to-delete |
| Reorder songs | ✅ Complete | Drag & drop within playlist |
| Rename playlist | ✅ Complete | Edit mode |
| Delete playlist | ✅ Complete | With confirmation |
| Bulk delete | ✅ Complete | Multi-select + delete |
| Import songs | ✅ Complete | From iOS Files app (Phase 04) |

#### 4. File Management (MVP/Phase 04 - Complete)

| Requirement | Status | Notes |
|-------------|--------|-------|
| WiFi file upload | ✅ Complete | Via web server (GCDWebServer) |
| File import from Files | ✅ Complete | UIDocumentPicker (Phase 04) |
| Supported formats | ✅ Complete | mp3, m4a, wav, flac, aac, ogg |
| Metadata extraction | ✅ Complete | AVAsset-based |
| Album artwork extraction | ✅ Complete | Automatic display |
| Duplicate detection | ✅ Complete | Filename-based hashing |

#### 5. User Interface (MVP - Complete, Phase 04 - Enhanced)

| Requirement | Status | Notes |
|-------------|--------|-------|
| Tab navigation | ✅ Complete | Home, Library, Settings |
| Now playing screen | ✅ Complete | Full-screen player interface |
| Mini player | ✅ Complete | Bottom bar during browsing |
| Playlist detail view | ✅ Complete | With edit/sort options (Phase 04) |
| Dark mode support | ✅ Complete | System theme integration |
| Animations | ✅ Complete | Smooth transitions |
| Loading states | ✅ Complete | Skeleton screens |

### Non-Functional Requirements

#### Performance

| Requirement | Target | Status |
|-------------|--------|--------|
| App launch | < 2s cold start | ✅ Meets target |
| Playlist load | < 500ms | ✅ Meets target |
| Search | < 200ms | ✅ Meets target |
| Playlist reorder | < 100ms | ✅ Meets target (Phase 04) |
| File import | < 1s per file | ✅ Meets target |

#### Reliability

| Requirement | Target | Status |
|-------------|--------|--------|
| Crash-free hours | > 99.9% | ✅ On track |
| Data persistence | 100% lossless | ✅ CoreData ensures |
| Offline availability | Always | ✅ By design |
| Battery impact | < 5% additional | ✅ Background audio only |

#### Scalability

| Requirement | Target | Status |
|-------------|--------|--------|
| Max library size | 10,000+ songs | ✅ Tested to 5,000 |
| Max playlist size | Unlimited | ✅ No limits |
| Concurrent operations | 5+ simultaneous | ✅ Serial queue handles |
| Memory per song | < 1MB metadata | ✅ Optimized |

#### Security & Privacy

| Requirement | Status | Implementation |
|-------------|--------|-----------------|
| No cloud sync | ✅ Complete | Offline-first by design |
| Local storage only | ✅ Complete | App sandbox (Documents) |
| No analytics | ✅ Complete | No external tracking |
| No ads | ✅ Complete | Clean interface |
| No permissions abuse | ✅ Complete | Only required permissions |
| Encrypted storage | ✅ Complete | CoreData encryption |

#### Compatibility

| Requirement | Status | Notes |
|-------------|--------|-------|
| iOS 15+ | ✅ Complete | Min deployment target |
| iPad support | ✅ Complete | Responsive UI |
| iPhone (all sizes) | ✅ Complete | Safe area handling |
| Light/dark mode | ✅ Complete | System-wide theme |
| Landscape orientation | ✅ Complete | Rotation support |

---

## Architecture & Design

### Architectural Style

**Clean Architecture + MVVM**
- **Domain Layer:** Business logic, use cases, entities (no iOS dependencies)
- **Data Layer:** Persistence, repositories, CoreData models
- **Presentation Layer:** SwiftUI views, view models, state management

### State Management

**MVI Pattern (Model-View-Intent)**
- Immutable state (value types)
- User intent enums
- ViewModel coordinates state changes
- Reducers handle pure state transitions
- @Published for reactive updates

### Dependency Injection

**DIContainer (no singletons)**
- Centralized bootstrapping
- Protocol-based dependencies
- Environment-based injection
- Testable by design

### Key Design Patterns

| Pattern | Purpose | Example |
|---------|---------|---------|
| Protocol-Oriented | Testability, loose coupling | RepositoryProtocol |
| Use Case | Business logic | AddPlaylistUseCase |
| Repository | Data abstraction | PlaylistRepository |
| Entity Mapper | Model conversion | PlaylistEntityMapper |
| Event Publisher | Decoupled notifications | PlaylistEventCenter |

---

## Technical Stack

### Core Technologies

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **UI** | SwiftUI | Native | Modern interface |
| **State** | Combine | Native | Reactive programming |
| **Persistence** | CoreData | Native | Local database |
| **Audio** | AVFoundation | Native | Playback engine |
| **Concurrency** | Async/Await | Swift 5.5+ | Non-blocking operations |

### Dependencies

| Dependency | Purpose | Version |
|-----------|---------|---------|
| GCDWebServer/WebUploader | WiFi file upload | ~> 3.0 |

### Development Tools

| Tool | Usage |
|------|-------|
| Xcode | IDE, build system |
| Swift | Language |
| CocoaPods | Package manager |
| Git | Version control |
| SwiftUI Preview | UI development |

---

## Acceptance Criteria (Phase 04)

All phase 04 features are **COMPLETE** and meet acceptance criteria:

### Reorder Songs
- [x] User can drag songs within playlist detail view
- [x] Order persists after app restart
- [x] Handles edge cases (0 songs, 1 song, all selected)
- [x] Performance < 100ms for 100+ song playlists

### Import Songs
- [x] User can select files from iOS Files app
- [x] Supports mp3, m4a, wav, flac, aac, ogg
- [x] Duplicate file detection works
- [x] Progress shown for multi-file imports
- [x] Results display success/failure per file

### Sort Playlists
- [x] Sorts by name A-Z
- [x] Sorts by creation date (newest first)
- [x] Sorts by song count (most first)
- [x] Default sort: name ascending

### Enhanced Validation
- [x] Playlist names trimmed of whitespace
- [x] Playlist names 1-50 character limit
- [x] Duplicate playlist names prevented
- [x] Error messages shown inline

---

## Development Phases Summary

### Completed Phases

#### Phase 01: DI Architecture ✅
- Replaced singleton pattern with DIContainer
- Implemented protocol-based dependencies
- Environment-based injection

#### Phase 02: File Structure ✅
- Established Clean Architecture layers
- Created Domain, Data, Presentation separation
- Use case organization

#### Phase 03: Modularization ✅
- Split large files (500+ LOC → 200 LOC)
- MVI pattern consolidation
- Improved code readability

#### Phase 04: Playlist Management ✅
- Reorder songs via drag & drop
- Import from Files app
- Enhanced sorting (3 options)
- Validation improvements

### Planned Phases

#### Phase 05: Playback Improvements (Planned)
- Queue management UI
- Smart shuffle algorithm
- Playback speed control (0.75x - 1.5x)
- Enhanced repeat modes

#### Phase 06: Feature Brainstorm (Planned)
- Evaluate smart playlists
- Evaluate backup/restore
- Evaluate gesture controls
- Prioritize Phase 07 features

#### Phase 07+: Feature Implementation
- Smart playlists (auto-generated)
- Backup & restore (iCloud + local)
- Gesture controls (swipe, pinch)
- Podcast support (optional)

---

## Known Limitations & Trade-offs

### Current Limitations

| Limitation | Reason | Workaround |
|-----------|--------|-----------|
| No cloud sync | Privacy-first design | Manual file upload via WiFi |
| No collaborative playlists | Offline-only architecture | Share playlists as files |
| No real-time lyrics | Not in Phase 04 scope | Manual metadata entry |
| No equalizer | DSP complexity | Use system audio settings |

### Acceptable Trade-offs

| Trade-off | Reasoning |
|-----------|-----------|
| Single-device only | Simplified architecture, reliable offline |
| No ads/analytics | Privacy protection, simpler codebase |
| Limited file formats | Focus on universal formats, extensible |

---

## Success Metrics

### User Engagement

| Metric | Target | Measurement |
|--------|--------|-------------|
| Daily active users | 1,000+ | App analytics |
| Avg. session length | > 20 minutes | Session tracking |
| Playlist creation rate | > 50% of users | Usage analytics |
| File import success | > 95% | Import logs |

### Code Quality

| Metric | Target | Status |
|--------|--------|--------|
| Code coverage | > 80% | Automated tests |
| Max file LOC | < 200 | Linting |
| Architecture adherence | 100% | Code review |
| Zero critical bugs | 0 per release | QA testing |

### Performance

| Metric | Target | Status |
|--------|--------|--------|
| Cold startup | < 2 seconds | Profiling |
| Memory usage | < 100MB baseline | Instruments |
| Crash rate | < 0.1% | Crash reporting |
| Battery impact | < 5% additional | Battery profiler |

---

## Risks & Mitigations

### Technical Risks

| Risk | Probability | Mitigation |
|------|-------------|-----------|
| CoreData performance at scale | Low | Indexed queries, batch operations |
| AVAudioEngine limitations | Medium | Early prototyping, fallback plans |
| iOS version compatibility | Low | Device testing on iOS 15-17 |
| Memory with large queues | Low | Lazy loading, chunk-based fetching |

### Product Risks

| Risk | Probability | Mitigation |
|------|-------------|-----------|
| User confusion on features | Medium | In-app tutorials, onboarding |
| Feature scope creep | Medium | Strict phase boundaries, backlog |
| Maintenance burden | Low | Protocol-based design, comprehensive docs |

---

## Quality Assurance

### Testing Strategy

| Type | Coverage | Tools |
|------|----------|-------|
| Unit tests | > 80% business logic | XCTest, mocking |
| Integration tests | > 60% workflows | XCTest, test database |
| UI tests | Critical user flows | XCUITest |
| Performance tests | Key operations | Xcode Instruments |

### Code Review Process

1. Author creates feature branch
2. Tests + docs updated
3. Peer review (architecture, style, completeness)
4. Automated linting check
5. Merge to main after approval

### Release Checklist

- [ ] All tests pass
- [ ] Zero critical warnings
- [ ] Changelog updated
- [ ] Docs synchronized
- [ ] Performance benchmarks pass
- [ ] Security review complete
- [ ] Release notes prepared

---

## Timeline & Resources

### Development Timeline

**Past:**
- Phase 01-04: 4 weeks (Completed)

**Future:**
- Phase 05: 2 weeks (May 13-27)
- Phase 06: 1 week (May 27-Jun 3)
- Phase 07: 2-3 weeks (Jun-July)

### Team & Roles

| Role | Responsibilities |
|------|------------------|
| **Developer** | Code implementation, testing, documentation |
| **Reviewer** | Architecture review, quality assurance |
| **Product** | Roadmap prioritization, user feedback |

---

## Maintenance & Support

### Ongoing Maintenance

- Bug fixes: Within 1-2 weeks
- Security patches: Immediate
- Performance optimization: Quarterly review
- Dependency updates: Monthly

### Version Support

- **Current (1.3):** Full support, active development
- **Previous (1.2):** Bug fixes only
- **Older:** No support (recommend upgrade)

### User Support

- GitHub issues for bug reports
- GitHub discussions for feature requests
- README troubleshooting guide
- Code comments for complex logic

---

## Future Considerations

### Potential Enhancements

1. **Smart Playlists** — Auto-generated by genre, mood, year
2. **Backup/Restore** — iCloud backup, encrypted local restore
3. **Gesture Controls** — Swipe next, pinch volume
4. **Podcast Support** — Episode tracking, auto-skip
5. **Collaborative Features** — Share playlists (post-Phase 06 evaluation)

### Architecture Evolution

- **Modularity:** Convert features to separate packages
- **Testing:** Expand UI test coverage
- **Persistence:** Consider SwiftData (iOS 17+) migration path
- **Performance:** Profile & optimize Core Data queries

### Market Expansion

- **Platforms:** iPad optimization, macOS support
- **Localization:** Multi-language support
- **Accessibility:** VoiceOver, Dynamic Type support

---

## Conclusion

MusicOffline-SwiftUI is a well-architected, privacy-first music player with solid fundamentals. Phase 04 completion brings advanced playlist management to a solid core feature set. Phase 05-07 will enhance playback capabilities and evaluate market-driven features while maintaining architectural integrity.

**Next Steps:**
1. Begin Phase 05 planning (2026-05-06)
2. Review smart shuffle algorithms
3. Evaluate playback speed control feasibility
4. Prepare Phase 05 kickoff materials

---

**Document Status:** ✅ Complete & Current
**Last Updated:** 2026-04-29
**Next Review:** 2026-05-13 (Phase 05 Kickoff)
**Maintainer:** Development Team
