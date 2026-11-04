# Poopita

A private poop and bowel diary for iPhone. Log each poop in seconds, see what is usual for you, and notice when it changes. Everything stays on your device.

[Website](https://poopita.ayungavis.com) · [Privacy policy](https://poopita.ayungavis.com/privacy/) · [Support](https://poopita.ayungavis.com/support/)

**Status:** in development, coming soon to the App Store. Available in English and Bahasa Indonesia.

## Features

- **Log in seconds.** Bristol type, amount, effort and blood. Color, time on the toilet and a note are optional.
- **Unknown is never zero.** Confirm a no-poop day with one tap; a day you did not record stays unknown instead of counting as zero.
- **See what is usual for you.** Frequency, consistency and comfort by week, month or year, and what changed from your usual. No scores, no streaks.
- **One quiet nudge.** An optional daily check-in, only on days you have not logged. The notification just says "Quick check-in".
- **Locked when you want.** Face ID, Touch ID or passcode, and hidden in the app switcher.
- **Share with your doctor.** Export a PDF or CSV, created on your iPhone and shared only where you choose.

## Privacy

Your diary is stored on your iPhone. There is no account, no server, no sync, no ads and no tracking. The only thing the app may send is an anonymous crash report with no diary content. Details are in the [privacy policy](https://poopita.ayungavis.com/privacy/).

## Repository layout

```
apps/
  ios/
    project.yml        XcodeGen spec, the source of truth for the Xcode project
    Poopita/           App target: entry point, assets, xcconfig files
    PoopitaKit/        Swift package with the app code, design system and tests
  web/                 Astro site for poopita.ayungavis.com
```

## Requirements

- macOS with Xcode and the iOS 27 SDK (the app targets iOS 27; PoopitaKit builds for iOS 26+)
- [Homebrew](https://brew.sh): `xcodegen`, `swiftlint`, `swiftformat`
- [Bun](https://bun.sh) for the website

## Getting started

### iOS app

```bash
brew install xcodegen swiftlint swiftformat
make ios-generate
open apps/ios/Poopita.xcodeproj
```

```bash
make ios-test       # unit tests, no simulator needed
make ios-run        # build, install and launch on the booted simulator
make ios-validate   # format → lint → test → build
```

The Xcode project is generated from `apps/ios/project.yml` and is not committed. Per-machine overrides, such as your signing team, go in `apps/ios/Poopita/Config/Local.xcconfig`, which is gitignored.

### Website

```bash
make web-install    # bun install
make web-dev        # http://localhost:4321
make web-validate   # format check → lint → typecheck → theme check → test → build
```

Copy lives in `apps/web/src/i18n/messages/{en,id}.ts`. After editing `apps/web/src/themes/poopitaTheme.ts`, run `bun run --cwd apps/web theme:build` and commit the generated files.

Run `make` on its own to list every command.

## Architecture

- **iOS:** SwiftUI with MVVM and `@Observable`. Views read view data from a view model, view models talk to repositories, and repositories own the domain rules. Dependencies are injected through `AppContainer`. Tests use Swift Testing.
- **Website:** Astro renders Astryx React components to static HTML. The only client JavaScript is a small header script and a theme script. It is served by a Cloudflare Worker with static assets.

## Contributing

Issues and pull requests are welcome. Before opening a pull request:

1. Run `make ios-validate` for app changes or `make web-validate` for website changes, and make sure it is green.
2. Add or update tests for new logic.
3. Keep facts on the website in line with the app and the privacy policy.

Please do not include health details or personal data in issues. For security reports, email [wahyu@ayungavis.com](mailto:wahyu@ayungavis.com) instead of opening a public issue.

## Roadmap

- App Store release
- Encrypted backup (not implemented yet)

## Maintainers: CI and releases

<details>
<summary>Configuration, TestFlight and website deployment</summary>

### App configuration

Values flow `Config/*.xcconfig` → `Info.plist` → `Bundle.main`:

| Key | Debug | Release |
| --- | --- | --- |
| `API_BASE_URL` | `http://localhost:8080` | passed to `xcodebuild` by CI |
| `SENTRY_DSN` | unset (Sentry off) | passed to `xcodebuild` by CI |
| `SENTRY_ENVIRONMENT` | `development` | `production` |

### TestFlight

`.github/workflows/testflight.yml` archives, exports and uploads to TestFlight on every push to `main` that touches `apps/ios/**`, or on a manual run. The build number is the workflow's run number; bump `MARKETING_VERSION` in `apps/ios/project.yml` for each release.

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

The workflow fails fast and names any missing value.

Apple-side prerequisites (team `QHL64K2LPL`):

1. Register the explicit bundle ID `com.ayungavis.Poopita` (Certificates, Identifiers & Profiles).
2. Create the app record in App Store Connect with that bundle ID.
3. Create an **App Store Connect** provisioning profile named exactly `Poopita Apple Distribution`, signed by the Apple Distribution certificate in the `.p12`.

### Website deployment

`.github/workflows/web.yml` validates every pull request and deploys `main` to Cloudflare.

| Name | Kind | Value |
| --- | --- | --- |
| `CLOUDFLARE_API_TOKEN` | secret | Cloudflare → My Profile → API Tokens → "Edit Cloudflare Workers" template, limited to your account and the `ayungavis.com` zone |
| `CLOUDFLARE_ACCOUNT_ID` | variable | Cloudflare dashboard → Workers & Pages → Account ID |
| `APP_STORE_ID` | variable | Optional. The numeric Apple ID from App Store Connect; turns "Coming soon" into a download button and adds the Smart App Banner |

</details>

## License

Code is licensed under the [Apache License 2.0](LICENSE). See [NOTICE](NOTICE).

## Trademarks

The name "Poopita", the app icon and the mascot artwork are not covered by the Apache License. Forks and redistributed builds must use a different name and icon.
