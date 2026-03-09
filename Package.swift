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
        .library(name: "RynBridgeWebView", targets: ["RynBridgeWebView"]),
        .library(name: "RynBridgeAuth", targets: ["RynBridgeAuth"]),
        .library(name: "RynBridgePush", targets: ["RynBridgePush"]),
        .library(name: "RynBridgePayment", targets: ["RynBridgePayment"]),
        .library(name: "RynBridgeMedia", targets: ["RynBridgeMedia"]),
        .library(name: "RynBridgeCrypto", targets: ["RynBridgeCrypto"]),
        .library(name: "RynBridgeCalendar", targets: ["RynBridgeCalendar"]),
        .library(name: "RynBridgeContacts", targets: ["RynBridgeContacts"]),
        .library(name: "RynBridgeShare", targets: ["RynBridgeShare"]),
        .library(name: "RynBridgeNavigation", targets: ["RynBridgeNavigation"]),
        .library(name: "RynBridgeAnalytics", targets: ["RynBridgeAnalytics"]),
        .library(name: "RynBridgeAuthApple", targets: ["RynBridgeAuthApple"]),
        .library(name: "RynBridgePushAPNs", targets: ["RynBridgePushAPNs"]),
        .library(name: "RynBridgePaymentStoreKit", targets: ["RynBridgePaymentStoreKit"]),
        .library(name: "RynBridgeSpeech", targets: ["RynBridgeSpeech"]),
        .library(name: "RynBridgeTranslation", targets: ["RynBridgeTranslation"]),
        .library(name: "RynBridgeBluetooth", targets: ["RynBridgeBluetooth"]),
        .library(name: "RynBridgeHealth", targets: ["RynBridgeHealth"]),
        .library(name: "RynBridgeBackgroundTask", targets: ["RynBridgeBackgroundTask"]),
        .library(name: "RynBridgeShareKakao", targets: ["RynBridgeShareKakao"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kakao/kakao-ios-sdk", from: "2.27.0"),
    ],
    targets: [
        .target(
            name: "RynBridge",
            path: "ios/Sources/RynBridge"
        ),
        .target(
            name: "RynBridgeDevice",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeDevice"
        ),
        .target(
            name: "RynBridgeStorage",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeStorage"
        ),
        .target(
            name: "RynBridgeSecureStorage",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeSecureStorage"
        ),
        .target(
            name: "RynBridgeUI",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeUI"
        ),
        .target(
            name: "RynBridgeWebView",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeWebView"
        ),
        .target(
            name: "RynBridgeAuth",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeAuth"
        ),
        .target(
            name: "RynBridgePush",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgePush"
        ),
        .target(
            name: "RynBridgePayment",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgePayment"
        ),
        .target(
            name: "RynBridgeMedia",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeMedia"
        ),
        .target(
            name: "RynBridgeCrypto",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeCrypto"
        ),
        .target(
            name: "RynBridgeCalendar",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeCalendar"
        ),
        .target(
            name: "RynBridgeContacts",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeContacts"
        ),
        .target(
            name: "RynBridgeShare",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeShare"
        ),
        .target(
            name: "RynBridgeNavigation",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeNavigation"
        ),
        .target(
            name: "RynBridgeAnalytics",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeAnalytics"
        ),
        .target(
            name: "RynBridgeAuthApple",
            dependencies: ["RynBridge", "RynBridgeAuth"],
            path: "ios/Sources/RynBridgeAuthApple"
        ),
        .target(
            name: "RynBridgePushAPNs",
            dependencies: ["RynBridge", "RynBridgePush"],
            path: "ios/Sources/RynBridgePushAPNs"
        ),
        .target(
            name: "RynBridgePaymentStoreKit",
            dependencies: ["RynBridge", "RynBridgePayment"],
            path: "ios/Sources/RynBridgePaymentStoreKit"
        ),
        .target(
            name: "RynBridgeSpeech",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeSpeech"
        ),
        .target(
            name: "RynBridgeTranslation",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeTranslation"
        ),
        .target(
            name: "RynBridgeBluetooth",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeBluetooth"
        ),
        .target(
            name: "RynBridgeHealth",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeHealth"
        ),
        .target(
            name: "RynBridgeBackgroundTask",
            dependencies: ["RynBridge"],
            path: "ios/Sources/RynBridgeBackgroundTask"
        ),
        .target(
            name: "RynBridgeShareKakao",
            dependencies: [
                "RynBridge",
                .product(name: "KakaoSDKCommon", package: "KakaoOpenSDK"),
                .product(name: "KakaoSDKShare", package: "KakaoOpenSDK"),
                .product(name: "KakaoSDKTemplate", package: "KakaoOpenSDK"),
            ],
            path: "ios/Sources/RynBridgeShareKakao"
        ),
    ]
)
