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
        .library(name: "RynBridgePushFCM", targets: ["RynBridgePushFCM"]),
        .library(name: "RynBridgeShareKakao", targets: ["RynBridgeShareKakao"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0"),
        .package(url: "https://github.com/kakao/kakao-ios-sdk", from: "2.27.0"),
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
            name: "RynBridgeWebView",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeWebView"
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
        .target(
            name: "RynBridgeCalendar",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeCalendar"
        ),
        .target(
            name: "RynBridgeContacts",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeContacts"
        ),
        .target(
            name: "RynBridgeShare",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeShare"
        ),
        .target(
            name: "RynBridgeNavigation",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeNavigation"
        ),
        .target(
            name: "RynBridgeAnalytics",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeAnalytics"
        ),
        .target(
            name: "RynBridgeAuthApple",
            dependencies: ["RynBridge", "RynBridgeAuth"],
            path: "Sources/RynBridgeAuthApple"
        ),
        .target(
            name: "RynBridgePushAPNs",
            dependencies: ["RynBridge", "RynBridgePush"],
            path: "Sources/RynBridgePushAPNs"
        ),
        .target(
            name: "RynBridgePushFCM",
            dependencies: [
                "RynBridge",
                "RynBridgePush",
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
            ],
            path: "Sources/RynBridgePushFCM"
        ),
        .target(
            name: "RynBridgePaymentStoreKit",
            dependencies: ["RynBridge", "RynBridgePayment"],
            path: "Sources/RynBridgePaymentStoreKit"
        ),
        .target(
            name: "RynBridgeSpeech",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeSpeech"
        ),
        .target(
            name: "RynBridgeTranslation",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeTranslation"
        ),
        .target(
            name: "RynBridgeBluetooth",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeBluetooth"
        ),
        .target(
            name: "RynBridgeHealth",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeHealth"
        ),
        .target(
            name: "RynBridgeBackgroundTask",
            dependencies: ["RynBridge"],
            path: "Sources/RynBridgeBackgroundTask"
        ),
        .target(
            name: "RynBridgeShareKakao",
            dependencies: [
                "RynBridge",
                .product(name: "KakaoSDKCommon", package: "kakao-ios-sdk"),
                .product(name: "KakaoSDKShare", package: "kakao-ios-sdk"),
                .product(name: "KakaoSDKTemplate", package: "kakao-ios-sdk"),
            ],
            path: "Sources/RynBridgeShareKakao"
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
            name: "RynBridgeWebViewTests",
            dependencies: ["RynBridge", "RynBridgeWebView"],
            path: "Tests/RynBridgeWebViewTests"
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
        .testTarget(
            name: "RynBridgeCalendarTests",
            dependencies: ["RynBridge", "RynBridgeCalendar"],
            path: "Tests/RynBridgeCalendarTests"
        ),
        .testTarget(
            name: "RynBridgeShareTests",
            dependencies: ["RynBridge", "RynBridgeShare"],
            path: "Tests/RynBridgeShareTests"
        ),
        .testTarget(
            name: "RynBridgeContactsTests",
            dependencies: ["RynBridge", "RynBridgeContacts"],
            path: "Tests/RynBridgeContactsTests"
        ),
        .testTarget(
            name: "RynBridgeNavigationTests",
            dependencies: ["RynBridge", "RynBridgeNavigation"],
            path: "Tests/RynBridgeNavigationTests"
        ),
        .testTarget(
            name: "RynBridgeAnalyticsTests",
            dependencies: ["RynBridge", "RynBridgeAnalytics"],
            path: "Tests/RynBridgeAnalyticsTests"
        ),
        .testTarget(
            name: "RynBridgeSpeechTests",
            dependencies: ["RynBridge", "RynBridgeSpeech"],
            path: "Tests/RynBridgeSpeechTests"
        ),
        .testTarget(
            name: "RynBridgeTranslationTests",
            dependencies: ["RynBridge", "RynBridgeTranslation"],
            path: "Tests/RynBridgeTranslationTests"
        ),
        .testTarget(
            name: "RynBridgeBluetoothTests",
            dependencies: ["RynBridge", "RynBridgeBluetooth"],
            path: "Tests/RynBridgeBluetoothTests"
        ),
        .testTarget(
            name: "RynBridgeHealthTests",
            dependencies: ["RynBridge", "RynBridgeHealth"],
            path: "Tests/RynBridgeHealthTests"
        ),
        .testTarget(
            name: "RynBridgeBackgroundTaskTests",
            dependencies: ["RynBridge", "RynBridgeBackgroundTask"],
            path: "Tests/RynBridgeBackgroundTaskTests"
        ),
        .testTarget(
            name: "RynBridgePushAPNsTests",
            dependencies: ["RynBridge", "RynBridgePushAPNs"],
            path: "Tests/RynBridgePushAPNsTests"
        ),
        .testTarget(
            name: "RynBridgePushFCMTests",
            dependencies: ["RynBridge", "RynBridgePushFCM"],
            path: "Tests/RynBridgePushFCMTests"
        ),
        .testTarget(
            name: "RynBridgeShareKakaoTests",
            dependencies: ["RynBridge", "RynBridgeShareKakao"],
            path: "Tests/RynBridgeShareKakaoTests"
        ),
    ]
)
