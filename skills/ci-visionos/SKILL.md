---
name: ci-visionos
description: visionOS lens on CI/CD and automation. Load alongside agent-skills:ci-cd-and-automation for the generic automated-quality-gates discipline. This skill adds visionOS-specific runner requirements, pipeline stages (privacy scans, entitlement verification), and worked GitHub Actions + Xcode Cloud configurations.
---

# CI/CD for visionOS - Lens

## How to Use This Skill

Load `agent-skills:ci-cd-and-automation` for the generic discipline. Use
this skill for visionOS-specific CI concerns and working pipeline
configurations.

## Runner Requirements

visionOS builds need a runner with:
- macOS 15 or newer
- Xcode with the visionOS SDK (26.x)
- Apple Vision Pro simulator runtime available

| Runner | Fits out of box? |
|---|---|
| Xcode Cloud | Yes |
| GitHub Actions `macos-15` | Yes, with explicit Xcode version select |
| GitHub Actions `macos-14` | May need Xcode upgrade step |
| Self-hosted macOS | Works if maintained |

## Pipeline Stages

Minimum pipeline:

1. **Checkout**
2. **Xcode select** - pin explicitly
3. **Resolve dependencies** - SwiftPM, pods, submodules
4. **Build** - `xcodebuild build -scheme <s> -destination 'platform=visionOS Simulator,name=Apple Vision Pro'`
5. **Test** - `xcodebuild test` with a visionOS simulator destination
6. **Lint** - SwiftLint, SwiftFormat check
7. **Privacy scan** - verify `.entitlements` and `Info.plist` against an allow-list
8. **Archive** - release branches only
9. **Upload** - `asc` CLI for TestFlight, on tagged releases only

## Worked Example 1: GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  build-and-test:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_26.1.app

      - name: Show Xcode version
        run: xcodebuild -version

      - name: Cache DerivedData
        uses: actions/cache@v4
        with:
          path: ~/Library/Developer/Xcode/DerivedData
          key: ${{ runner.os }}-xcode-26-${{ hashFiles('**/Package.resolved') }}

      - name: Build for visionOS simulator
        run: |
          xcodebuild build \
            -scheme MyApp \
            -destination 'platform=visionOS Simulator,name=Apple Vision Pro,OS=26.1' \
            -derivedDataPath .build \
            CODE_SIGNING_ALLOWED=NO

      - name: Run tests
        run: |
          xcodebuild test \
            -scheme MyAppTests \
            -destination 'platform=visionOS Simulator,name=Apple Vision Pro,OS=26.1' \
            -derivedDataPath .build

      - name: SwiftLint
        run: brew install swiftlint && swiftlint --strict

      - name: Privacy scan
        run: ./scripts/privacy-scan.sh
```

## Worked Example 2: Privacy Scan Script

```bash
#!/usr/bin/env bash
# scripts/privacy-scan.sh
# Verify Info.plist and .entitlements against an allow-list.
# Run in CI; fail if the set drifts without explicit update.

set -euo pipefail

INFO_PLIST="MyApp/Info.plist"
ENTITLEMENTS="MyApp/MyApp.entitlements"
ALLOW_LIST=".ci/allowed-privacy-keys.txt"

if [ ! -f "$ALLOW_LIST" ]; then
  echo "Missing $ALLOW_LIST - cannot scan"
  exit 1
fi

# Extract current usage descriptions
ACTUAL_PRIVACY_KEYS=$(
  /usr/libexec/PlistBuddy -c "Print" "$INFO_PLIST" \
    | grep -E "^\s+NS\w+UsageDescription\b" \
    | awk '{print $1}' \
    | sort -u
)

# Extract current entitlements
ACTUAL_ENTITLEMENTS=$(
  /usr/libexec/PlistBuddy -c "Print" "$ENTITLEMENTS" \
    | grep -E "^\s+com\.apple\." \
    | awk '{print $1}' \
    | sort -u
)

ALL_ACTUAL=$(echo -e "$ACTUAL_PRIVACY_KEYS\n$ACTUAL_ENTITLEMENTS" | sort -u)

# Compare against allow-list
DRIFT=$(comm -23 <(echo "$ALL_ACTUAL") <(sort -u "$ALLOW_LIST"))

if [ -n "$DRIFT" ]; then
  echo "Privacy/entitlement drift detected. New keys require explicit review:"
  echo "$DRIFT"
  echo ""
  echo "If these additions are intentional, update $ALLOW_LIST in the same commit."
  exit 1
fi

