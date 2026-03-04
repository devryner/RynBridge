package io.rynbridge.ui

data class ShowAlertPayload(
    val title: String,
    val message: String,
    val buttonText: String = "OK"
)

data class ShowConfirmPayload(
    val title: String,
    val message: String,
    val confirmText: String = "Confirm",
    val cancelText: String = "Cancel"
)

data class ShowToastPayload(
    val message: String,
    val duration: Double = 2.0
)

data class ShowActionSheetPayload(
    val title: String?,
    val options: List<String>
)

data class SetStatusBarPayload(
    val style: String?,
    val hidden: Boolean?
)

data class KeyboardInfo(
    val height: Double,
    val visible: Boolean
)

interface UIProvider {
    suspend fun showAlert(title: String, message: String, buttonText: String)
    suspend fun showConfirm(title: String, message: String, confirmText: String, cancelText: String): Boolean
    fun showToast(message: String, duration: Double)
    suspend fun showActionSheet(title: String?, options: List<String>): Int
    suspend fun setStatusBar(style: String?, hidden: Boolean?)
    fun showKeyboard()
    fun hideKeyboard()
    suspend fun getKeyboardHeight(): KeyboardInfo
}
