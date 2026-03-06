package io.rynbridge.contacts

import io.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class ContactsModuleTest {

    @Test
    fun `getContacts returns contact list`() = runTest {
        val provider = MockContactsProvider()
        val module = ContactsModule(provider)
        val handler = module.actions["getContacts"]!!

        val result = handler(mapOf(
            "query" to BridgeValue.string("John"),
            "limit" to BridgeValue.int(10),
            "offset" to BridgeValue.int(0)
        ))
        val contacts = result["contacts"]?.arrayValue
        assertNotNull(contacts)
        assertEquals(1, contacts!!.size)
        assertEquals("John", contacts[0].dictionaryValue?.get("givenName")?.stringValue)
    }

    @Test
    fun `getContact returns single contact`() = runTest {
        val provider = MockContactsProvider()
        val module = ContactsModule(provider)
        val handler = module.actions["getContact"]!!

        val result = handler(mapOf("id" to BridgeValue.string("c1")))
        assertEquals("c1", result["id"]?.stringValue)
        assertEquals("John", result["givenName"]?.stringValue)
        assertEquals("Doe", result["familyName"]?.stringValue)
    }

    @Test
    fun `createContact returns id`() = runTest {
        val provider = MockContactsProvider()
        val module = ContactsModule(provider)
        val handler = module.actions["createContact"]!!

        val result = handler(mapOf(
            "givenName" to BridgeValue.string("Jane"),
            "familyName" to BridgeValue.string("Smith"),
            "phoneNumbers" to BridgeValue.array(listOf(
                BridgeValue.dict(mapOf(
                    "label" to BridgeValue.string("mobile"),
                    "number" to BridgeValue.string("555-1234")
                ))
            )),
            "emailAddresses" to BridgeValue.array(listOf(
                BridgeValue.dict(mapOf(
                    "label" to BridgeValue.string("work"),
                    "address" to BridgeValue.string("jane@example.com")
                ))
            ))
        ))
        assertEquals("new-id", result["id"]?.stringValue)
        assertEquals("Jane", provider.lastCreateGivenName)
    }

    @Test
    fun `updateContact calls provider`() = runTest {
        val provider = MockContactsProvider()
        val module = ContactsModule(provider)
        val handler = module.actions["updateContact"]!!

        val result = handler(mapOf(
            "id" to BridgeValue.string("c1"),
            "givenName" to BridgeValue.string("Johnny")
        ))
        assertTrue(result.isEmpty())
        assertEquals("c1", provider.lastUpdateId)
        assertEquals("Johnny", provider.lastUpdateGivenName)
    }

    @Test
    fun `deleteContact calls provider`() = runTest {
        val provider = MockContactsProvider()
        val module = ContactsModule(provider)
        val handler = module.actions["deleteContact"]!!

        val result = handler(mapOf("id" to BridgeValue.string("c1")))
        assertTrue(result.isEmpty())
        assertEquals("c1", provider.lastDeleteId)
    }

    @Test
    fun `pickContact returns contact`() = runTest {
        val provider = MockContactsProvider()
        val module = ContactsModule(provider)
        val handler = module.actions["pickContact"]!!

        val result = handler(emptyMap())
        val contact = result["contact"]?.dictionaryValue
        assertNotNull(contact)
        assertEquals("c1", contact!!["id"]?.stringValue)
    }

    @Test
    fun `requestPermission returns granted`() = runTest {
        val provider = MockContactsProvider()
        val module = ContactsModule(provider)
        val handler = module.actions["requestPermission"]!!

        val result = handler(emptyMap())
        assertEquals(true, result["granted"]?.boolValue)
    }

    @Test
    fun `getPermissionStatus returns status`() = runTest {
        val provider = MockContactsProvider()
        val module = ContactsModule(provider)
        val handler = module.actions["getPermissionStatus"]!!

        val result = handler(emptyMap())
        assertEquals("granted", result["status"]?.stringValue)
    }

    @Test
    fun `module name and version`() {
        val provider = MockContactsProvider()
        val module = ContactsModule(provider)
        assertEquals("contacts", module.name)
        assertEquals("0.1.0", module.version)
    }
}

private class MockContactsProvider : ContactsProvider {
    var lastCreateGivenName: String? = null
    var lastUpdateId: String? = null
    var lastUpdateGivenName: String? = null
    var lastDeleteId: String? = null

    private val mockContact = ContactData(
        id = "c1",
        givenName = "John",
        familyName = "Doe",
        phoneNumbers = listOf(ContactPhoneData("mobile", "555-0000")),
        emailAddresses = listOf(ContactEmailData("home", "john@example.com"))
    )

    override suspend fun getContacts(query: String?, limit: Int, offset: Int): List<ContactData> =
        listOf(mockContact)

    override suspend fun getContact(id: String): ContactData = mockContact

    override suspend fun createContact(
        givenName: String,
        familyName: String,
        phoneNumbers: List<Pair<String, String>>,
        emailAddresses: List<Pair<String, String>>
    ): String {
        lastCreateGivenName = givenName
        return "new-id"
    }

    override suspend fun updateContact(
        id: String,
        givenName: String?,
        familyName: String?,
        phoneNumbers: List<Pair<String, String>>?,
        emailAddresses: List<Pair<String, String>>?
    ) {
        lastUpdateId = id
        lastUpdateGivenName = givenName
    }

    override suspend fun deleteContact(id: String) {
        lastDeleteId = id
    }

    override suspend fun pickContact(): ContactData = mockContact

    override suspend fun requestPermission(): Boolean = true

    override suspend fun getPermissionStatus(): String = "granted"
}
