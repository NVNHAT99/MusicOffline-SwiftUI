# Fastlane — local CI/CD

Local build/test/ship pipeline for MusicApp. No CI server; you run lanes from
your Mac. Uses **Xcode automatic signing** (team `755CXQS973`) and **App Store
Connect API key** auth (no Apple ID/password stored).

## Lanes
| Command | What it does | Needs API key | Needs Distribution cert |
|---------|--------------|:---:|:---:|
| `bundle exec fastlane test`    | Run `MusicAppTests` on iPhone 17 Pro sim | no | no |
| `bundle exec fastlane build`   | Archive a signed Release `.ipa` → `build/` (no upload) | no | yes |
| `bundle exec fastlane beta`    | test → bump build # → archive → upload to **TestFlight** | yes | yes |
| `bundle exec fastlane release` | test → archive → upload to **App Store** + submit for review | yes | yes |

## One-time setup

### 1. Install gems
```
bundle install
```

### 2. App Store Connect API key (for beta/release)
1. App Store Connect → **Users and Access → Integrations → App Store Connect API**.
2. Generate an API key with **App Manager** access. Download the `.p8` **once**
   and store it OUTSIDE this repo (e.g. `~/secrets/AuthKey_XXXX.p8`).
3. `cp fastlane/.env.example fastlane/.env` and fill in `ASC_KEY_ID`,
   `ASC_ISSUER_ID`, `ASC_KEY_PATH`. (`.env` is git-ignored.)

### 3. Apple Distribution certificate (for build/beta/release)
You currently have only "Apple Development" certs. Create a Distribution one once:
- Xcode → Settings → Accounts → your team → **Manage Certificates → + → Apple Distribution**.
- (Automatic signing will then pick it for Release archives.)

### 4. App record on App Store Connect
Create the app once (bundle id `com.nph.OffIMuzikBox`) so beta/release have a
target. Screenshots/description are managed in App Store Connect for now
(`release` lane uses `skip_screenshots: true`).

## Typical flow
```
bundle exec fastlane test       # sanity
bundle exec fastlane beta       # ship to TestFlight
# ...test on TestFlight, then:
bundle exec fastlane release    # submit to App Store
```

## Notes
- `release` uses `skip_metadata: false` → it reads `fastlane/metadata/` if present.
  To manage everything in the web UI instead, set `skip_metadata: true` in the Fastfile.
- First TestFlight upload may take a few minutes to process before it's testable.
