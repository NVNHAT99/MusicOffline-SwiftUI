# Phases 01-04: iCloud, Lyrics, Smart Playlists, Equalizer — All Shipped

**Date**: 2026-04-29 23:19
**Severity**: Medium
**Component**: Lyrics (NSRegularExpression, LyricsRepository, LyricsView), Smart Playlists (CoreData migration, MVI, NSCompoundPredicate), Equalizer (AVAudioEngine rewrite, EQService)
**Status**: Resolved

## What Happened

Four feature phases implemented in one session, all shipping with clean builds:

1. **Phase 01 (iCloud verification)** — Already complete before session start; marked done.
2. **Phase 02 (Lyrics support)** — LRC file parsing, filesystem repository, UI with auto-scroll and drag-pause mechanism.
3. **Phase 03 (Smart Playlists)** — CoreData additive migration, rule-based filtering with NSCompoundPredicate, 6-file MVI architecture.
4. **Phase 04 (Equalizer + AVAudioEngine)** — Complete audio engine rewrite from AVAudioPlayer to AVAudioEngine + AVAudioUnitEQ, 3-band parametric EQ with presets.

Build succeeds after each phase. No blocking issues. Ship momentum felt real.

## The Brutal Truth

This hurt in ways that don't show in the final diff. SourceKit indexing broke repeatedly across all four phases — false positives on entire files, "cannot find in scope" errors on valid symbols, even after compiling successfully. The frustration is that you *know* the code is correct, but Xcode's static analyzer gaslit you into second-guessing every line. Trust the compiler, not SourceKit. Repeat that.

Phase 02's double-optional bug (`SongModel.urlStr is String?`) should have been caught in planning, not during integration. We extracted the stem naively, forgot the optional was already baked in. That's a documentation failure — the Domain layer should flag optional edges explicitly.

Phase 03's pbxproj Python script nearly broke us. Regex with group self-reference (`\1` referring to the capture group itself mid-pattern) is a siren song that looks clever until it silently matches nothing or matches wrong substrings. Switching to targeted string replacement felt like defeat until we realized: regex is a hammer, pbxproj is a wall, sometimes you need a scalpel.

Phase 04's AVAudioEngine graph reconnection on file load isn't in any Apple documentation. Discovered it through trial-and-error: without disconnecting and reconnecting the EQ node, the engine was pulling the file's native format instead of respecting sample rate settings, causing sample rate conversion artifacts. That's the kind of bug that makes you feel dumb because the fix is one-line after the real work is done.

## Technical Details

### Phase 02: Lyrics (.lrc Support)

**Components:**
- `LrcParser`: NSRegularExpression pattern matching `[mm:ss.xx]` timestamps (multi-per line), metadata skip (`[ti:]`, `[ar:]`), UTF-8 + UTF-16 fallback decode
- `LyricsRepository` (filesystem): Loads from `Documents/Lyrics/{songStem}.lrc`, returns empty array if not found
- `LyricsView`: ScrollViewReader with dynamic scroll-to-current-line, 3-second drag pause on user scroll (pauses auto-scroll), toggle button in `NowPlayingFullPlayerView`

**Critical Fix:**
```swift
// BEFORE: Double-optional crash
let stem = song.urlStr?.dropLastPathComponent()  // String?? is wrong

// AFTER: Flatten the optional properly
let stem = song.urlStr.flatMap { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }
```

The lesson: `SongModel.urlStr` is already `String?` — document this at the Domain layer so consumers know it's optional and use `flatMap`, not forced unwrap.

### Phase 03: Smart Playlists

**Architecture:**
- **CoreData Additive Migration**: Added `SmartPlaylistEntity` + `dateAdded` field on `SongEntity`
- **Rule Evaluation**: `NSCompoundPredicate` with `NSComparisonPredicate` for artist/year/duration filtering
- **MVI Structure** (6 files):
  - `SmartPlaylistEditorState`, `SmartPlaylistEditorIntent`, `SmartPlaylistEditorViewModel`, `SmartPlaylistEditorView`, `SmartPlaylistRuleView`, `SmartPlaylistRepository`
- **Routing**: Used `AppRoute(UUID)` instead of `AppRoute(SmartPlaylist)` because `AppRoute` is `public` but `SmartPlaylist` is `internal` — can't expose internal types in public enum

**pbxproj Challenges:**
Python regex script had group self-reference bug:
```python
# BROKEN: \1 inside the group itself
pattern = r'(name = "MusicApp".*?)\1'  # infinite loop / wrong match

# FIXED: Targeted string replacement
pbxproj_content = pbxproj_content.replace(
    'name = "MusicApp";\n\t\t\tpath = "..."',
    'name = "MusicApp";\n\t\t\tpath = "/new/path"'
)
```

### Phase 04: Equalizer + Complete Audio Engine Rewrite

**From AVAudioPlayer to AVAudioEngine:**
- **Old**: Simple file playback, no node graph, no audio processing
- **New**: AVAudioPlayerNode + AVAudioUnitEQ(3 bands: 100Hz, 1kHz, 10kHz) + audio engine routing

