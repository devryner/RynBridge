package com.devryner.rynbridge.share

import com.devryner.rynbridge.core.BridgeValue

data class ShareResult(
    val success: Boolean
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "success" to BridgeValue.bool(success)
    )
}

data class ClipboardText(
    val text: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "text" to BridgeValue.string(text)
    )
}

interface ShareProvider {
    suspend fun share(text: String?, url: String?, title: String?): Boolean
    suspend fun shareFile(filePath: String, mimeType: String): Boolean
    suspend fun copyToClipboard(text: String)
    suspend fun readClipboard(): String?
    suspend fun canShare(): Boolean
}
