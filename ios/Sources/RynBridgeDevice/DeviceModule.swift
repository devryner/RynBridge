import Foundation
import RynBridge

public struct DeviceModule: BridgeModule, Sendable {
    public let name = "device"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: DeviceInfoProvider) {
        actions = [
            "getInfo": { _ in
                provider.getDeviceInfo().toPayload()
            },
            "getBattery": { _ in
                provider.getBatteryInfo().toPayload()
            },
            "getScreen": { _ in
                provider.getScreenInfo().toPayload()
            },
            "vibrate": { payload in
                let pattern: [Int]
                if let arr = payload["pattern"]?.arrayValue {
                    pattern = arr.compactMap { $0.intValue }
                } else {
                    pattern = []
                }
                provider.vibrate(pattern: pattern)
                return [:]
            },
            "capturePhoto": { payload in
                let quality = payload["quality"]?.doubleValue ?? 0.8
                let camera = payload["camera"]?.stringValue ?? "back"
                let result = try await provider.capturePhoto(quality: quality, camera: camera)
                return result.toPayload()
            },
            "getLocation": { _ in
                let location = try await provider.getLocation()
                return location.toPayload()
            },
            "authenticate": { payload in
                guard let reason = payload["reason"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: reason")
                }
                let result = try await provider.authenticate(reason: reason)
                return result.toPayload()
            },
        ]
    }
}

#if canImport(UIKit)
import UIKit
import AudioToolbox

public final class DefaultDeviceInfoProvider: DeviceInfoProvider, @unchecked Sendable {
    public init() {}

    public func getDeviceInfo() -> DeviceInfo {
        let device = UIDevice.current
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        return DeviceInfo(
            platform: "ios",
            osVersion: device.systemVersion,
            model: device.model,
            appVersion: appVersion
        )
    }

    public func getBatteryInfo() -> BatteryInfo {
        let device = UIDevice.current
        let wasEnabled = device.isBatteryMonitoringEnabled
        device.isBatteryMonitoringEnabled = true
        let level = Int(device.batteryLevel * 100)
        let isCharging = device.batteryState == .charging || device.batteryState == .full
        if !wasEnabled { device.isBatteryMonitoringEnabled = false }
        return BatteryInfo(level: max(level, 0), isCharging: isCharging)
    }

    public func getScreenInfo() -> ScreenInfo {
        let screen = UIScreen.main
        let bounds = screen.bounds
        let orientation: String
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
        if let ws = windowScene {
            orientation = ws.interfaceOrientation.isLandscape ? "landscape" : "portrait"
        } else {
            orientation = "portrait"
        }
        return ScreenInfo(
            width: bounds.width,
            height: bounds.height,
            scale: screen.scale,
            orientation: orientation
        )
    }

    public func vibrate(pattern: [Int]) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    public func capturePhoto(quality: Double, camera: String) async throws -> CapturePhotoResult {
        throw RynBridgeError(code: .unknown, message: "capturePhoto requires a custom provider implementation")
    }

    public func getLocation() async throws -> LocationInfo {
        throw RynBridgeError(code: .unknown, message: "getLocation requires a custom provider implementation")
    }

    public func authenticate(reason: String) async throws -> AuthenticateResult {
        throw RynBridgeError(code: .unknown, message: "authenticate requires a custom provider implementation")
    }
}
#endif
