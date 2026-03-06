import Foundation
import RynBridge

public struct ContactData: Sendable {
    public let id: String
    public let givenName: String
    public let familyName: String
    public let phoneNumbers: [ContactPhoneData]
    public let emailAddresses: [ContactEmailData]

    public init(id: String, givenName: String, familyName: String, phoneNumbers: [ContactPhoneData], emailAddresses: [ContactEmailData]) {
        self.id = id
        self.givenName = givenName
        self.familyName = familyName
        self.phoneNumbers = phoneNumbers
        self.emailAddresses = emailAddresses
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "id": .string(id),
            "givenName": .string(givenName),
            "familyName": .string(familyName),
            "phoneNumbers": .array(phoneNumbers.map { .dictionary($0.toPayload()) }),
            "emailAddresses": .array(emailAddresses.map { .dictionary($0.toPayload()) }),
        ]
    }
}

public struct ContactPhoneData: Sendable {
    public let label: String
    public let number: String

    public init(label: String, number: String) {
        self.label = label
        self.number = number
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "label": .string(label),
            "number": .string(number),
        ]
    }
}

public struct ContactEmailData: Sendable {
    public let label: String
    public let address: String

    public init(label: String, address: String) {
        self.label = label
        self.address = address
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "label": .string(label),
            "address": .string(address),
        ]
    }
}

public struct CreateContactResult: Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "id": .string(id),
        ]
    }
}

public struct PermissionResult: Sendable {
    public let granted: Bool

    public init(granted: Bool) {
        self.granted = granted
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "granted": .bool(granted),
        ]
    }
}

public struct PermissionStatus: Sendable {
    public let status: String

    public init(status: String) {
        self.status = status
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "status": .string(status),
        ]
    }
}

public protocol ContactsProvider: Sendable {
    func getContacts(query: String?, limit: Int, offset: Int) async throws -> [ContactData]
    func getContact(id: String) async throws -> ContactData
    func createContact(givenName: String, familyName: String, phoneNumbers: [(label: String, number: String)], emailAddresses: [(label: String, address: String)]) async throws -> String
    func updateContact(id: String, givenName: String?, familyName: String?, phoneNumbers: [(label: String, number: String)]?, emailAddresses: [(label: String, address: String)]?) async throws
    func deleteContact(id: String) async throws
    func pickContact() async throws -> ContactData?
    func requestPermission() async throws -> Bool
    func getPermissionStatus() async throws -> String
}
