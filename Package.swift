// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Stamp",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Stamp",
            path: "Sources/Stamp"
        )
    ]
)
