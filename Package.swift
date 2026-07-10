// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CodexCompanion",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CodexCompanionCore", targets: ["CodexCompanionCore"]),
        .executable(name: "CodexCompanion", targets: ["CodexCompanion"]),
        .executable(name: "CodexCompanionTestRunner", targets: ["CodexCompanionTestRunner"]),
    ],
    targets: [
        .target(name: "CodexCompanionCore"),
        .executableTarget(name: "CodexCompanion", dependencies: ["CodexCompanionCore"]),
        .executableTarget(name: "CodexCompanionTestRunner", dependencies: ["CodexCompanionCore"]),
    ]
)
