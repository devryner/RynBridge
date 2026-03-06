package io.rynbridge.playground

import android.annotation.SuppressLint
import android.os.Bundle
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity
import io.rynbridge.core.RynBridge
import io.rynbridge.core.WebViewTransport
import io.rynbridge.device.DeviceModule
import io.rynbridge.storage.StorageModule
import io.rynbridge.securestorage.SecureStorageModule
import io.rynbridge.ui.UIModule
import io.rynbridge.auth.AuthModule
import io.rynbridge.push.PushModule
import io.rynbridge.payment.PaymentModule
import io.rynbridge.media.MediaModule
import io.rynbridge.media.DefaultMediaProvider
import io.rynbridge.crypto.CryptoModule
import io.rynbridge.crypto.DefaultCryptoProvider
import io.rynbridge.playground.providers.*

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
