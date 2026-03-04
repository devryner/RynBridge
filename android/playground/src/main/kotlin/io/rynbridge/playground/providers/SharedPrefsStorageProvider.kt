package io.rynbridge.playground.providers

import android.content.Context
import android.content.SharedPreferences
import io.rynbridge.storage.FileInfo
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

    override fun readFile(path: String, encoding: String): String {
        val file = java.io.File(path)
        val bytes = file.readBytes()
        return if (encoding == "base64") {
            android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP)
        } else {
            String(bytes, Charsets.UTF_8)
        }
    }

    override fun writeFile(path: String, content: String, encoding: String) {
        val file = java.io.File(path)
        val bytes = if (encoding == "base64") {
            android.util.Base64.decode(content, android.util.Base64.NO_WRAP)
        } else {
            content.toByteArray(Charsets.UTF_8)
        }
        file.writeBytes(bytes)
    }

    override fun deleteFile(path: String) {
        java.io.File(path).delete()
    }

    override fun listDir(path: String): List<String> {
        return java.io.File(path).list()?.toList() ?: emptyList()
    }

    override fun getFileInfo(path: String): FileInfo {
        val file = java.io.File(path)
        val sdf = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", java.util.Locale.US)
        sdf.timeZone = java.util.TimeZone.getTimeZone("UTC")
        return FileInfo(
            size = file.length(),
            modifiedAt = sdf.format(java.util.Date(file.lastModified())),
            isDirectory = file.isDirectory
        )
    }
}
