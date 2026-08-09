# Phase 02 — AdMob Integration

## Context Links
- `Podfile`
- `MusicApp/Info.plist`
- `MusicApp/Presentation/Feature/App/MusicApp.swift`
- `MusicApp/Core/DI/AppEnvironment.swift`
- `MusicApp/Presentation/Feature/Home/HomeView.swift`
- `MusicApp/Presentation/Feature/NowPlayingScreen/Views/NowPlayingMiniPlayerView.swift`
- `MusicApp/Presentation/Feature/NowPlayingScreen/Views/NowPlayingFullPlayerView.swift`

## Overview
- **Priority:** P2
- **Status:** pending
- **Description:** Add Google Mobile Ads SDK, ATT consent prompt, banner ads on Home (bottom) and NowPlaying mini-player.

## Key Insights
- AdMob SDK init MUST happen AFTER ATT response (or skip wait if user denies); otherwise IDFA-less requests still work but personalization disabled
- Use **AdMob TEST IDs only** until real account setup — prevents account ban during dev
- Banner = `GADBannerView` standard size 320x50; wrap as `UIViewRepresentable`
- iOS 14.5+ ATT requires `NSUserTrackingUsageDescription` in Info.plist or app rejected
- Single `AdService` singleton handles SDK init + ATT request + banner request lifecycle (avoid leaking GADBannerView refs across SwiftUI redraws)

## Requirements

