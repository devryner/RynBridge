package io.rynbridge.contacts

import android.content.Context
import io.rynbridge.core.*

class ContactsModule(provider: ContactsProvider) : BridgeModule {
    constructor(context: Context) : this(DefaultContactsProvider(context))

    override val name = "contacts"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "getContacts" to { payload ->
            val query = payload["query"]?.stringValue
            val limit = payload["limit"]?.intValue?.toInt() ?: 100
            val offset = payload["offset"]?.intValue?.toInt() ?: 0
            val contacts = provider.getContacts(query, limit, offset)
            mapOf("contacts" to BridgeValue.array(contacts.map { BridgeValue.dict(it.toPayload()) }))
        },
        "getContact" to { payload ->
            val id = payload["id"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: id")
            val contact = provider.getContact(id)
            contact.toPayload()
        },
        "createContact" to { payload ->
            val givenName = payload["givenName"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: givenName")
            val familyName = payload["familyName"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: familyName")
            val phoneNumbers = payload["phoneNumbers"]?.arrayValue?.mapNotNull { item ->
                val dict = item.dictionaryValue ?: return@mapNotNull null
                val label = dict["label"]?.stringValue ?: return@mapNotNull null
                val number = dict["number"]?.stringValue ?: return@mapNotNull null
                Pair(label, number)
            } ?: emptyList()
            val emailAddresses = payload["emailAddresses"]?.arrayValue?.mapNotNull { item ->
                val dict = item.dictionaryValue ?: return@mapNotNull null
                val label = dict["label"]?.stringValue ?: return@mapNotNull null
                val address = dict["address"]?.stringValue ?: return@mapNotNull null
                Pair(label, address)
            } ?: emptyList()
            val id = provider.createContact(givenName, familyName, phoneNumbers, emailAddresses)
            mapOf("id" to BridgeValue.string(id))
        },
        "updateContact" to { payload ->
            val id = payload["id"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: id")
            val givenName = payload["givenName"]?.stringValue
            val familyName = payload["familyName"]?.stringValue
            val phoneNumbers = payload["phoneNumbers"]?.arrayValue?.mapNotNull { item ->
                val dict = item.dictionaryValue ?: return@mapNotNull null
                val label = dict["label"]?.stringValue ?: return@mapNotNull null
                val number = dict["number"]?.stringValue ?: return@mapNotNull null
                Pair(label, number)
            }
            val emailAddresses = payload["emailAddresses"]?.arrayValue?.mapNotNull { item ->
                val dict = item.dictionaryValue ?: return@mapNotNull null
                val label = dict["label"]?.stringValue ?: return@mapNotNull null
                val address = dict["address"]?.stringValue ?: return@mapNotNull null
                Pair(label, address)
            }
            provider.updateContact(id, givenName, familyName, phoneNumbers, emailAddresses)
            emptyMap()
        },
        "deleteContact" to { payload ->
            val id = payload["id"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: id")
            provider.deleteContact(id)
            emptyMap()
        },
        "pickContact" to { _ ->
            val contact = provider.pickContact()
            if (contact != null) {
                mapOf("contact" to BridgeValue.dict(contact.toPayload()))
            } else {
                mapOf("contact" to BridgeValue.nullValue())
            }
        },
        "requestPermission" to { _ ->
            val granted = provider.requestPermission()
            mapOf("granted" to BridgeValue.bool(granted))
        },
        "getPermissionStatus" to { _ ->
            val status = provider.getPermissionStatus()
            mapOf("status" to BridgeValue.string(status))
        }
    )
}
