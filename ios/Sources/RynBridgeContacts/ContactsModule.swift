import Foundation
import RynBridge

public struct ContactsModule: BridgeModule, Sendable {
    public let name = "contacts"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: ContactsProvider) {
        actions = [
            "getContacts": { payload in
                let query = payload["query"]?.stringValue
                let limit = payload["limit"]?.intValue ?? 100
                let offset = payload["offset"]?.intValue ?? 0
                let contacts = try await provider.getContacts(query: query, limit: limit, offset: offset)
                return ["contacts": .array(contacts.map { .dictionary($0.toPayload()) })]
            },
            "getContact": { payload in
                guard let id = payload["id"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: id")
                }
                let contact = try await provider.getContact(id: id)
                return contact.toPayload()
            },
            "createContact": { payload in
                guard let givenName = payload["givenName"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: givenName")
                }
                guard let familyName = payload["familyName"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: familyName")
                }
                let phoneNumbers = payload["phoneNumbers"]?.arrayValue?.compactMap { item -> (label: String, number: String)? in
                    guard let dict = item.dictionaryValue,
                          let label = dict["label"]?.stringValue,
                          let number = dict["number"]?.stringValue else { return nil }
                    return (label: label, number: number)
                } ?? []
                let emailAddresses = payload["emailAddresses"]?.arrayValue?.compactMap { item -> (label: String, address: String)? in
                    guard let dict = item.dictionaryValue,
                          let label = dict["label"]?.stringValue,
                          let address = dict["address"]?.stringValue else { return nil }
                    return (label: label, address: address)
                } ?? []
                let id = try await provider.createContact(givenName: givenName, familyName: familyName, phoneNumbers: phoneNumbers, emailAddresses: emailAddresses)
                return ["id": .string(id)]
            },
            "updateContact": { payload in
                guard let id = payload["id"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: id")
                }
                let givenName = payload["givenName"]?.stringValue
                let familyName = payload["familyName"]?.stringValue
                let phoneNumbers = payload["phoneNumbers"]?.arrayValue?.compactMap { item -> (label: String, number: String)? in
                    guard let dict = item.dictionaryValue,
                          let label = dict["label"]?.stringValue,
                          let number = dict["number"]?.stringValue else { return nil }
                    return (label: label, number: number)
                }
                let emailAddresses = payload["emailAddresses"]?.arrayValue?.compactMap { item -> (label: String, address: String)? in
                    guard let dict = item.dictionaryValue,
                          let label = dict["label"]?.stringValue,
                          let address = dict["address"]?.stringValue else { return nil }
                    return (label: label, address: address)
                }
                try await provider.updateContact(id: id, givenName: givenName, familyName: familyName, phoneNumbers: phoneNumbers, emailAddresses: emailAddresses)
                return [:]
            },
            "deleteContact": { payload in
                guard let id = payload["id"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: id")
                }
                try await provider.deleteContact(id: id)
                return [:]
            },
            "pickContact": { _ in
                let contact = try await provider.pickContact()
                if let contact {
                    return ["contact": .dictionary(contact.toPayload())]
                } else {
                    return ["contact": .null]
                }
            },
            "requestPermission": { _ in
                let granted = try await provider.requestPermission()
                return ["granted": .bool(granted)]
            },
            "getPermissionStatus": { _ in
                let status = try await provider.getPermissionStatus()
                return ["status": .string(status)]
            },
        ]
    }
}