echo "Privacy scan passed. No unexpected keys."
```

With `.ci/allowed-privacy-keys.txt`:

```
NSHandsTrackingUsageDescription
NSWorldSensingUsageDescription
NSCameraUsageDescription
com.apple.developer.arkit.hand-tracking
com.apple.security.app-sandbox
```

New entitlements or privacy keys fail CI until explicitly added to the
allow-list, which requires explicit review.

## Worked Example 3: Xcode Cloud Workflow

Xcode Cloud workflows are configured in the Xcode IDE, then committed as
`.xcode-cloud-workflow` definitions. For a typical visionOS app:

### Workflow: PR Build

- **Start condition:** pull request opened or updated
- **Environment:** Xcode 26.1 on macOS 15
- **Actions:**
  - Build: `MyApp` scheme, visionOS simulator
  - Test: `MyAppTests` scheme, visionOS simulator
  - Analyze: static analysis
- **Post-actions:**
  - Notify: Slack on failure

### Workflow: Release Tag

- **Start condition:** tag matching `v*` pushed
- **Environment:** Xcode 26.1 on macOS 15
- **Actions:**
  - Build: `MyApp` scheme, Any visionOS Device
  - Archive: yes
  - Analyze: yes
- **Post-actions:**
  - TestFlight: internal group
  - Notify: Slack on complete

Xcode Cloud handles signing automatically when the project is properly
configured in App Store Connect. No need to store `.p8` keys.

## Worked Example 4: asc CLI Upload (GitHub Actions Alternative)

If you're not using Xcode Cloud for distribution:

```yaml
release:
  needs: build-and-test
  if: startsWith(github.ref, 'refs/tags/v')
  runs-on: macos-15
  steps:
    - uses: actions/checkout@v4

    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_26.1.app

    - name: Import signing certs
      uses: apple-actions/import-codesign-certs@v3
      with:
        p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
        p12-password: ${{ secrets.CERTIFICATES_P12_PASSWORD }}

    - name: Import provisioning profile
      uses: apple-actions/download-provisioning-profiles@v3
      with:
        bundle-id: com.example.myapp
        issuer-id: ${{ secrets.ASC_ISSUER_ID }}
        api-key-id: ${{ secrets.ASC_API_KEY_ID }}
        api-private-key: ${{ secrets.ASC_API_PRIVATE_KEY }}

    - name: Archive
      run: |
        xcodebuild archive \
          -scheme MyApp \
          -archivePath build/MyApp.xcarchive \
          -destination 'generic/platform=visionOS'

    - name: Export IPA
      run: |
        xcodebuild -exportArchive \
          -archivePath build/MyApp.xcarchive \
          -exportPath build/export \
          -exportOptionsPlist .ci/ExportOptions.plist

    - name: Upload to TestFlight
      run: |
        asc auth login --issuer-id ${{ secrets.ASC_ISSUER_ID }} \
                      --key-id ${{ secrets.ASC_API_KEY_ID }} \
                      --private-key-path <(echo "${{ secrets.ASC_API_PRIVATE_KEY }}")
        asc testflight upload --ipa build/export/MyApp.ipa
```

## Branch Protection

Protect `main` with these required checks:
- Build passes for visionOS simulator
- Tests pass
- Lint passes
- Privacy scan passes
- `.entitlements` changes require code owner review
- `Info.plist` privacy key changes require code owner review

## Cache Strategy

Invalidate on:
- Xcode version change
- SwiftPM `Package.resolved` change
- `.xcconfig` change

Cache keys should include these so upgrades bust the cache correctly.

## Xcode Cloud vs GitHub Actions

| Factor | Xcode Cloud | GitHub Actions |
|---|---|---|
| Setup time | Minutes | Hours |
| Cost | Per-compute-hour after free tier | Per-minute after free tier |
| Apple-native integration | Yes | No |
| Custom shell scripts | Limited | Full |
| Third-party action ecosystem | No | Yes |
| Signing complexity | Managed | Manual (.p8, profiles, certs) |
| Secret management | Apple ecosystem | GitHub |

Choose Xcode Cloud for small teams with standard workflows. GitHub Actions
when you need custom pipelines or non-Apple build steps.

## When To Switch Skills

- `packaging-distribution` - for archive and TestFlight mechanics
- `ui-automation` - for CI screenshot diffs using AXe
- `test-triage` - when CI tests fail and need classification
- `signing-entitlements` - when CI signing fails
- `agent-skills:ci-cd-and-automation` - for generic pipeline design

## Guardrails

- Never commit `.p8` keys, signing certs, or provisioning profiles to source
- Never skip the privacy scan check
- Never auto-upload on every merge - tag-triggered only
- Never bypass branch protection for `.entitlements` changes
- Always pin the Xcode version - do not rely on the runner default
