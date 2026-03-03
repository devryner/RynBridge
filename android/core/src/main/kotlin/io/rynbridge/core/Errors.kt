package io.rynbridge.core

enum class ErrorCode(val code: String) {
    TIMEOUT("TIMEOUT"),
    MODULE_NOT_FOUND("MODULE_NOT_FOUND"),
    ACTION_NOT_FOUND("ACTION_NOT_FOUND"),
    INVALID_MESSAGE("INVALID_MESSAGE"),
    SERIALIZATION_ERROR("SERIALIZATION_ERROR"),
    TRANSPORT_ERROR("TRANSPORT_ERROR"),
    VERSION_MISMATCH("VERSION_MISMATCH"),
    UNKNOWN("UNKNOWN")
}

class RynBridgeError(
    val code: ErrorCode,
    override val message: String,
    val details: Map<String, BridgeValue>? = null
) : Exception(message) {

    val errorData: BridgeErrorData
        get() = BridgeErrorData(
            code = code.code,
            message = message,
            details = details
        )

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is RynBridgeError) return false
        return code == other.code && message == other.message && details == other.details
    }

    override fun hashCode(): Int {
        var result = code.hashCode()
        result = 31 * result + message.hashCode()
        result = 31 * result + (details?.hashCode() ?: 0)
        return result
    }
}
