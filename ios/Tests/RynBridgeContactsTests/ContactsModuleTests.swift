import XCTest
@testable import RynBridge
@testable import RynBridgeContacts

final class ContactsModuleTests: XCTestCase {
    func testGetContacts() async throws {
        let provider = MockContactsProvider()
        let module = ContactsModule(provider: provider)
        let handler = module.actions["getContacts"]!

        let result = try await handler(["query": .string("John"), "limit": .int(10), "offset": .int(0)])
        let contacts = result["contacts"]?.arrayValue
        XCTAssertNotNil(contacts)
        XCTAssertEqual(contacts?.count, 1)
        let first = contacts?.first?.dictionaryValue
        XCTAssertEqual(first?["id"]?.stringValue, "contact-1")
        XCTAssertEqual(first?["givenName"]?.stringValue, "John")
        XCTAssertEqual(first?["familyName"]?.stringValue, "Doe")
    }

    func testGetContact() async throws {
        let provider = MockContactsProvider()
        let module = ContactsModule(provider: provider)
        let handler = module.actions["getContact"]!

        let result = try await handler(["id": .string("contact-1")])
        XCTAssertEqual(result["id"]?.stringValue, "contact-1")
        XCTAssertEqual(result["givenName"]?.stringValue, "John")
        XCTAssertEqual(result["familyName"]?.stringValue, "Doe")
    }

    func testCreateContact() async throws {
        let provider = MockContactsProvider()
        let module = ContactsModule(provider: provider)
        let handler = module.actions["createContact"]!

        let result = try await handler([
            "givenName": .string("Jane"),
            "familyName": .string("Smith"),
            "phoneNumbers": .array([
                .dictionary(["label": .string("mobile"), "number": .string("+1234567890")])
            ]),
            "emailAddresses": .array([
                .dictionary(["label": .string("work"), "address": .string("jane@example.com")])
            ]),
        ])
        XCTAssertEqual(result["id"]?.stringValue, "new-contact-id")
        XCTAssertEqual(provider.lastCreatedGivenName, "Jane")
        XCTAssertEqual(provider.lastCreatedFamilyName, "Smith")
    }

    func testUpdateContact() async throws {
        let provider = MockContactsProvider()
        let module = ContactsModule(provider: provider)
        let handler = module.actions["updateContact"]!

        let result = try await handler(["id": .string("contact-1"), "givenName": .string("Updated")])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastUpdatedId, "contact-1")
        XCTAssertEqual(provider.lastUpdatedGivenName, "Updated")
    }

    func testDeleteContact() async throws {
        let provider = MockContactsProvider()
        let module = ContactsModule(provider: provider)
        let handler = module.actions["deleteContact"]!

        let result = try await handler(["id": .string("contact-1")])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastDeletedId, "contact-1")
    }

    func testPickContact() async throws {
        let provider = MockContactsProvider()
        let module = ContactsModule(provider: provider)
        let handler = module.actions["pickContact"]!

        let result = try await handler([:])
        let contact = result["contact"]?.dictionaryValue
        XCTAssertNotNil(contact)
        XCTAssertEqual(contact?["id"]?.stringValue, "picked-contact")
        XCTAssertEqual(contact?["givenName"]?.stringValue, "Picked")
    }

    func testRequestPermission() async throws {
        let provider = MockContactsProvider()
        let module = ContactsModule(provider: provider)
        let handler = module.actions["requestPermission"]!

        let result = try await handler([:])
        XCTAssertEqual(result["granted"]?.boolValue, true)
    }

    func testGetPermissionStatus() async throws {
        let provider = MockContactsProvider()
        let module = ContactsModule(provider: provider)
        let handler = module.actions["getPermissionStatus"]!

        let result = try await handler([:])
        XCTAssertEqual(result["status"]?.stringValue, "authorized")
    }

    func testModuleNameAndVersion() {
        let provider = MockContactsProvider()
        let module = ContactsModule(provider: provider)
        XCTAssertEqual(module.name, "contacts")
        XCTAssertEqual(module.version, "0.1.0")
    }
}

private final class MockContactsProvider: ContactsProvider, @unchecked Sendable {
    var lastCreatedGivenName: String?
    var lastCreatedFamilyName: String?
    var lastUpdatedId: String?
    var lastUpdatedGivenName: String?
    var lastDeletedId: String?

    func getContacts(query: String?, limit: Int, offset: Int) async throws -> [ContactData] {
        [
            ContactData(
                id: "contact-1",
                givenName: "John",
                familyName: "Doe",
                phoneNumbers: [ContactPhoneData(label: "mobile", number: "+1234567890")],
                emailAddresses: [ContactEmailData(label: "home", address: "john@example.com")]
            ),
        ]
    }

    func getContact(id: String) async throws -> ContactData {
        ContactData(
            id: id,
            givenName: "John",
            familyName: "Doe",
            phoneNumbers: [ContactPhoneData(label: "mobile", number: "+1234567890")],
            emailAddresses: [ContactEmailData(label: "home", address: "john@example.com")]
        )
    }

    func createContact(givenName: String, familyName: String, phoneNumbers: [(label: String, number: String)], emailAddresses: [(label: String, address: String)]) async throws -> String {
        lastCreatedGivenName = givenName
        lastCreatedFamilyName = familyName
        return "new-contact-id"
    }

    func updateContact(id: String, givenName: String?, familyName: String?, phoneNumbers: [(label: String, number: String)]?, emailAddresses: [(label: String, address: String)]?) async throws {
        lastUpdatedId = id
        lastUpdatedGivenName = givenName
    }

    func deleteContact(id: String) async throws {
        lastDeletedId = id
    }

    func pickContact() async throws -> ContactData? {
        ContactData(
            id: "picked-contact",
            givenName: "Picked",
            familyName: "User",
            phoneNumbers: [],
            emailAddresses: []
        )
    }

    func requestPermission() async throws -> Bool {
        true
    }

    func getPermissionStatus() async throws -> String {
        "authorized"
    }
}
