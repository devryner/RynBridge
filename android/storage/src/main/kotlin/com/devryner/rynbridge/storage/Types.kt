package com.devryner.rynbridge.storage

import com.devryner.rynbridge.core.BridgeValue

data class FileInfo(
    val size: Long,
    val modifiedAt: String,
    val isDirectory: Boolean
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "size" to BridgeValue.int(size.toInt()),
        "modifiedAt" to BridgeValue.string(modifiedAt),
        "isDirectory" to BridgeValue.bool(isDirectory)
    )
}

interface StorageProvider {
    fun get(key: String): String?
    fun set(key: String, value: String)
    fun remove(key: String)
    fun clear()
    fun keys(): List<String>
    @Throws(Exception::class)
    fun readFile(path: String, encoding: String): String
    @Throws(Exception::class)
    fun writeFile(path: String, content: String, encoding: String)
    @Throws(Exception::class)
    fun deleteFile(path: String)
    @Throws(Exception::class)
    fun listDir(path: String): List<String>
    @Throws(Exception::class)
    fun getFileInfo(path: String): FileInfo
}
