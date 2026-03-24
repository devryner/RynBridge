package com.devryner.rynbridge.core

import android.os.Handler
import android.os.Looper
import android.webkit.JavascriptInterface
import android.webkit.WebView
import java.lang.ref.WeakReference

class WebViewTransport(webView: WebView) : Transport {

    private val webViewRef = WeakReference(webView)
    private val mainHandler = Handler(Looper.getMainLooper())
    private var messageHandler: ((String) -> Unit)? = null
    private var disposed = false

    override fun send(message: String) {
        if (disposed) return
        val escaped = message
            .replace("\\", "\\\\")
            .replace("'", "\\'")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
        mainHandler.post {
            webViewRef.get()?.evaluateJavascript(
                "window.__rynbridge_receive('$escaped')",
                null
            )
        }
    }

    override fun onMessage(handler: (String) -> Unit) {
        messageHandler = handler
    }

    override fun dispose() {
        disposed = true
        messageHandler = null
    }

    @JavascriptInterface
    fun postMessage(message: String) {
        messageHandler?.invoke(message)
    }
}
