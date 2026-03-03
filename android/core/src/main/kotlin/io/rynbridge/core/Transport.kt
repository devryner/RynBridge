package io.rynbridge.core

interface Transport {
    fun send(message: String)
    fun onMessage(handler: (String) -> Unit)
    fun dispose()
}
