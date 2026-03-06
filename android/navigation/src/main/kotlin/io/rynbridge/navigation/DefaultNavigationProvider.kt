package io.rynbridge.navigation

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import io.rynbridge.core.BridgeValue

class DefaultNavigationProvider(private val context: Context) : NavigationProvider {

    private var initialURL: String? = null

    fun setInitialURL(url: String?) {
        this.initialURL = url
    }

    override suspend fun push(screen: String, params: Map<String, BridgeValue>?): PopResult {
        throw UnsupportedOperationException("push requires an Activity context. Use a custom provider for navigation.")
    }

    override suspend fun pop(): PopResult {
        throw UnsupportedOperationException("pop requires an Activity context. Use a custom provider for navigation.")
    }

    override suspend fun popToRoot(): PopResult {
        throw UnsupportedOperationException("popToRoot requires an Activity context. Use a custom provider for navigation.")
    }

    override suspend fun present(screen: String, style: String?, params: Map<String, BridgeValue>?): PopResult {
        throw UnsupportedOperationException("present requires an Activity context. Use a custom provider for navigation.")
    }

    override suspend fun dismiss(): PopResult {
        throw UnsupportedOperationException("dismiss requires an Activity context. Use a custom provider for navigation.")
    }

    override suspend fun openURL(url: String): OpenURLResult {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            OpenURLResult(success = true)
        } catch (e: Exception) {
            OpenURLResult(success = false)
        }
    }

    override suspend fun canOpenURL(url: String): CanOpenURLResult {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        val canOpen = intent.resolveActivity(context.packageManager) != null
        return CanOpenURLResult(canOpen = canOpen)
    }

    override suspend fun getInitialURL(): InitialURLResult {
        return InitialURLResult(url = initialURL)
    }

    override suspend fun getAppState(): AppStateResult {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val appProcesses = activityManager.runningAppProcesses
        val currentProcess = appProcesses?.find { it.pid == android.os.Process.myPid() }
        val state = when (currentProcess?.importance) {
            ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND -> "active"
            ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE -> "inactive"
            else -> "background"
        }
        return AppStateResult(state = state)
    }
}
