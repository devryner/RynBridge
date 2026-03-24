package com.devryner.rynbridge.securestorage

interface SecureStorageProvider {
    @Throws(Exception::class)
    fun get(key: String): String?

    @Throws(Exception::class)
    fun set(key: String, value: String)

    @Throws(Exception::class)
    fun remove(key: String)

    @Throws(Exception::class)
    fun has(key: String): Boolean
}
