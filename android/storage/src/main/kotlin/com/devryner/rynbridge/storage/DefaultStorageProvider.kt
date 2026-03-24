package com.devryner.rynbridge.storage

import android.content.Context
import android.content.SharedPreferences
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class DefaultStorageProvider(context: Context) : StorageProvider {

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
        val file = File(path)
        if (!file.exists()) throw Exception("File not found: $path")
        val bytes = file.readBytes()
        return if (encoding == "base64") {
            android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP)
        } else {
            String(bytes, Charsets.UTF_8)
        }
    }

    override fun writeFile(path: String, content: String, encoding: String) {
        val file = File(path)
        file.parentFile?.mkdirs()
        val bytes = if (encoding == "base64") {
            android.util.Base64.decode(content, android.util.Base64.NO_WRAP)
        } else {
            content.toByteArray(Charsets.UTF_8)
        }
        file.writeBytes(bytes)
    }

    override fun deleteFile(path: String) {
        val file = File(path)
        if (!file.exists()) throw Exception("File not found: $path")
        if (!file.delete()) throw Exception("Failed to delete file: $path")
    }

    override fun listDir(path: String): List<String> {
        val dir = File(path)
        if (!dir.exists()) throw Exception("Directory not found: $path")
        if (!dir.isDirectory) throw Exception("Not a directory: $path")
        return dir.list()?.toList() ?: emptyList()
    }

    override fun getFileInfo(path: String): FileInfo {
        val file = File(path)
        if (!file.exists()) throw Exception("File not found: $path")
        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
        sdf.timeZone = TimeZone.getTimeZone("UTC")
        return FileInfo(
            size = file.length(),
            modifiedAt = sdf.format(Date(file.lastModified())),
            isDirectory = file.isDirectory
        )
    }
}