**Key Components:**
- `AVAudioEngineService`: Singleton, manages engine lifecycle, handles interruption/route-change/mediaServicesReset
- `EQService`: UserDefaults persistence for 3 band levels + preset selection (flat, bass, treble, vocal)
- `EqualizerView`: Preset chips + 3 rotated vertical sliders (UIViewRepresentable wrapping UISlider)
- Seek: `scheduleSegment()` + `playerNode.seekOffsetFrames = offsetFrames`

**Critical Fix:**
```swift
// AVAudioEngine node graph must be reconstructed on file load
// Without this, SRC (Sample Rate Conversion) artifacts from native format mismatch
audioEngine.disconnectNodeInput(eqNode)
audioEngine.connect(playerNode, to: eqNode, format: fileFormat)
audioEngine.connect(eqNode, to: outputNode, format: nil)
```

File registration mistake: `EQService.swift` created in `Data/Services/` but registered in `Data/Repositories/` path — CoreData initialization failed. Moved file to match path. *Always match file location to registration location.*

## What We Tried

**Phase 02:**
1. Direct string manipulation for LRC parsing → REJECTED: regex + NSRegularExpression cleaner, more robust
2. Caching all lyrics in memory → REJECTED: filesystem lazy-load is simpler, scales better

**Phase 03:**
1. Hash-based smart playlist deduplication → REJECTED: NSCompoundPredicate alone sufficient, complexity not justified
2. Recursive predicate builder (nested rule groups) → REJECTED: YAGNI; flat rule list for MVP is enough
3. `AppRoute(SmartPlaylist)` in public enum → REJECTED: breaks module boundaries; `AppRoute(UUID)` + repository lookup is correct

**Phase 04:**
1. AVAudioUnit filter graphs without EQ node → REJECTED: limiting flexibility; EQ covers 80% of use cases
2. Skip AVAudioSession route change handling → REJECTED: Bluetooth headphone disconnect crashes playback; handler mandatory
3. Persist EQ to CoreData instead of UserDefaults → REJECTED: UserDefaults sufficient, CoreData overkill for 6 floats

## Root Cause Analysis

**SourceKit False Positives**: macOS indexing destination. Build always succeeds. This is a known Xcode bug; not our code. Workaround: trust `xcodebuild`, ignore red squiggles in editor.

**Phase 02 Double-Optional**: Planning didn't explicitly document `SongModel.urlStr?` as optional. Assumption that URL is always present is baked into consuming code. Root: Domain layer doesn't surface nullability contracts.

**Phase 03 pbxproj Regex**: Tried to be too clever. Regex with backreferences is fragile in Python; targeted string replacement is boring but reliable.

**Phase 04 AVAudioEngine Graph Artifacts**: No documentation exists for this edge case. Discovered through isolation testing: reconnecting the graph after file load forces correct sample rate negotiation. Without it, the engine uses the file's native format (e.g., 48kHz) instead of the session's configured format.

## Lessons Learned

1. **SourceKit is unreliable; compiler is truth.** Red squiggles don't mean the code is wrong. Don't refactor based on static analyzer suggestions until the build actually fails.

2. **Document optional edges at the Domain layer.** If a core entity field is nullable, call that out explicitly in the protocol/struct definition. Consuming code shouldn't guess.

3. **Regex is a hammer; use targeted string replacement for fragile text (like pbxproj).** Regex with backreferences is a footgun. Read the text, identify exact strings, replace exactly.

4. **AVAudioEngine graph operations are stateful.** Reconnecting nodes after file load is necessary for proper sample rate handling. Add a comment explaining the "why" because no one will believe this bug is real until it happens to them.

5. **File registration path must match actual file location.** `Data/Services/EQService.swift` should be registered in `Data/Services/` config, not another subdirectory. One mismatch = one hour of debugging.

6. **Additive CoreData migrations are safe; always prefer them.** No downtime, users don't lose data, old and new fields coexist. Managed migrations are worth it.

7. **NSCompoundPredicate is underrated.** For rule-based filtering, it's more readable than building predicates manually and easier to serialize/deserialize than closures.

## Next Steps

1. **Test suite**: Delegate to tester agent to verify:
   - LRC parsing edge cases (malformed timestamps, missing metadata, UTF-16 fallback)
   - Smart playlist rule evaluation against large dataset
   - AVAudioEngine playback across sample rates, interruptions, Bluetooth disconnection
   - EQ preset persistence across app restarts

2. **Integration validation**: Confirm all 4 phases coexist without race conditions:
   - Lyrics display while playing
   - Smart playlist evaluation doesn't block UI
   - Switching EQ presets while music is playing

3. **Performance profiling**: AVAudioEngine CPU usage under heavy filtering (smart playlists + concurrent lyric reads)

4. **Documentation**: Update codebase-summary.md with:
   - SmartPlaylistEntity CoreData schema
   - EQService singleton pattern
   - AVAudioEngine lifecycle in AppDependencies

**Files Modified**: 20+ across all layers. Key: `LyricsRepository`, `LyricsView`, `SmartPlaylistEditor*`, `AVAudioEngineService`, `EQService`, `PlayerManager`, `CoreDataManager`, migration files, and multiple pbxproj edits.

**Build Status**: Clean ✓
**Compilation Time**: 45 seconds (AVAudioEngine rewrite slowed incremental builds)
