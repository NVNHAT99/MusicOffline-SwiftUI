# MusicApp - Full Refactor & Feature Improvement Plan

**Created:** 2026-04-28  
**Branch:** Master  
**Status:** 🔵 Ready to implement

## Overview

5-phase plan to refactor MusicApp to EasyFax/stress-app/EZTranslate architecture standards, then improve playlist management, playback flow, and brainstorm new features.

## Reference Codebases Analyzed
- **EasyFax** (`/Users/nhat/Dev/IOS/my-fax-app/EasyFax`): DIContainer + AppEnvironment + Router<AppRoute> + MVI
- **stress-app** (`/Users/nhat/Dev/IOS/stress-app`): Generic Router, AppEnvironment bootstrap, clean DI
- **EZTranslate** (`/Users/nhat/Dev/IOS/EZTranslate`): DesignSystem/DesignToken, Features folder, clean UseCases

## Current State Summary
- ✅ `AppEnvironment.bootstrap()` — already correct pattern
- ✅ `DIContainer` (Services + UseCases) — already correct  
- ✅ `AppState` — already correct
- ✅ `MusicApp.swift` — uses `AppEnvironment.bootstrap()`
- ✅ `MainTabView` — injects via `@EnvironmentObject var container: DIContainer`
- ✅ `AppRoute.swift` — in `Core/Router/AppRoute.swift`
- ❌ `AppDependencies.swift` (298 LOC) — old singleton, still referenced in previews + ViewBuilder
- ❌ `DIContainer+ViewFactory.appRouter(for:)` — creates new empty router (bug)
- ❌ `makeEditPlaylistView` — returns `EmptyView()` (TODO)
- ❌ No `DesignSystem/` folder, no `AppFont`, no SwiftUI `Color+Ext`
- ❌ 7 files exceed 200 LOC (ImageCacheManager 460, PlayerManager 439, etc.)
- ❌ Demo/backup files in codebase

## Phases

| # | Phase | LOC est | Status | Context |
|---|-------|---------|--------|---------|
| [01](./phase-01-refactor-di-architecture.md) | Remove AppDependencies + fix ViewFactory | ~50 changes | ✅ Complete | Same session |
| [02](./phase-02-refactor-file-structure.md) | DesignSystem + cleanup dead files | ~200 new LOC | ✅ Complete | Same session |
| [03](./phase-03-split-large-files.md) | Split 7 files >200 LOC | Reorganize | ✅ Complete | Same session |
| [04](./phase-04-playlist-management-improve.md) | Playlist CRUD + import + reorder | ~400 new LOC | ✅ Complete | **Clear context first** |
| [05](./phase-05-playback-flow-improve.md) | Seek/shuffle/repeat improvements | ~100 changes | ✅ Complete | **Clear context first** |
| [06](./phase-06-feature-brainstorm.md) | Brainstorm + Gemini research | Research only | ⬜ Todo | **Clear context first** |

## Task Mapping
- **Task 1-2 (Refactor):** Phases 01 → 02 → 03 in sequence, same context window
- **Task 3 (Playlist):** Phase 04 — clear context, load phase-04 file
- **Task 4 (Playback):** Phase 05 — clear context, load phase-05 file  
- **Task 5 (Brainstorm):** Phase 06 — clear context, load phase-06 file

## Context Continuity Strategy
Each phase file is self-contained with all context needed. When clearing context:
1. Tell Claude: "Load plan from `plans/260428-2336-musicapp-full-refactor-and-improve/phase-0X-*.md`"
2. Claude reads the phase file and has all context to proceed without needing prior conversation

## Key Constraints
- iOS 15+ target, CocoaPods dependency manager
- All existing functionality must work after each phase
- MVI pattern: State → Intent → ViewModel → StateAction → Reducer
- Max 200 LOC per file
- No mocks — real code only
- Compile check after every phase

## Quick Reference - Files Over 200 LOC
| File | LOC |
|------|-----|
| `Core/ImageCacheManager.swift` | 460 |
| `Core/PlayerManager.swift` | 439 |
| `Presentation/Feature/NowPlayingScreen/NowPlayingView.swift` | 339 |
| `Commons/Tabars/CustomTabBar.swift` | 311 |
| `Core/AppDependencies.swift` | 298 (delete) |
| `Core/DI/DIContainer+ViewFactory.swift` | 258 |
| `Commons/Logger/LoggerExample.swift` | 254 (delete) |
| `Commons/Extension/Demos/DemoDelayTouch.swift` | 252 (delete) |
| `Data/Repositories/SongRepository.swift` | 232 |
| `Commons/Modifiers.swift` | 224 |
| `Core/DI/DIContainer.swift` | 223 |
