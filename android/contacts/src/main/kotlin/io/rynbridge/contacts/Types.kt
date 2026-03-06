package io.rynbridge.contacts

import io.rynbridge.core.BridgeValue

data class ContactData(
    val id: String,
    val givenName: String,
    val familyName: String,
    val phoneNumbers: List<ContactPhoneData>,
    val emailAddresses: List<ContactEmailData>
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "id" to BridgeValue.string(id),
        "givenName" to BridgeValue.string(givenName),
        "familyName" to BridgeValue.string(familyName),
        "phoneNumbers" to BridgeValue.array(phoneNumbers.map { BridgeValue.dict(it.toPayload()) }),
        "emailAddresses" to BridgeValue.array(emailAddresses.map { BridgeValue.dict(it.toPayload()) })
    )
}

data class ContactPhoneData(
    val label: String,
    val number: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "label" to BridgeValue.string(label),
        "number" to BridgeValue.string(number)
    )
}

data class ContactEmailData(
    val label: String,
    val address: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "label" to BridgeValue.string(label),
        "address" to BridgeValue.string(address)
    )
}

interface ContactsProvider {
    suspend fun getContacts(query: String?, limit: Int, offset: Int): List<ContactData>
    suspend fun getContact(id: String): ContactData
    suspend fun createContact(givenName: String, familyName: String, phoneNumbers: List<Pair<String, String>>, emailAddresses: List<Pair<String, String>>): String
    suspend fun updateContact(id: String, givenName: String?, familyName: String?, phoneNumbers: List<Pair<String, String>>?, emailAddresses: List<Pair<String, String>>?)
    suspend fun deleteContact(id: String)
    suspend fun pickContact(): ContactData?
    suspend fun requestPermission(): Boolean
    suspend fun getPermissionStatus(): String
}
