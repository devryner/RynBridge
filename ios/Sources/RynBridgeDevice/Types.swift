import Foundation
import RynBridge

public struct DeviceInfo: Sendable {
    public let platform: String
    public let osVersion: String
    public let model: String
    public let appVersion: String

    public init(platform: String, osVersion: String, model: String, appVersion: String) {
        self.platform = platform
        self.osVersion = osVersion
        self.model = model
        self.appVersion = appVersion
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "platform": .string(platform),
            "osVersion": .string(osVersion),
            "model": .string(model),
            "appVersion": .string(appVersion),
        ]
    }
}

public struct BatteryInfo: Sendable {
    public let level: Int
    public let isCharging: Bool

    public init(level: Int, isCharging: Bool) {
        self.level = level
        self.isCharging = isCharging
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "level": .int(level),
            "isCharging": .bool(isCharging),
        ]
    }
}

public struct ScreenInfo: Sendable {
    public let width: Double
    public let height: Double
    public let scale: Double
    public let orientation: String

    public init(width: Double, height: Double, scale: Double, orientation: String) {
        self.width = width
        self.height = height
        self.scale = scale
        self.orientation = orientation
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "width": .double(width),
            "height": .double(height),
            "scale": .double(scale),
            "orientation": .string(orientation),
        ]
    }
}

public struct CapturePhotoOptions: Sendable {
    public let quality: Double
    public let camera: String

    public init(quality: Double = 0.8, camera: String = "back") {
        self.quality = quality
        self.camera = camera
    }
}

public struct CapturePhotoResult: Sendable {
    public let imageBase64: String
    public let width: Int
    public let height: Int

    public init(imageBase64: String, width: Int, height: Int) {
        self.imageBase64 = imageBase64
        self.width = width
        self.height = height
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "imageBase64": .string(imageBase64),
            "width": .int(width),
            "height": .int(height),
        ]
    }
}

public struct LocationInfo: Sendable {
    public let latitude: Double
    public let longitude: Double
    public let accuracy: Double

    public init(latitude: Double, longitude: Double, accuracy: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "latitude": .double(latitude),
            "longitude": .double(longitude),
            "accuracy": .double(accuracy),
        ]
    }
}

public struct AuthenticateResult: Sendable {
    public let success: Bool

    public init(success: Bool) {
        self.success = success
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "success": .bool(success),
        ]
    }
}

public protocol DeviceInfoProvider: Sendable {
    func getDeviceInfo() -> DeviceInfo
    func getBatteryInfo() -> BatteryInfo
    func getScreenInfo() -> ScreenInfo
    func vibrate(pattern: [Int])
    func capturePhoto(quality: Double, camera: String) async throws -> CapturePhotoResult
    func getLocation() async throws -> LocationInfo
    func authenticate(reason: String) async throws -> AuthenticateResult
}
