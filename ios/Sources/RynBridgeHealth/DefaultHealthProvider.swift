#if canImport(HealthKit)
import Foundation
import HealthKit
import RynBridge

public final class DefaultHealthProvider: HealthProvider, @unchecked Sendable {
    private let healthStore: HKHealthStore

    public init() {
        self.healthStore = HKHealthStore()
    }

    public func requestPermission(readTypes: [String], writeTypes: [String]) async throws -> Bool {
        let readSet = Set(readTypes.compactMap { quantityType(for: $0) as HKObjectType? })
        let writeSet = Set(writeTypes.compactMap { quantityType(for: $0) as HKSampleType? })
        try await healthStore.requestAuthorization(toShare: writeSet, read: readSet)
        return true
    }

    public func getPermissionStatus() async throws -> String {
        // Check a common type (steps) as a representative
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return "notDetermined"
        }
        let status = healthStore.authorizationStatus(for: stepsType)
        switch status {
        case .sharingAuthorized:
            return "granted"
        case .sharingDenied:
            return "denied"
        case .notDetermined:
            return "notDetermined"
        @unknown default:
            return "notDetermined"
        }
    }

    public func queryData(dataType: String, startDate: String, endDate: String, limit: Int?) async throws -> [[String: AnyCodable]] {
        guard let qType = quantityType(for: dataType) else {
            throw RynBridgeError(code: .invalidMessage, message: "Unsupported data type: \(dataType)")
        }
        let start = try parseDate(startDate)
        let end = try parseDate(endDate)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let queryLimit = limit ?? HKObjectQueryNoLimit

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: qType,
                predicate: predicate,
                limit: queryLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: RynBridgeError(code: .unknown, message: error.localizedDescription))
                    return
                }
                let records: [[String: AnyCodable]] = (samples ?? []).compactMap { sample in
                    guard let quantitySample = sample as? HKQuantitySample else { return nil }
                    let unit = self.preferredUnit(for: dataType)
                    return [
                        "type": .string(dataType),
                        "value": .double(quantitySample.quantity.doubleValue(for: unit)),
                        "unit": .string(unit.unitString),
                        "startDate": .string(ISO8601DateFormatter().string(from: quantitySample.startDate)),
                        "endDate": .string(ISO8601DateFormatter().string(from: quantitySample.endDate)),
                    ]
                }
                continuation.resume(returning: records)
            }
            healthStore.execute(query)
        }
    }

    public func writeData(dataType: String, value: Double, unit: String, startDate: String, endDate: String) async throws -> Bool {
        guard let qType = quantityType(for: dataType) else {
            throw RynBridgeError(code: .invalidMessage, message: "Unsupported data type: \(dataType)")
        }
        let hkUnit = HKUnit(from: unit)
        let quantity = HKQuantity(unit: hkUnit, doubleValue: value)
        let start = try parseDate(startDate)
        let end = try parseDate(endDate)
        let sample = HKQuantitySample(type: qType, quantity: quantity, start: start, end: end)
        try await healthStore.save(sample)
        return true
    }

    public func getSteps(startDate: String, endDate: String) async throws -> Double {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw RynBridgeError(code: .unknown, message: "Step count type unavailable")
        }
        let start = try parseDate(startDate)
        let end = try parseDate(endDate)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: RynBridgeError(code: .unknown, message: error.localizedDescription))
                    return
                }
                let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: steps)
            }
            healthStore.execute(query)
        }
    }

    public func isAvailable() async throws -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Helpers

    private func quantityType(for name: String) -> HKQuantityType? {
        switch name {
        case "steps", "stepCount":
            return .quantityType(forIdentifier: .stepCount)
        case "heartRate":
            return .quantityType(forIdentifier: .heartRate)
        case "activeEnergyBurned":
            return .quantityType(forIdentifier: .activeEnergyBurned)
        case "distanceWalkingRunning":
            return .quantityType(forIdentifier: .distanceWalkingRunning)
        case "height":
            return .quantityType(forIdentifier: .height)
        case "bodyMass", "weight":
            return .quantityType(forIdentifier: .bodyMass)
        case "bodyTemperature":
            return .quantityType(forIdentifier: .bodyTemperature)
        case "bloodGlucose":
            return .quantityType(forIdentifier: .bloodGlucose)
        case "oxygenSaturation":
            return .quantityType(forIdentifier: .oxygenSaturation)
        case "bloodPressureSystolic":
            return .quantityType(forIdentifier: .bloodPressureSystolic)
        case "bloodPressureDiastolic":
            return .quantityType(forIdentifier: .bloodPressureDiastolic)
        case "respiratoryRate":
            return .quantityType(forIdentifier: .respiratoryRate)
        default:
            return nil
        }
    }

    private func preferredUnit(for dataType: String) -> HKUnit {
        switch dataType {
        case "steps", "stepCount":
            return .count()
        case "heartRate":
            return HKUnit.count().unitDivided(by: .minute())
        case "activeEnergyBurned":
            return .kilocalorie()
        case "distanceWalkingRunning":
            return .meter()
        case "height":
            return .meterUnit(with: .centi)
        case "bodyMass", "weight":
            return .gramUnit(with: .kilo)
        case "bodyTemperature":
            return .degreeCelsius()
        case "bloodGlucose":
            return HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: .liter())
        case "oxygenSaturation":
            return .percent()
        case "bloodPressureSystolic", "bloodPressureDiastolic":
            return .millimeterOfMercury()
        case "respiratoryRate":
            return HKUnit.count().unitDivided(by: .minute())
        default:
            return .count()
        }
    }

    private func parseDate(_ string: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) {
            return date
        }
        throw RynBridgeError(code: .invalidMessage, message: "Invalid date format: \(string)")
    }
}
#endif
