// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "RynBridge",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "RynBridge", targets: ["RynBridge"]),
        .library(name: "RynBridgeDevice", targets: ["RynBridgeDevice"]),
        .library(name: "RynBridgeStorage", targets: ["RynBridgeStorage"]),
        .library(name: "RynBridgeSecureStorage", targets: ["RynBridgeSecureStorage"]),
        .library(name: "RynBridgeUI", targets: ["RynBridgeUI"]),
    ],
    targets: [
        .target(
            name: "RynBridge",
            path: "Sources/RynBridge"
        ),
        .target(
            name: "RynBridgeDevice",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeDevice"
        ),
        .target(
            name: "RynBridgeStorage",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeStorage"
        ),
        .target(
            name: "RynBridgeSecureStorage",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeSecureStorage"
        ),
        .target(
            name: "RynBridgeUI",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeUI"
        ),
        .testTarget(
            name: "RynBridgeTests",
            dependencies: ["RynBridge"],
            path: "Tests/RynBridgeTests"
        ),
        .testTarget(
            name: "RynBridgeDeviceTests",
            dependencies: ["RynBridge", "RynBridgeDevice"],
            path: "Tests/RynBridgeDeviceTests"
        ),
        .testTarget(
            name: "RynBridgeStorageTests",
            dependencies: ["RynBridge", "RynBridgeStorage"],
            path: "Tests/RynBridgeStorageTests"
        ),
        .testTarget(
            name: "RynBridgeSecureStorageTests",
            dependencies: ["RynBridge", "RynBridgeSecureStorage"],
            path: "Tests/RynBridgeSecureStorageTests"
        ),
        .testTarget(
            name: "RynBridgeUITests",
            dependencies: ["RynBridge", "RynBridgeUI"],
            path: "Tests/RynBridgeUITests"
        ),
    ]
)
