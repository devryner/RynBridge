package io.rynbridge.ui

import io.rynbridge.core.ActionHandler
import io.rynbridge.core.BridgeModule
import io.rynbridge.core.BridgeValue

class UIModule(provider: UIProvider) : BridgeModule {

    override val name = "ui"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "showAlert" to { payload ->
            val title = payload["title"]?.stringValue ?: ""
            val message = payload["message"]?.stringValue ?: ""
            val buttonText = payload["buttonText"]?.stringValue ?: "OK"
            provider.showAlert(title, message, buttonText)
            emptyMap()
        },
        "showConfirm" to { payload ->
            val title = payload["title"]?.stringValue ?: ""
            val message = payload["message"]?.stringValue ?: ""
            val confirmText = payload["confirmText"]?.stringValue ?: "Confirm"
            val cancelText = payload["cancelText"]?.stringValue ?: "Cancel"
            val confirmed = provider.showConfirm(title, message, confirmText, cancelText)
            mapOf("confirmed" to BridgeValue.bool(confirmed))
        },
        "showToast" to { payload ->
            val message = payload["message"]?.stringValue ?: ""
            val duration = payload["duration"]?.doubleValue ?: 2.0
            provider.showToast(message, duration)
            emptyMap()
        },
        "showActionSheet" to { payload ->
            val title = payload["title"]?.stringValue
            val options = payload["options"]?.arrayValue
                ?.mapNotNull { it.stringValue }
                ?: emptyList()
            val selectedIndex = provider.showActionSheet(title, options)
            mapOf("selectedIndex" to BridgeValue.int(selectedIndex))
        },
        "setStatusBar" to { payload ->
            val style = payload["style"]?.stringValue
            val hidden = payload["hidden"]?.boolValue
            provider.setStatusBar(style, hidden)
            emptyMap()
        }
    )
}
