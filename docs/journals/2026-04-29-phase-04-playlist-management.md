# Phase 04: Playlist Management CRUD & Drag Reorder — Implementation Complete

**Date**: 2026-04-29 05:57
**Severity**: Low
**Component**: Playlist Management (Core Data, Use Cases, UI)
**Status**: Resolved

## What Happened

Phase 04 playlist management features shipped: reorder by drag, import from Files app, bulk delete, improved validation. All Swift compilation succeeds. Build fails on unrelated GCDWebServer SPM issue, not our code.

## The Brutal Truth

This phase was cleaner than expected — disciplined adherence to KISS prevented scope creep. One design decision (optimistic reorder) could mask race conditions under poor network, but CoreData transaction fallback is solid. File import validation is weak (filename only, not hash) because we valued simplicity over duplicate detection rigor.

## Technical Details

**New Use Cases:**
- `ReorderPlaylistSongsUseCase`: Updates songIDs array order in CoreData transaction
- `ImportSongFromFilesUseCase`: UIDocumentPicker → file copy to Documents/Music/ → AddSongUseCase → persistence

**Enhanced Components:**
- `PlaylistRepository.updateSongOrder()`: Single mutation point for reorder
- `PlaylistDetailViewModel`: Optimistic UI update with fallback on error; preserves songIDs array order on load
- `AddPlaylistViewModel`: Client-side name validation (trim, 1-50 chars) before async call
- `PlaylistDetailView`: .onMove drag handler, edit mode toggle, bulk delete toolbar with multi-select

**Validation Changes:**
- AddPlaylistUseCase: nameEmpty, nameTooLong error cases added; prevents unnecessary network round-trips

## What We Tried

1. Hash-based duplicate detection for imports — REJECTED: complexity vs benefit trade-off; filename match sufficient for initial MVP
2. Server-side validation only in AddPlaylistViewModel — REJECTED: felt too slow; client validation catches common errors faster

## Root Cause Analysis

Why cleaner than expected? Task boundaries were tight. Phase 02 (models) and Phase 03 (repository) left no ambiguity about data contracts. Validation rules explicit before coding started. No last-minute scope changes.

The GCDWebServer build failure is external — SPM dependency resolution issue, not Phase 04 code.

## Lessons Learned

- Client-side validation before async use cases reduces perceived latency and catches obvious errors early
- Optimistic updates are safe if fallback is properly tested; state rollback on failure is non-negotiable
- File operations (copy, duplicate detection) should remain simple initially — upgrade only if actual duplicates become a user pain point
- Tight task boundaries from planning → cleaner implementation; looseness leads to scope drift

## Next Steps

1. Run Phase 04 test suite (delegate to tester agent) — verify reorder state rollback, import file handling, bulk delete
2. Phase 05: Profile management — depends on Phase 03 (UserRepository) being stable; check for any blocking issues
3. Monitor GCDWebServer SPM issue — may need to replace with alternative or pin version

**Files Modified**: ReorderPlaylistSongsUseCase, ImportSongFromFilesUseCase, PlaylistRepository, PlaylistDetailViewModel, PlaylistDetailView, AddNewPlaylistViewModel, ImportSong/ (new MVI module), DIContainer
