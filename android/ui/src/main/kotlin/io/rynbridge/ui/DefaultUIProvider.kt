package io.rynbridge.ui

import android.app.Activity
import android.view.inputmethod.InputMethodManager
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import kotlinx.coroutines.suspendCancellableCoroutine
import java.lang.ref.WeakReference
import kotlin.coroutines.resume

class DefaultUIProvider(activity: Activity) : UIProvider {

    private val activityRef = WeakReference(activity)

    override suspend fun showAlert(title: String, message: String, buttonText: String) {
        val activity = activityRef.get() ?: return
        suspendCancellableCoroutine { cont ->
            activity.runOnUiThread {
                AlertDialog.Builder(activity)
                    .setTitle(title)
                    .setMessage(message)
                    .setPositiveButton(buttonText) { dialog, _ ->
                        dialog.dismiss()
                        cont.resume(Unit)
                    }
                    .setCancelable(false)
                    .show()
            }
        }
    }

    override suspend fun showConfirm(
        title: String,
        message: String,
        confirmText: String,
        cancelText: String
    ): Boolean {
        val activity = activityRef.get() ?: return false
        return suspendCancellableCoroutine { cont ->
            activity.runOnUiThread {
                AlertDialog.Builder(activity)
                    .setTitle(title)
                    .setMessage(message)
                    .setPositiveButton(confirmText) { dialog, _ ->
                        dialog.dismiss()
                        cont.resume(true)
                    }
                    .setNegativeButton(cancelText) { dialog, _ ->
                        dialog.dismiss()
                        cont.resume(false)
                    }
                    .setCancelable(false)
                    .show()
            }
        }
    }

    override fun showToast(message: String, duration: Double) {
        val activity = activityRef.get() ?: return
        activity.runOnUiThread {
            val length = if (duration > 2.5) Toast.LENGTH_LONG else Toast.LENGTH_SHORT
            Toast.makeText(activity, message, length).show()
        }
    }

    override suspend fun showActionSheet(title: String?, options: List<String>): Int {
        val activity = activityRef.get() ?: return -1
        return suspendCancellableCoroutine { cont ->
            activity.runOnUiThread {
                val builder = AlertDialog.Builder(activity)
                if (title != null) builder.setTitle(title)
                builder.setItems(options.toTypedArray()) { dialog, which ->
                    dialog.dismiss()
                    cont.resume(which)
                }
                builder.setNegativeButton("Cancel") { dialog, _ ->
                    dialog.dismiss()
                    cont.resume(-1)
                }
                builder.setCancelable(false)
                builder.show()
            }
        }
    }

    override suspend fun setStatusBar(style: String?, hidden: Boolean?) {
        val activity = activityRef.get() ?: return
        activity.runOnUiThread {
            val window = activity.window
            if (hidden == true) {
                @Suppress("DEPRECATION")
                window.decorView.systemUiVisibility = (
                    android.view.View.SYSTEM_UI_FLAG_FULLSCREEN
                    or android.view.View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                )
            } else if (hidden == false) {
                @Suppress("DEPRECATION")
                window.decorView.systemUiVisibility = android.view.View.SYSTEM_UI_FLAG_VISIBLE
            }

            if (style != null) {
                val controller = androidx.core.view.WindowCompat.getInsetsController(window, window.decorView)
                when (style) {
                    "light" -> controller.isAppearanceLightStatusBars = false
                    "dark" -> controller.isAppearanceLightStatusBars = true
                }
            }
        }
    }

    override fun showKeyboard() {
        val activity = activityRef.get() ?: return
        val imm = activity.getSystemService(android.content.Context.INPUT_METHOD_SERVICE) as InputMethodManager
        activity.currentFocus?.let {
            imm.showSoftInput(it, InputMethodManager.SHOW_IMPLICIT)
        }
    }

    override fun hideKeyboard() {
        val activity = activityRef.get() ?: return
        val imm = activity.getSystemService(android.content.Context.INPUT_METHOD_SERVICE) as InputMethodManager
        activity.currentFocus?.let {
            imm.hideSoftInputFromWindow(it.windowToken, 0)
        }
    }

    override suspend fun getKeyboardHeight(): KeyboardInfo {
        val activity = activityRef.get() ?: return KeyboardInfo(height = 0.0, visible = false)
        val rootView = activity.window.decorView.rootView
        val rect = android.graphics.Rect()
        rootView.getWindowVisibleDisplayFrame(rect)
        val screenHeight = rootView.height
        val keyboardHeight = screenHeight - rect.bottom
        return KeyboardInfo(
            height = keyboardHeight.toDouble(),
            visible = keyboardHeight > screenHeight * 0.15
        )
    }
}
