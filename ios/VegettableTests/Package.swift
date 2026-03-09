// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "VegettableTests",
    platforms: [.macOS(.v13)],
    targets: [
        .testTarget(
            name: "VegettableTests",
            path: "Tests"
        )
    ]
)