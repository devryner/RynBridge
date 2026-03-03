package io.rynbridge.playground.providers

import android.app.Activity
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import io.rynbridge.ui.UIProvider
import kotlinx.coroutines.suspendCancellableCoroutine
import java.lang.ref.WeakReference
import kotlin.coroutines.resume

class AndroidUIProvider(activity: Activity) : UIProvider {

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
        // Status bar customization is a no-op for this playground
    }
}
