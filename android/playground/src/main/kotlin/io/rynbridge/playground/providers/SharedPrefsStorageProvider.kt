package io.rynbridge.playground.providers

import android.content.Context
import android.content.SharedPreferences
import io.rynbridge.storage.StorageProvider

class SharedPrefsStorageProvider(context: Context) : StorageProvider {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("rynbridge_storage", Context.MODE_PRIVATE)

    override fun get(key: String): String? {
        return prefs.getString(key, null)
    }

    override fun set(key: String, value: String) {
        prefs.edit().putString(key, value).apply()
    }

    override fun remove(key: String) {
        prefs.edit().remove(key).apply()
    }

    override fun clear() {
        prefs.edit().clear().apply()
    }

    override fun keys(): List<String> {
        return prefs.all.keys.sorted()
    }
}
