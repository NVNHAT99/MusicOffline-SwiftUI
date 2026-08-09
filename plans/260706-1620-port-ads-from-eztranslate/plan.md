# Port Ad System from EZTranslate → MusicOffline-SwiftUI

## Goal
Add Banner + Interstitial ads (GoogleMobileAds SPM, already linked 13.3.0) to MusicOffline,
porting EZTranslate's proven ad system, adapted to MusicOffline's architecture.

## Production Ad Unit IDs (from AdMob, account ca-app-pub-9481704307510282)
- Banner_Home: `ca-app-pub-9481704307510282/9740866756`
- interstitial: `ca-app-pub-9481704307510282/6913090370`
- App ID (GADApplicationIdentifier): TBD — confirm Off IMuzik Box app id (~ suffix)

## Key architecture differences vs EZTranslate
- No AppDelegate → pure SwiftUI scenePhase via SystemEventsHandler
- DI = DIContainer.Services struct + createDefault()
- SDK init in AppEnvironment.bootstrap(), not AppDelegate
- No premium gate → ads always show
- App-open interstitial via SystemEventsHandler.sceneDidBecomeActive() (not didBecomeActive notification)

## Placement decisions (per user + pending plan)
- Banner: Home (bottom, above tab bar) + NowPlaying full player (bottom, expanded only)
- Interstitial: app-open counter (every N foregrounds) — port AdCounterService

## Phases
- phase-01: Config + SDK init + Info.plist (AdMobConfig, MobileAds.start, GADApplicationIdentifier, ATT) — DONE
- phase-02: Interstitial service (GoogleAdMobService port: preload + waitForInterstitial + delegate dismiss) — DONE
- phase-03: AdCounterService + app-open trigger via AppDelegate (didBecomeActive) — DONE
- phase-04: Banner (AdBanner SwiftUI wrapper) mount on Home + NowPlaying — DONE

## Status: DONE
- App ID confirmed: `ca-app-pub-9481704307510282~6397847108`.
- App-open trigger lives in `AppDelegate` (UIApplication.didBecomeActiveNotification),
  not SystemEventsHandler — better distinguishes real foregrounds from transient reactivations.
- ATT consent (`ATTrackingService`) runs ~1s after launch, THEN `MobileAds.start` — deny still serves ads.
- IAP "Remove Ads" ($4.99 lifetime) via MonetizeKit gates all ads on `AppState.isPremium`.
