// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TimerPro",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "TimerPro",
            path: "Sources/TimerPro",
            exclude: ["Resources/Info.plist"]
        )
    ]
)
