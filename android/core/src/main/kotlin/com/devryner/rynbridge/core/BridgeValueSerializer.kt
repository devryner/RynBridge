package com.devryner.rynbridge.core

import kotlinx.serialization.KSerializer
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.descriptors.buildClassSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.*

object BridgeValueSerializer : KSerializer<BridgeValue> {
    override val descriptor: SerialDescriptor =
        buildClassSerialDescriptor("BridgeValue")

    override fun serialize(encoder: Encoder, value: BridgeValue) {
        val jsonEncoder = encoder as? JsonEncoder
            ?: throw IllegalStateException("BridgeValue can only be serialized with JSON")
        jsonEncoder.encodeJsonElement(toJsonElement(value))
    }

    override fun deserialize(decoder: Decoder): BridgeValue {
        val jsonDecoder = decoder as? JsonDecoder
            ?: throw IllegalStateException("BridgeValue can only be deserialized with JSON")
        return fromJsonElement(jsonDecoder.decodeJsonElement())
    }

    fun toJsonElement(value: BridgeValue): JsonElement = when (value) {
        is BridgeValue.StringValue -> JsonPrimitive(value.value)
        is BridgeValue.IntValue -> JsonPrimitive(value.value)
        is BridgeValue.DoubleValue -> JsonPrimitive(value.value)
        is BridgeValue.BoolValue -> JsonPrimitive(value.value)
        is BridgeValue.ArrayValue -> JsonArray(value.value.map { toJsonElement(it) })
        is BridgeValue.DictValue -> JsonObject(value.value.mapValues { toJsonElement(it.value) })
        is BridgeValue.NullValue -> JsonNull
    }

    fun fromJsonElement(element: JsonElement): BridgeValue = when (element) {
        is JsonNull -> BridgeValue.NullValue
        is JsonPrimitive -> parsePrimitive(element)
        is JsonArray -> BridgeValue.ArrayValue(element.map { fromJsonElement(it) })
        is JsonObject -> BridgeValue.DictValue(element.mapValues { fromJsonElement(it.value) })
    }

    private fun parsePrimitive(primitive: JsonPrimitive): BridgeValue {
        if (primitive.isString) {
            return BridgeValue.StringValue(primitive.content)
        }
        // Try boolean
        primitive.booleanOrNull?.let { return BridgeValue.BoolValue(it) }
        // Try long (integer)
        primitive.longOrNull?.let { return BridgeValue.IntValue(it) }
        // Try double
        primitive.doubleOrNull?.let { return BridgeValue.DoubleValue(it) }
        // Fallback to string
        return BridgeValue.StringValue(primitive.content)
    }
}

object BridgeValueMapSerializer : KSerializer<Map<String, BridgeValue>> {
    override val descriptor: SerialDescriptor =
        buildClassSerialDescriptor("BridgeValueMap")

    override fun serialize(encoder: Encoder, value: Map<String, BridgeValue>) {
        val jsonEncoder = encoder as? JsonEncoder
            ?: throw IllegalStateException("BridgeValueMap can only be serialized with JSON")
        val jsonObject = JsonObject(value.mapValues { BridgeValueSerializer.toJsonElement(it.value) })
        jsonEncoder.encodeJsonElement(jsonObject)
    }

    override fun deserialize(decoder: Decoder): Map<String, BridgeValue> {
        val jsonDecoder = decoder as? JsonDecoder
            ?: throw IllegalStateException("BridgeValueMap can only be deserialized with JSON")
        val jsonObject = jsonDecoder.decodeJsonElement().jsonObject
        return jsonObject.mapValues { BridgeValueSerializer.fromJsonElement(it.value) }
    }
}
