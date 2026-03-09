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
import AVFoundation
import CoreLocation
import LocalAuthentication

public final class DefaultDeviceInfoProvider: NSObject, DeviceInfoProvider, CLLocationManagerDelegate, @unchecked Sendable {
    private var locationContinuation: CheckedContinuation<LocationInfo, any Error>?
    private let locationManager = CLLocationManager()

    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

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
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                guard let viewController = Self.topViewController() else {
                    continuation.resume(throwing: RynBridgeError(code: .unknown, message: "No view controller available"))
                    return
                }

                guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                    continuation.resume(throwing: RynBridgeError(code: .unknown, message: "Camera not available"))
                    return
                }

                let picker = CameraPickerCoordinator(quality: quality, continuation: continuation)
                let imagePicker = UIImagePickerController()
                imagePicker.sourceType = .camera
                imagePicker.cameraDevice = camera == "front" ? .front : .rear
                imagePicker.delegate = picker
                // Retain coordinator until picker is dismissed
                objc_setAssociatedObject(imagePicker, "coordinator", picker, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                viewController.present(imagePicker, animated: true)
            }
        }
    }

    public func getLocation() async throws -> LocationInfo {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .denied || status == .restricted {
            throw RynBridgeError(code: .unknown, message: "Location permission denied")
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    public func authenticate(reason: String) async throws -> AuthenticateResult {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw RynBridgeError(code: .unknown, message: error?.localizedDescription ?? "Biometric authentication not available")
        }
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            return AuthenticateResult(success: success)
        } catch {
            return AuthenticateResult(success: false)
        }
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let info = LocationInfo(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: location.horizontalAccuracy
        )
        locationContinuation?.resume(returning: info)
        locationContinuation = nil
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        locationContinuation?.resume(throwing: RynBridgeError(code: .unknown, message: error.localizedDescription))
        locationContinuation = nil
    }

    // MARK: - Helpers

    @MainActor
    private static func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first,
              let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}

// MARK: - Camera Picker Coordinator

private class CameraPickerCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let quality: Double
    let continuation: CheckedContinuation<CapturePhotoResult, any Error>
    private var didResume = false

    init(quality: Double, continuation: CheckedContinuation<CapturePhotoResult, any Error>) {
        self.quality = quality
        self.continuation = continuation
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard !didResume else { return }
        didResume = true

        guard let image = info[.originalImage] as? UIImage else {
            continuation.resume(throwing: RynBridgeError(code: .unknown, message: "Failed to capture image"))
            return
        }
        guard let data = image.jpegData(compressionQuality: CGFloat(quality)) else {
            continuation.resume(throwing: RynBridgeError(code: .unknown, message: "Failed to compress image"))
            return
        }
        let base64 = data.base64EncodedString()
        let result = CapturePhotoResult(
            imageBase64: base64,
            width: Int(image.size.width),
            height: Int(image.size.height)
        )
        continuation.resume(returning: result)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        guard !didResume else { return }
        didResume = true
        continuation.resume(throwing: RynBridgeError(code: .unknown, message: "Camera cancelled"))
    }
}
#endif
