#if canImport(Contacts)
import Foundation
import Contacts
import RynBridge

public final class DefaultContactsProvider: ContactsProvider, @unchecked Sendable {
    private let store: CNContactStore

    public init() {
        self.store = CNContactStore()
    }

    private let keysToFetch: [CNKeyDescriptor] = [
        CNContactIdentifierKey as CNKeyDescriptor,
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
    ]

    private func contactToData(_ contact: CNContact) -> ContactData {
        ContactData(
            id: contact.identifier,
            givenName: contact.givenName,
            familyName: contact.familyName,
            phoneNumbers: contact.phoneNumbers.map { phone in
                ContactPhoneData(
                    label: CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: phone.label ?? "other"),
                    number: phone.value.stringValue
                )
            },
            emailAddresses: contact.emailAddresses.map { email in
                ContactEmailData(
                    label: CNLabeledValue<NSString>.localizedString(forLabel: email.label ?? "other"),
                    address: email.value as String
                )
            }
        )
    }

    public func getContacts(query: String?, limit: Int, offset: Int) async throws -> [ContactData] {
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        if let query, !query.isEmpty {
            fetchRequest.predicate = CNContact.predicateForContacts(matchingName: query)
        }
        fetchRequest.sortOrder = .givenName

        var contacts: [ContactData] = []
        var currentIndex = 0
        try store.enumerateContacts(with: fetchRequest) { contact, stop in
            if currentIndex >= offset {
                contacts.append(self.contactToData(contact))
            }
            currentIndex += 1
            if contacts.count >= limit {
                stop.pointee = true
            }
        }
        return contacts
    }

    public func getContact(id: String) async throws -> ContactData {
        let predicate = CNContact.predicateForContacts(withIdentifiers: [id])
        let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
        guard let contact = contacts.first else {
            throw RynBridgeError(code: .unknown, message: "Contact not found: \(id)")
        }
        return contactToData(contact)
    }

    public func createContact(givenName: String, familyName: String, phoneNumbers: [(label: String, number: String)], emailAddresses: [(label: String, address: String)]) async throws -> String {
        let contact = CNMutableContact()
        contact.givenName = givenName
        contact.familyName = familyName
        contact.phoneNumbers = phoneNumbers.map { phone in
            CNLabeledValue(label: phone.label, value: CNPhoneNumber(stringValue: phone.number))
        }
        contact.emailAddresses = emailAddresses.map { email in
            CNLabeledValue(label: email.label, value: email.address as NSString)
        }

        let saveRequest = CNSaveRequest()
        saveRequest.add(contact, toContainerWithIdentifier: nil)
        try store.execute(saveRequest)
        return contact.identifier
    }

    public func updateContact(id: String, givenName: String?, familyName: String?, phoneNumbers: [(label: String, number: String)]?, emailAddresses: [(label: String, address: String)]?) async throws {
        let predicate = CNContact.predicateForContacts(withIdentifiers: [id])
        let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
        guard let existing = contacts.first else {
            throw RynBridgeError(code: .unknown, message: "Contact not found: \(id)")
        }
        let mutableContact = existing.mutableCopy() as! CNMutableContact
        if let givenName { mutableContact.givenName = givenName }
        if let familyName { mutableContact.familyName = familyName }
        if let phoneNumbers {
            mutableContact.phoneNumbers = phoneNumbers.map { phone in
                CNLabeledValue(label: phone.label, value: CNPhoneNumber(stringValue: phone.number))
            }
        }
        if let emailAddresses {
            mutableContact.emailAddresses = emailAddresses.map { email in
                CNLabeledValue(label: email.label, value: email.address as NSString)
            }
        }

        let saveRequest = CNSaveRequest()
        saveRequest.update(mutableContact)
        try store.execute(saveRequest)
    }

    public func deleteContact(id: String) async throws {
        let predicate = CNContact.predicateForContacts(withIdentifiers: [id])
        let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
        guard let existing = contacts.first else {
            throw RynBridgeError(code: .unknown, message: "Contact not found: \(id)")
        }
        let mutableContact = existing.mutableCopy() as! CNMutableContact
        let saveRequest = CNSaveRequest()
        saveRequest.delete(mutableContact)
        try store.execute(saveRequest)
    }

    public func pickContact() async throws -> ContactData? {
        throw RynBridgeError(code: .unknown, message: "pickContact requires UI context and must be implemented by the host application")
    }

    public func requestPermission() async throws -> Bool {
        return try await store.requestAccess(for: .contacts)
    }

    public func getPermissionStatus() async throws -> String {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized:
            return "granted"
        case .denied, .restricted:
            return "denied"
        case .notDetermined:
            return "notDetermined"
        @unknown default:
            return "notDetermined"
        }
    }
}
#endif
