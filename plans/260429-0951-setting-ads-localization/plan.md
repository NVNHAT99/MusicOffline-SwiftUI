---
title: "Setting Refactor + AdMob + Localization"
description: "Restructure Setting screen, integrate AdMob banners on Home/NowPlaying, add EN/VI localization via xcstrings"
status: pending
priority: P2
effort: ~12h
branch: Master
tags: [ios, swiftui, mvi, admob, localization, settings]
created: 2026-04-29
---

# MusicApp — Setting Refactor + AdMob + Localization

## Goal
Three sequential phases delivering a refactored Setting screen, monetization via AdMob banners, and EN/VI localization scaffold.

## Phases

| # | Phase | File | Status | Effort |
|---|-------|------|--------|--------|
| 1 | Setting UI Refactor (sections + new actions) | `phase-01-setting-ui-refactor.md` | ✅ Complete | ~4h |
| 2 | AdMob Integration (SDK + banners + ATT) | `phase-02-admob-integration.md` | pending | ~5h |
| 3 | Localization (xcstrings + LanguageManager) | `phase-03-localization.md` | pending | ~3h |

## Dependencies
- Phase 2 has NO blocker on Phase 1 (independent), but ordered for review hygiene
- Phase 3 depends on Phase 1 (language picker placeholder lives in Setting → General; Phase 3 wires it)
- All phases respect existing MVI: `State / Intent / ViewModel / Reducer / Action`

## Cross-cutting Constraints
- File size ≤ 200 LOC; split into helper views/services where needed
- DIContainer pattern; no new singletons unless infra-level (AdService, LanguageManager OK)
- `withAnimation` guarded; use `MainActor` for UI state mutations
- All new strings funneled through `String(localized:)` from Phase 3 onward; Phase 1 may use literals temporarily

## Success Criteria
- Setting screen presents 3 sections (General / About / Danger Zone) and all actions work
- AdMob banner visible on Home (bottom) and NowPlaying mini-player without overlapping content
- ATT prompt fires once on first launch; no crash without consent
- Switching language in Setting persists across app restart and updates Setting screen text immediately

## Risks (Top)
- **R1 (High):** AdMob SDK init race vs ATT consent → init only AFTER ATT response
- **R2 (Med):** Banner overlap with mini-player / safe area → reserve fixed height container
- **R3 (Med):** xcstrings migration breaks existing literals scattered across views → Phase 3 limits scope to Setting + shared strings
- **R4 (Low):** SKStoreReviewController throttling silently no-ops → expected, no fallback needed

## Rollback
- Phase 1: revert SettingView/Intent/State/Reducer commits
- Phase 2: comment out `pod 'Google-Mobile-Ads-SDK'`, remove banner mounts, leave ATT in place (harmless)
- Phase 3: remove `LanguageManager` env injection, keys fallback to literal defaults

## Open Questions
- Real Privacy/ToU URLs and AdMob app/unit IDs — currently placeholders
- Should ATT prompt be deferred to first ad load instead of cold launch? (current plan: cold launch)
