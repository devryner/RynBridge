package com.devryner.rynbridge.contacts

import android.content.ContentProviderOperation
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.provider.ContactsContract
import android.provider.ContactsContract.CommonDataKinds
import android.provider.ContactsContract.Data
import android.provider.ContactsContract.RawContacts
import com.devryner.rynbridge.core.ErrorCode
import com.devryner.rynbridge.core.RynBridgeError

class DefaultContactsProvider(private val context: Context) : ContactsProvider {

    private val contentResolver get() = context.contentResolver

    private fun requireReadPermission() {
        if (context.checkSelfPermission(android.Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Contacts read permission denied. Required: READ_CONTACTS")
        }
    }

    private fun requireWritePermission() {
        if (context.checkSelfPermission(android.Manifest.permission.WRITE_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Contacts write permission denied. Required: WRITE_CONTACTS")
        }
    }

    override suspend fun getContacts(query: String?, limit: Int, offset: Int): List<ContactData> {
        requireReadPermission()
        val selection = if (!query.isNullOrEmpty()) {
            "${ContactsContract.Contacts.DISPLAY_NAME} LIKE ?"
        } else null
        val selectionArgs = if (!query.isNullOrEmpty()) {
            arrayOf("%$query%")
        } else null

        val cursor = contentResolver.query(
            ContactsContract.Contacts.CONTENT_URI,
            arrayOf(
                ContactsContract.Contacts._ID,
                ContactsContract.Contacts.DISPLAY_NAME
            ),
            selection,
            selectionArgs,
            "${ContactsContract.Contacts.DISPLAY_NAME} ASC"
        ) ?: return emptyList()

        val contacts = mutableListOf<ContactData>()
        cursor.use {
            var currentIndex = 0
            while (it.moveToNext()) {
                if (currentIndex < offset) {
                    currentIndex++
                    continue
                }
                if (contacts.size >= limit) break

                val contactId = it.getString(it.getColumnIndexOrThrow(ContactsContract.Contacts._ID))
                val displayName = it.getString(it.getColumnIndexOrThrow(ContactsContract.Contacts.DISPLAY_NAME)) ?: ""

                val nameParts = displayName.split(" ", limit = 2)
                val givenName = nameParts.getOrElse(0) { "" }
                val familyName = nameParts.getOrElse(1) { "" }

                contacts.add(
                    ContactData(
                        id = contactId,
                        givenName = givenName,
                        familyName = familyName,
                        phoneNumbers = getPhoneNumbers(contactId),
                        emailAddresses = getEmailAddresses(contactId)
                    )
                )
                currentIndex++
            }
        }
        return contacts
    }

    override suspend fun getContact(id: String): ContactData {
        requireReadPermission()
        val cursor = contentResolver.query(
            ContactsContract.Contacts.CONTENT_URI,
            arrayOf(
                ContactsContract.Contacts._ID,
                ContactsContract.Contacts.DISPLAY_NAME
            ),
            "${ContactsContract.Contacts._ID} = ?",
            arrayOf(id),
            null
        ) ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Contact not found: $id")

        cursor.use {
            if (!it.moveToFirst()) {
                throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Contact not found: $id")
            }
            val displayName = it.getString(it.getColumnIndexOrThrow(ContactsContract.Contacts.DISPLAY_NAME)) ?: ""
            val nameParts = displayName.split(" ", limit = 2)
            return ContactData(
                id = id,
                givenName = nameParts.getOrElse(0) { "" },
                familyName = nameParts.getOrElse(1) { "" },
                phoneNumbers = getPhoneNumbers(id),
                emailAddresses = getEmailAddresses(id)
            )
        }
    }

    override suspend fun createContact(
        givenName: String,
        familyName: String,
        phoneNumbers: List<Pair<String, String>>,
        emailAddresses: List<Pair<String, String>>
    ): String {
        requireWritePermission()
        val ops = ArrayList<ContentProviderOperation>()

        ops.add(
            ContentProviderOperation.newInsert(RawContacts.CONTENT_URI)
                .withValue(RawContacts.ACCOUNT_TYPE, null)
                .withValue(RawContacts.ACCOUNT_NAME, null)
                .build()
        )

        ops.add(
            ContentProviderOperation.newInsert(Data.CONTENT_URI)
                .withValueBackReference(Data.RAW_CONTACT_ID, 0)
                .withValue(Data.MIMETYPE, CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
                .withValue(CommonDataKinds.StructuredName.GIVEN_NAME, givenName)
                .withValue(CommonDataKinds.StructuredName.FAMILY_NAME, familyName)
                .build()
        )

        for ((label, number) in phoneNumbers) {
            ops.add(
                ContentProviderOperation.newInsert(Data.CONTENT_URI)
                    .withValueBackReference(Data.RAW_CONTACT_ID, 0)
                    .withValue(Data.MIMETYPE, CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                    .withValue(CommonDataKinds.Phone.NUMBER, number)
                    .withValue(CommonDataKinds.Phone.LABEL, label)
                    .withValue(CommonDataKinds.Phone.TYPE, CommonDataKinds.Phone.TYPE_CUSTOM)
                    .build()
            )
        }

        for ((label, address) in emailAddresses) {
            ops.add(
                ContentProviderOperation.newInsert(Data.CONTENT_URI)
                    .withValueBackReference(Data.RAW_CONTACT_ID, 0)
                    .withValue(Data.MIMETYPE, CommonDataKinds.Email.CONTENT_ITEM_TYPE)
                    .withValue(CommonDataKinds.Email.ADDRESS, address)
                    .withValue(CommonDataKinds.Email.LABEL, label)
                    .withValue(CommonDataKinds.Email.TYPE, CommonDataKinds.Email.TYPE_CUSTOM)
                    .build()
            )
        }

        val results = contentResolver.applyBatch(ContactsContract.AUTHORITY, ops)
        val rawContactUri = results[0].uri
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Failed to create contact")
        val rawContactId = rawContactUri.lastPathSegment
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Failed to get raw contact ID")

        // Look up the aggregate contact ID
        val cursor = contentResolver.query(
            RawContacts.CONTENT_URI,
            arrayOf(RawContacts.CONTACT_ID),
            "${RawContacts._ID} = ?",
            arrayOf(rawContactId),
            null
        )
        cursor?.use {
            if (it.moveToFirst()) {
                return it.getString(it.getColumnIndexOrThrow(RawContacts.CONTACT_ID))
            }
        }
        return rawContactId
    }

    override suspend fun updateContact(
        id: String,
        givenName: String?,
        familyName: String?,
        phoneNumbers: List<Pair<String, String>>?,
        emailAddresses: List<Pair<String, String>>?
    ) {
        requireWritePermission()
        val rawContactId = getRawContactId(id)
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Contact not found: $id")

        val ops = ArrayList<ContentProviderOperation>()

        if (givenName != null || familyName != null) {
            val builder = ContentProviderOperation.newUpdate(Data.CONTENT_URI)
                .withSelection(
                    "${Data.RAW_CONTACT_ID} = ? AND ${Data.MIMETYPE} = ?",
                    arrayOf(rawContactId, CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
                )
            givenName?.let { builder.withValue(CommonDataKinds.StructuredName.GIVEN_NAME, it) }
            familyName?.let { builder.withValue(CommonDataKinds.StructuredName.FAMILY_NAME, it) }
            ops.add(builder.build())
        }

        if (phoneNumbers != null) {
            ops.add(
                ContentProviderOperation.newDelete(Data.CONTENT_URI)
                    .withSelection(
                        "${Data.RAW_CONTACT_ID} = ? AND ${Data.MIMETYPE} = ?",
                        arrayOf(rawContactId, CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                    )
                    .build()
            )
            for ((label, number) in phoneNumbers) {
                ops.add(
                    ContentProviderOperation.newInsert(Data.CONTENT_URI)
                        .withValue(Data.RAW_CONTACT_ID, rawContactId.toLong())
                        .withValue(Data.MIMETYPE, CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                        .withValue(CommonDataKinds.Phone.NUMBER, number)
                        .withValue(CommonDataKinds.Phone.LABEL, label)
                        .withValue(CommonDataKinds.Phone.TYPE, CommonDataKinds.Phone.TYPE_CUSTOM)
                        .build()
                )
            }
        }

        if (emailAddresses != null) {
            ops.add(
                ContentProviderOperation.newDelete(Data.CONTENT_URI)
                    .withSelection(
                        "${Data.RAW_CONTACT_ID} = ? AND ${Data.MIMETYPE} = ?",
                        arrayOf(rawContactId, CommonDataKinds.Email.CONTENT_ITEM_TYPE)
                    )
                    .build()
            )
            for ((label, address) in emailAddresses) {
                ops.add(
                    ContentProviderOperation.newInsert(Data.CONTENT_URI)
                        .withValue(Data.RAW_CONTACT_ID, rawContactId.toLong())
                        .withValue(Data.MIMETYPE, CommonDataKinds.Email.CONTENT_ITEM_TYPE)
                        .withValue(CommonDataKinds.Email.ADDRESS, address)
                        .withValue(CommonDataKinds.Email.LABEL, label)
                        .withValue(CommonDataKinds.Email.TYPE, CommonDataKinds.Email.TYPE_CUSTOM)
                        .build()
                )
            }
        }

        if (ops.isNotEmpty()) {
            contentResolver.applyBatch(ContactsContract.AUTHORITY, ops)
        }
    }

    override suspend fun deleteContact(id: String) {
        requireWritePermission()
        val uri = Uri.withAppendedPath(ContactsContract.Contacts.CONTENT_URI, id)
        val deleted = contentResolver.delete(uri, null, null)
        if (deleted == 0) {
            throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Contact not found: $id")
        }
    }

    override suspend fun pickContact(): ContactData? {
        throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "pickContact requires Activity context and must be implemented by the host application")
    }

    override suspend fun requestPermission(): Boolean {
        return context.checkSelfPermission(
            android.Manifest.permission.READ_CONTACTS
        ) == PackageManager.PERMISSION_GRANTED
    }

    override suspend fun getPermissionStatus(): String {
        val readGranted = context.checkSelfPermission(
            android.Manifest.permission.READ_CONTACTS
        ) == PackageManager.PERMISSION_GRANTED
        return if (readGranted) "granted" else "denied"
    }

    private fun getPhoneNumbers(contactId: String): List<ContactPhoneData> {
        val phones = mutableListOf<ContactPhoneData>()
        val cursor = contentResolver.query(
            CommonDataKinds.Phone.CONTENT_URI,
            arrayOf(
                CommonDataKinds.Phone.NUMBER,
                CommonDataKinds.Phone.LABEL,
                CommonDataKinds.Phone.TYPE
            ),
            "${CommonDataKinds.Phone.CONTACT_ID} = ?",
            arrayOf(contactId),
            null
        )
        cursor?.use {
            while (it.moveToNext()) {
                val number = it.getString(it.getColumnIndexOrThrow(CommonDataKinds.Phone.NUMBER)) ?: continue
                val type = it.getInt(it.getColumnIndexOrThrow(CommonDataKinds.Phone.TYPE))
                val customLabel = it.getString(it.getColumnIndexOrThrow(CommonDataKinds.Phone.LABEL))
                val label = customLabel ?: CommonDataKinds.Phone.getTypeLabel(context.resources, type, "other").toString()
                phones.add(ContactPhoneData(label = label, number = number))
            }
        }
        return phones
    }

    private fun getEmailAddresses(contactId: String): List<ContactEmailData> {
        val emails = mutableListOf<ContactEmailData>()
        val cursor = contentResolver.query(
            CommonDataKinds.Email.CONTENT_URI,
            arrayOf(
                CommonDataKinds.Email.ADDRESS,
                CommonDataKinds.Email.LABEL,
                CommonDataKinds.Email.TYPE
            ),
            "${CommonDataKinds.Email.CONTACT_ID} = ?",
            arrayOf(contactId),
            null
        )
        cursor?.use {
            while (it.moveToNext()) {
                val address = it.getString(it.getColumnIndexOrThrow(CommonDataKinds.Email.ADDRESS)) ?: continue
                val type = it.getInt(it.getColumnIndexOrThrow(CommonDataKinds.Email.TYPE))
                val customLabel = it.getString(it.getColumnIndexOrThrow(CommonDataKinds.Email.LABEL))
                val label = customLabel ?: CommonDataKinds.Email.getTypeLabel(context.resources, type, "other").toString()
                emails.add(ContactEmailData(label = label, address = address))
            }
        }
        return emails
    }

    private fun getRawContactId(contactId: String): String? {
        val cursor = contentResolver.query(
            RawContacts.CONTENT_URI,
            arrayOf(RawContacts._ID),
            "${RawContacts.CONTACT_ID} = ?",
            arrayOf(contactId),
            null
        )
        cursor?.use {
            if (it.moveToFirst()) {
                return it.getString(it.getColumnIndexOrThrow(RawContacts._ID))
            }
        }
        return null
    }
}
