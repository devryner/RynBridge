package com.devryner.rynbridge.playground.providers

import com.devryner.rynbridge.securestorage.SecureStorageProvider
import java.util.concurrent.ConcurrentHashMap

class InMemorySecureStorageProvider : SecureStorageProvider {

    private val store = ConcurrentHashMap<String, String>()

    override fun get(key: String): String? {
        return store[key]
    }

    override fun set(key: String, value: String) {
        store[key] = value
    }

    override fun remove(key: String) {
        store.remove(key)
    }

    override fun has(key: String): Boolean {
        return store.containsKey(key)
    }
}
