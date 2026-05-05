# Peeply

Peeply is an iOS app built with SwiftUI.

## Requirements

- macOS with a recent version of Xcode
- GitHub access to this repository
- Apple Developer account access if you need to run on a physical device or manage signing
- Internet access to resolve Swift Package Manager dependencies

## Project setup

1. Clone the repository:
   ```bash
   git clone https://github.com/peeplyapp/Peeply.git
   cd Peeply
   ```

2. Open the project in Xcode:
   - Open `Peeply.xcodeproj`

3. Let Xcode resolve Swift Package Manager dependencies.

4. Select the `Peeply` scheme.

5. Choose an iPhone simulator and run the app.

## Dependencies

This project currently resolves package dependencies through Swift Package Manager, including:

- RevenueCat
- GoMarketMe

## Build

From Xcode:
- Press `Cmd+B` to build
- Press `Cmd+R` to run

From Terminal:
```bash
xcodebuild -project Peeply.xcodeproj -scheme Peeply -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Test

Run tests from Xcode with `Cmd+U` or from Terminal:

```bash
xcodebuild test \
  -project Peeply.xcodeproj \
  -scheme Peeply \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## RevenueCat and secrets

RevenueCat’s iOS SDK should be configured with a **public SDK key only**. Do not commit secret keys, especially keys prefixed with `sk_`, certificates, private keys, or provisioning profiles to this repository. [web:65][web:68]

If local configuration is needed later, keep it out of Git and document setup steps here.

## Branching and pull requests

- Do not commit directly to `main`
- Create a feature or fix branch for every change
- Open a pull request for review
- Make sure CI passes before merging

Example branch names:
- `feature/contact-search`
- `fix/onboarding-crash`
- `chore/update-ci`

## Recommended commit style

Use short, descriptive commit messages, for example:
- `Add contact detail empty state`
- `Fix splash screen routing for returning users`
- `Add CI workflow for build and tests`

## Repository standards

This repository is expected to use:
- Pull request reviews
- Branch protection on `main`
- CODEOWNERS
- GitHub Actions CI

## Notes for contributors

Before opening a PR:
- Build the app locally
- Run tests locally
- Include screenshots for UI changes
- Note any config or dependency changes in the PR description