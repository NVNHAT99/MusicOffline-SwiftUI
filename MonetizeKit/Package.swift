// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "MonetizeKit",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "MonetizeKit", targets: ["MonetizeKit"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "MonetizeKit", dependencies: []),
        .testTarget(name: "MonetizeKitTests", dependencies: ["MonetizeKit"]),
    ]
)