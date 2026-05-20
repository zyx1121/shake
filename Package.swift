// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Shake",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Shake",
            path: "Sources/Shake"
        )
    ]
)
