package io.rynbridge.core

sealed class BridgeValue {
    data class StringValue(val value: String) : BridgeValue()
    data class IntValue(val value: Long) : BridgeValue()
    data class DoubleValue(val value: Double) : BridgeValue()
    data class BoolValue(val value: Boolean) : BridgeValue()
    data class ArrayValue(val value: List<BridgeValue>) : BridgeValue()
    data class DictValue(val value: Map<String, BridgeValue>) : BridgeValue()
    data object NullValue : BridgeValue()

    val stringValue: String?
        get() = (this as? StringValue)?.value

    val intValue: Long?
        get() = (this as? IntValue)?.value

    val doubleValue: Double?
        get() = when (this) {
            is DoubleValue -> value
            is IntValue -> value.toDouble()
            else -> null
        }

    val boolValue: Boolean?
        get() = (this as? BoolValue)?.value

    val arrayValue: List<BridgeValue>?
        get() = (this as? ArrayValue)?.value

    val dictionaryValue: Map<String, BridgeValue>?
        get() = (this as? DictValue)?.value

    val isNull: Boolean
        get() = this is NullValue

    companion object {
        fun string(value: String) = StringValue(value)
        fun int(value: Long) = IntValue(value)
        fun int(value: Int) = IntValue(value.toLong())
        fun double(value: Double) = DoubleValue(value)
        fun bool(value: Boolean) = BoolValue(value)
        fun array(value: List<BridgeValue>) = ArrayValue(value)
        fun dict(value: Map<String, BridgeValue>) = DictValue(value)
        fun nullValue() = NullValue
    }
}
