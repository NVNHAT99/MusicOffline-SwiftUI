fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios certs

```sh
[bundle exec] fastlane ios certs
```

Create/fetch the Apple Distribution cert + App Store profile via API key

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Upload App Store screenshots only (no binary/metadata/submit)

### ios test

```sh
[bundle exec] fastlane ios test
```

Run the unit test suite

### ios build

```sh
[bundle exec] fastlane ios build
```

Build + archive a signed IPA locally (no upload)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build + upload to TestFlight (internal testing)

### ios release

```sh
[bundle exec] fastlane ios release
```

Build + upload to App Store + submit for review

### ios privacy

```sh
[bundle exec] fastlane ios privacy
```

Upload App Privacy (data collection) details for AdMob + ATT. Apple has no API-key endpoint for this yet, so it uses Apple ID session login — you'll be prompted for your Apple ID and a 2FA code. Answers live in fastlane/app_privacy_details.json.

### ios age_rating

```sh
[bundle exec] fastlane ios age_rating
```

Push ONLY the age-rating declaration (advertising = true, required because the app shows AdMob ads). Uses the API key. Does not submit.

### ios prepare_release

```sh
[bundle exec] fastlane ios prepare_release
```

Create the App Store version + push ONLY the release notes, attach the uploaded build, but DO NOT submit for review (finish IAP + submit manually). deliver only uploads fields that exist as files, so the metadata folder holds just release_notes.txt — description, keywords, etc. on App Store Connect are left untouched.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
