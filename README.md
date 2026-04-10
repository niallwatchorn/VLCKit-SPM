# VLCKit-SPM

`VLCKit-SPM` is a Swift Package Manager wrapper for the official prebuilt [VLCKit](https://code.videolan.org/videolan/VLCKit) binary distributed by VideoLAN.

This repository exists to make `VLCKit` easy to consume from Swift Package Manager without depending on CocoaPods and without waiting for a third-party wrapper repository to publish updates.

## What This Repository Provides

This package publishes a single SwiftPM library product:

- `VLCKitSPM`

Your app imports:

```swift
import VLCKitSPM
```

The package re-exports the upstream `VLCKit` module, so consumers do not need to interact with the binary target directly.

## Why This Exists

At the time this repository was created, `VLCKit` was still primarily distributed for Apple platforms through CocoaPods-oriented binaries. This repository repackages the official VideoLAN binary as a GitHub release asset that Swift Package Manager can consume directly.

## Supported Platforms

This package is intended for the Apple platform slices included by the upstream `VLCKit.xcframework`. The current package manifest declares support for:

- iOS
- tvOS
- macOS
- visionOS

Actual support depends on the slices present in the upstream framework bundle for a given VLCKit release.

## Installation

Add this repository as a Swift Package dependency in Xcode:

- URL: `https://github.com/niallwatchorn/VLCKit-SPM.git`

Or declare it in another Swift package:

```swift
.package(url: "https://github.com/niallwatchorn/VLCKit-SPM.git", from: "4.0.0-alpha.19")
```

Then add the product to your target dependencies:

```swift
.product(name: "VLCKitSPM", package: "VLCKit-SPM")
```

Import it in your code:

```swift
import VLCKitSPM
```

## How Releases Work

This repository does not build VLCKit from source.

Instead, each release follows this flow:

1. Obtain the official prebuilt `VLCKit.xcframework` from VideoLAN.
2. Zip that framework in the format expected by Swift Package Manager.
3. Compute the binary checksum.
4. Publish the zip file as a GitHub release asset in this repository.
5. Point `Package.swift` at that GitHub-hosted asset.

This means:

- the binary content comes from VideoLAN
- the SwiftPM artifact URL comes from this GitHub repository

## Updating To A New VLCKit Release

The repository includes a helper script, `generate.sh`, which:

- accepts a local `VLCKit.xcframework` or a downloadable archive
- creates `Artifacts/VLCKit.xcframework.zip`
- computes the SwiftPM checksum
- updates `Package.swift`
- refreshes the local license file when available

### Using A Local Framework

If you have already downloaded and extracted the VideoLAN artifact:

```sh
./generate.sh \
  --version 4.0.0a19 \
  --repo-url https://github.com/niallwatchorn/VLCKit-SPM \
  --source-path ~/<YOUR_NAME>/Downloads/VLCKit-binary/VLCKit.xcframework
```

### Using A Remote Artifact URL

If VideoLAN exposes a direct artifact archive URL:

```sh
./generate.sh \
  --version 4.0.0a19 \
  --repo-url https://github.com/niallwatchorn/VLCKit-SPM \
  --source-url "PASTE_THE_DIRECT_VLCKIT_ARTIFACT_URL_HERE"
```

Supported source archive formats:

- `.zip`
- `.tar`
- `.tar.gz`
- `.tar.bz2`
- `.tar.xz`

Important: a source-code archive is not enough. The input must contain a built `VLCKit.xcframework`.

## Publishing A New Package Release

After running `generate.sh` successfully:

1. Commit the updated repository files.
2. Push the branch and the matching tag.
3. Create a GitHub release for that tag.
4. Upload `Artifacts/VLCKit.xcframework.zip` to the release.

The package uses semver-friendly tags for SwiftPM compatibility. For example:

- upstream VLCKit version: `4.0.0a19`
- package release tag: `4.0.0-alpha.19`

## Repository Structure

- `Package.swift`: SwiftPM manifest
- `generate.sh`: packaging helper script
- `Sources/VLCKitSPM/Export.swift`: re-exports the `VLCKit` module

## License

This repository is a packaging wrapper around the official VLCKit binary.

The bundled framework remains subject to VideoLAN's licensing terms. See `LICENSE` and the upstream VLCKit project for full details.
