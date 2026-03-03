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
}
#endif
