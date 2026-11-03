# Poopita

iOS app scaffold (`com.ayungavis.Poopita`), SwiftUI, iOS 27+, Swift 6. The local Swift package supports iOS 26+.

Encrypted backup is not implemented yet.

## Setup

```bash
brew install xcodegen swiftlint swiftformat
make ios-generate
open apps/ios/Poopita.xcodeproj
```

## Everyday commands

```bash
make ios-test       # unit tests, no simulator
make ios-run        # build + launch on the booted simulator
make ios-validate   # format → lint → test → build; must be green before a PR
```

## Configuration

Values flow `Config/*.xcconfig` → `Info.plist` → `Bundle.main`:

| Key | Debug | Release |
| --- | --- | --- |
| `API_BASE_URL` | `http://localhost:8080` | passed to `xcodebuild` by CI |
| `SENTRY_DSN` | unset (Sentry off) | passed to `xcodebuild` by CI |
| `SENTRY_ENVIRONMENT` | `development` | `production` |

Per-machine overrides (signing team, a device-reachable API URL) go in `apps/ios/Poopita/Config/Local.xcconfig`, which is gitignored.

## TestFlight

`.github/workflows/testflight.yml` archives, exports, and uploads to TestFlight on every push to `main` touching `apps/ios/**` (or a manual run). The build number is the workflow's run number; bump `MARKETING_VERSION` in `apps/ios/project.yml` per release.

GitHub → Settings → Secrets and variables → Actions:

| Name | Kind | Value |
| --- | --- | --- |
| `APPSTORE_ISSUER_ID` | variable | App Store Connect → Users and Access → Integrations → App Store Connect API → Issuer ID |
| `APPSTORE_API_KEY_ID` | variable | Key ID of an API key with the **App Manager** role |
| `APPSTORE_API_PRIVATE_KEY` | secret | Contents of that key's `.p8` (downloadable once) |
| `APPSTORE_CERTIFICATES_FILE_BASE64` | secret | Apple Distribution cert + private key exported as `.p12`, then `base64 -i cert.p12 \| pbcopy` |
| `APPSTORE_CERTIFICATES_PASSWORD` | secret | The `.p12` export password |
| `API_BASE_URL` | secret | Production API base URL |
| `SENTRY_DSN` | secret | Sentry DSN for the iOS project |

Variables go in the **Variables** tab; the workflow fails fast naming any missing value.

Apple-side prerequisites (team `QHL64K2LPL`):

1. Register the explicit bundle ID `com.ayungavis.Poopita` (Certificates, Identifiers & Profiles).
2. Create the app record in App Store Connect with that bundle ID.
3. Create an **App Store Connect** provisioning profile for it named exactly `Poopita Apple Distribution`, signed by the Apple Distribution certificate in the `.p12`.

## Architecture

MVVM + `@Observable`, dependencies injected through `AppContainer`.

## License

Code is licensed under the [Apache License 2.0](LICENSE). See [NOTICE](NOTICE).

## Trademarks

The name "Poopita", the app icon and the mascot artwork are not covered by the Apache License. Forks and redistributed builds must use a different name and icon.
