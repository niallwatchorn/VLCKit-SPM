# VLCKit-SPM

This repository is a thin Swift Package Manager wrapper around the official prebuilt `VLCKit.xcframework` published by VideoLAN.

It exists so you can:

- publish your own SPM-compatible VLCKit package
- update to new VLCKit drops without waiting for a third-party wrapper
- keep your app dependencies on Swift Package Manager instead of CocoaPods

## What This Package Does

The package exposes a single SwiftPM library product named `VLCKitSPM`.

Your apps import:

```swift
import VLCKitSPM
```

Internally, that target re-exports the upstream `VLCKit` binary framework.

## Repository Layout

- `Package.swift`: SwiftPM manifest that points to your hosted `.xcframework.zip`
- `Sources/VLCKitSPM/Export.swift`: re-exports the upstream `VLCKit` module
- `generate.sh`: downloads the official VideoLAN archive, zips the `VLCKit.xcframework`, computes the checksum, and updates `Package.swift`

## First-Time Setup

1. Create a GitHub repository for this project.
2. Update the package by running:

```sh
./generate.sh \
  --version 4.0.0a19 \
  --repo-url https://github.com/niallwatchorn/VLCKit-SPM \
  --source-path /Users/niall/Downloads/VLCKit-binary/VLCKit.xcframework
```

3. Commit the generated changes.
4. Push the repository to GitHub.
5. Create a GitHub release using the tag written into `Package.swift`.
6. Upload `Artifacts/VLCKit.xcframework.zip` to that release.

The script converts VideoLAN versions like `4.0.0a19` into semver-friendly package tags like `4.0.0-alpha.19`, because Swift Package Manager works best with semantic version tags.

## Updating To A New VLCKit Build

When VideoLAN publishes a new alpha or stable build:

```sh
./generate.sh \
  --version 4.0.0a19 \
  --repo-url https://github.com/niallwatchorn/VLCKit-SPM \
  --source-path /Users/niall/Downloads/VLCKit-binary/VLCKit.xcframework
```

If VideoLAN publishes the build through the GitLab tag page first, pass the exact archive or artifact URL:

```sh
./generate.sh \
  --version 4.0.0a19 \
  --repo-url https://github.com/niallwatchorn/VLCKit-SPM \
  --source-url "PASTE_THE_DIRECT_VLCKIT_ARTIFACT_URL_HERE"
```

The script accepts `.zip`, `.tar`, `.tar.gz`, `.tar.bz2`, and `.tar.xz` archives. What matters is that the downloaded archive contains a built `VLCKit.xcframework`. A GitLab "source code zip" will not work unless it already includes the built framework.

You can also point it directly at a local extracted framework directory:

```sh
./generate.sh \
  --version 4.0.0a19 \
  --repo-url https://github.com/niallwatchorn/VLCKit-SPM \
  --source-path /Users/niall/Downloads/VLCKit-binary/VLCKit.xcframework
```

Then:

1. commit the updated files
2. push the new tag
3. upload the new zip to the matching GitHub release

## Using This Package In Your Apps

In Xcode, add your GitHub repository as a package dependency.

If you are declaring it in another Swift package:

```swift
.package(url: "https://github.com/niallwatchorn/VLCKit-SPM.git", from: "4.0.0-alpha.19")
```

Then add the product:

```swift
.product(name: "VLCKitSPM", package: "VLCKit-SPM")
```

## Notes

- VLCKit 4.x is a unified Apple-platform framework, so this wrapper targets the single `VLCKit.xcframework` layout instead of the older `MobileVLCKit` plus `TVVLCKit` split.
- The package declares support for `iOS`, `tvOS`, `macOS`, and `visionOS`. Actual platform availability still depends on the slices included by the upstream VLCKit build you package.
- The bundled binary remains subject to VideoLAN's licensing terms.
