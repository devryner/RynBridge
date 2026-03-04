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
        .library(name: "RynBridgeAuth", targets: ["RynBridgeAuth"]),
        .library(name: "RynBridgePush", targets: ["RynBridgePush"]),
        .library(name: "RynBridgePayment", targets: ["RynBridgePayment"]),
        .library(name: "RynBridgeMedia", targets: ["RynBridgeMedia"]),
        .library(name: "RynBridgeCrypto", targets: ["RynBridgeCrypto"]),
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
        .target(
            name: "RynBridgeAuth",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeAuth"
        ),
        .target(
            name: "RynBridgePush",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgePush"
        ),
        .target(
            name: "RynBridgePayment",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgePayment"
        ),
        .target(
            name: "RynBridgeMedia",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeMedia"
        ),
        .target(
            name: "RynBridgeCrypto",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeCrypto"
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
        .testTarget(
            name: "RynBridgeAuthTests",
            dependencies: ["RynBridge", "RynBridgeAuth"],
            path: "Tests/RynBridgeAuthTests"
        ),
        .testTarget(
            name: "RynBridgePushTests",
            dependencies: ["RynBridge", "RynBridgePush"],
            path: "Tests/RynBridgePushTests"
        ),
        .testTarget(
            name: "RynBridgePaymentTests",
            dependencies: ["RynBridge", "RynBridgePayment"],
            path: "Tests/RynBridgePaymentTests"
        ),
        .testTarget(
            name: "RynBridgeMediaTests",
            dependencies: ["RynBridge", "RynBridgeMedia"],
            path: "Tests/RynBridgeMediaTests"
        ),
        .testTarget(
            name: "RynBridgeCryptoTests",
            dependencies: ["RynBridge", "RynBridgeCrypto"],
            path: "Tests/RynBridgeCryptoTests"
        ),
    ]
)
