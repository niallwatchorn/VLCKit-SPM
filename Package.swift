// swift-tools-version: 5.9

import PackageDescription

let vlcUpstreamVersion = "4.0.0a23"
let vlcReleaseTag = "4.0.0-alpha.23"
let vlcReleaseBaseURL = "https://github.com/niallwatchorn/VLCKit-SPM/releases/download"
let vlcChecksum = "2368013239b8e33a1b3803053e0dbc0c83482ca0be9cf90e141d2559d41750b5"
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
