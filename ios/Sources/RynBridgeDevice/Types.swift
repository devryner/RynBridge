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

public protocol DeviceInfoProvider: Sendable {
    func getDeviceInfo() -> DeviceInfo
    func getBatteryInfo() -> BatteryInfo
    func getScreenInfo() -> ScreenInfo
    func vibrate(pattern: [Int])
}
