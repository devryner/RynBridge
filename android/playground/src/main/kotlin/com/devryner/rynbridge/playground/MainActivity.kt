package com.devryner.rynbridge.playground

import android.annotation.SuppressLint
import android.os.Bundle
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity
import com.devryner.rynbridge.core.RynBridge
import com.devryner.rynbridge.core.WebViewTransport
import com.devryner.rynbridge.device.DeviceModule
import com.devryner.rynbridge.storage.StorageModule
import com.devryner.rynbridge.securestorage.SecureStorageModule
import com.devryner.rynbridge.ui.UIModule
import com.devryner.rynbridge.auth.AuthModule
import com.devryner.rynbridge.push.PushModule
import com.devryner.rynbridge.payment.PaymentModule
import com.devryner.rynbridge.media.MediaModule
import com.devryner.rynbridge.media.DefaultMediaProvider
import com.devryner.rynbridge.crypto.CryptoModule
import com.devryner.rynbridge.crypto.DefaultCryptoProvider
import com.devryner.rynbridge.playground.providers.*

class MainActivity : AppCompatActivity() {

    private var bridge: RynBridge? = null

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val webView = WebView(this).apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.allowFileAccess = true
            webViewClient = WebViewClient()
        }

        setContentView(webView)

        // Set up bridge
        val transport = WebViewTransport(webView)
        webView.addJavascriptInterface(transport, "RynBridgeAndroid")

        val bridge = RynBridge(transport)
        this.bridge = bridge

        // Register Phase 1 modules
        bridge.register(DeviceModule(AndroidDeviceInfoProvider(this)))
        bridge.register(StorageModule(SharedPrefsStorageProvider(this)))
        bridge.register(SecureStorageModule(InMemorySecureStorageProvider()))
        bridge.register(UIModule(AndroidUIProvider(this)))

        // Register Phase 2 modules (mock providers for playground)
        bridge.register(AuthModule(MockAuthProvider()))
        bridge.register(PushModule(MockPushProvider()))
        bridge.register(PaymentModule(MockPaymentProvider()))
        bridge.register(MediaModule(DefaultMediaProvider(this)))
        bridge.register(CryptoModule(DefaultCryptoProvider()))

        // Load web playground from assets
        webView.loadUrl("file:///android_asset/index.html")
    }

    override fun onDestroy() {
        bridge?.dispose()
        bridge = null
        super.onDestroy()
    }
}
