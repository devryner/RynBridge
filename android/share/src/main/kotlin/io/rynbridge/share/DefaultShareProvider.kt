package io.rynbridge.share

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import io.rynbridge.core.ErrorCode
import io.rynbridge.core.RynBridgeError

class DefaultShareProvider(private val context: Context) : ShareProvider {

    override suspend fun share(text: String?, url: String?, title: String?): Boolean {
        throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "share requires an Activity context. Use a custom provider for UI-based sharing.")
    }

    override suspend fun shareFile(filePath: String, mimeType: String): Boolean {
        throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "shareFile requires an Activity context. Use a custom provider for UI-based sharing.")
    }

    override suspend fun copyToClipboard(text: String) {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText("RynBridge", text)
        clipboard.setPrimaryClip(clip)
    }

    override suspend fun readClipboard(): String? {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip
        return if (clip != null && clip.itemCount > 0) {
            clip.getItemAt(0).text?.toString()
        } else {
            null
        }
    }

    override suspend fun canShare(): Boolean {
        return true
    }
}