### Functional
- ATT prompt on first cold launch (after ~1s delay so it doesn't compete with launch screen)
- AdMob SDK init regardless of ATT outcome
- Banner ad at bottom of `HomeView` (above tab bar safe area)
- Banner ad at bottom of `NowPlayingFullPlayerView` (above bottom controls, only when expanded — confirmed in spec as "minimized/mini player"; interpret as: show on full player bottom, NOT mini)
- No banner during initial loading skeleton

### Non-functional
- Banner reserves 50pt height even before load (no layout shift)
- Failed ad load is silent (logged only)
- No ads block on Wi-Fi loss

## Architecture

### Components
```
AppEnvironment.bootstrap()
   ↓
AdService.shared.start()
   ├─ requestATT { _ in MobileAds.shared.start(completionHandler: nil) }
   └─ (ready)

HomeView / NowPlayingFullPlayerView
   └─ AdBannerView(adUnitID: AdConstants.homeBanner)
         ↓
       UIViewRepresentable → GADBannerView → loadRequest()
```

### Key Files
- `AdService.swift` — singleton: ATT request, SDK init, ad-unit ID provider
- `AdBannerView.swift` — UIViewRepresentable wrapping GADBannerView
- `AdConstants.swift` — placeholder app ID + unit IDs (test IDs)

## Related Code Files

### Modify
- `Podfile` — add `pod 'Google-Mobile-Ads-SDK'`
- `MusicApp/Info.plist` — add `GADApplicationIdentifier`, `NSUserTrackingUsageDescription`, `SKAdNetworkItems` (optional but recommended)
- `MusicApp/Core/DI/AppEnvironment.swift` — call `AdService.shared.start()` during bootstrap
- `MusicApp/Presentation/Feature/Home/HomeView.swift` — mount `AdBannerView` at bottom
- `MusicApp/Presentation/Feature/NowPlayingScreen/Views/NowPlayingFullPlayerView.swift` — mount banner above bottom safe area

### Create
- `MusicApp/Core/Ads/AdService.swift`
- `MusicApp/Core/Ads/AdBannerView.swift`
- `MusicApp/Core/Ads/AdConstants.swift`

### Delete
- None

## Implementation Steps

1. **Podfile + Info.plist**
   - Append `pod 'Google-Mobile-Ads-SDK'` to main `MusicApp` target only (not test targets)
   - Run `pod install`
   - Info.plist additions:
     - `GADApplicationIdentifier` = `ca-app-pub-3940256099942544~1458002511` (test app ID)
     - `NSUserTrackingUsageDescription` = "We use your data to show relevant ads."
     - `SKAdNetworkItems`: optional Google list (defer if SDK auto-provides)

2. **AdConstants**
   ```swift
   enum AdConstants {
     static let appID = "ca-app-pub-3940256099942544~1458002511"
     static let homeBannerUnitID = "ca-app-pub-3940256099942544/2934735716" // test banner
     static let nowPlayingBannerUnitID = "ca-app-pub-3940256099942544/2934735716"
   }
   ```

3. **AdService**
   - `static let shared`
   - `start()` — call once
   - Internal `requestATTIfNeeded(completion:)` using `ATTrackingManager.requestTrackingAuthorization`
   - On callback (any status) → `MobileAds.shared.start(completionHandler: nil)`
   - Guard `start()` called only once (`hasStarted` flag)
   - Delay ATT request by 1s after launch (DispatchQueue.main.asyncAfter)

4. **AdBannerView**
   - `UIViewRepresentable`, `adUnitID: String`
   - `makeUIView` → create `GADBannerView(adSize: GADAdSizeBanner)`, set `adUnitID`, set `rootViewController` from active window scene, call `load(GADRequest())`
   - `updateUIView` → no-op
   - Frame fixed 320x50; container reserves 50pt height regardless of load state

5. **AppEnvironment bootstrap**
   - In `AppEnvironment.bootstrap()` (or `MusicApp.init`), call `AdService.shared.start()`
   - Verify it runs ONCE not per scene change

6. **HomeView mount**
   - Wrap existing `ScrollView` in `VStack`
   - Append `AdBannerView(adUnitID: AdConstants.homeBannerUnitID).frame(height: 50)` at bottom
   - Add bottom padding to ScrollView so last item not hidden behind banner

7. **NowPlayingFullPlayerView mount**
   - Add overlay or bottom HStack with `AdBannerView(adUnitID: AdConstants.nowPlayingBannerUnitID)` above safe area
   - Ensure does not overlap play/pause controls; adjust controls spacer if needed

8. **Compile + smoke test**
   - `pod install` succeeds
   - App launches, ATT prompt appears once after ~1s
   - Test banner renders on Home + NowPlaying
   - Logs show `MobileAds.shared.start` completion

## Todo List

- [ ] Add `Google-Mobile-Ads-SDK` to Podfile
- [ ] Run `pod install` and resolve
- [ ] Add `GADApplicationIdentifier` + `NSUserTrackingUsageDescription` to Info.plist
- [ ] Create `AdConstants.swift`
- [ ] Create `AdService.swift` with ATT + SDK init
- [ ] Create `AdBannerView.swift` UIViewRepresentable
- [ ] Hook `AdService.shared.start()` into `AppEnvironment.bootstrap`
- [ ] Mount banner in `HomeView`
- [ ] Mount banner in `NowPlayingFullPlayerView`
- [ ] Verify ATT prompt appears once
- [ ] Verify test banner loads on both screens
- [ ] Confirm no layout shift / overlap

## Success Criteria
- App launches without crash
- ATT prompt fires once on first launch, never again
- Test banner visible on Home (bottom) and NowPlaying (bottom)
- 50pt reserved height — no layout jump on load
- Logs confirm SDK init success
- No file exceeds 200 LOC

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| AdMob SDK adds large binary / slow build | High | Med | Accept; document build time delta |
| ATT prompt rejected by App Review (vague description) | Med | High | Use specific copy: "We use your data to show relevant ads." |
| GADBannerView leaks across SwiftUI redraws | Med | Med | Use `UIViewRepresentable` correctly with stable identity; do not recreate in body |
| Banner overlaps mini-player on Home | Med | Med | Mini-player is overlay above tab bar; verify z-order, place banner below mini-player |
| iOS 14.5 ATT prompt requires main thread + active scene | High | High | Wrap in `DispatchQueue.main.asyncAfter` post-launch |
| Pod install breaks existing GCDWebServer | Low | High | Lock SDK version; test build before merging |

## Security Considerations
- Use TEST ad unit IDs only until production AdMob account ready (avoid policy violations)
- ATT description string must accurately describe data usage
- No PII passed to ad requests
- COPPA / GDPR consent: defer to post-launch (out of scope for this phase, document as TODO)

## Rollback
- Comment out `pod 'Google-Mobile-Ads-SDK'` in Podfile, run `pod install`
- Remove `AdBannerView` mounts from Home + NowPlaying views
- Leave `AdService` + Info.plist entries (harmless if SDK gone — guard imports with `#if canImport(GoogleMobileAds)`)
