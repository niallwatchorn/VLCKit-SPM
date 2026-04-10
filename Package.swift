// swift-tools-version: 5.9

import PackageDescription

let vlcUpstreamVersion = "4.0.0a19"
let vlcReleaseTag = "4.0.0-alpha.19"
let vlcReleaseBaseURL = "https://github.com/niallwatchorn/VLCKit-SPM/releases/download"
let vlcChecksum = "54b1efd946c658fe1036919a8abfc011231048e28751c56c376bb51aa4019aa0"
let vlcBinaryURL = "\(vlcReleaseBaseURL)/\(vlcReleaseTag)/VLCKit.xcframework.zip"

let package = Package(
    name: "VLCKit-SPM",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .macOS(.v10_15),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "VLCKitSPM",
            targets: ["VLCKitSPM"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "VLCKitBinary",
            url: vlcBinaryURL,
            checksum: vlcChecksum
        ),
        .target(
            name: "VLCKitSPM",
            dependencies: ["VLCKitBinary"],
            path: "Sources/VLCKitSPM"
        ),
    ]
)
