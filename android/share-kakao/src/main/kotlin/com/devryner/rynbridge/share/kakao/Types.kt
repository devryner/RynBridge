package com.devryner.rynbridge.share.kakao

import com.devryner.rynbridge.core.BridgeValue

data class KakaoShareResult(
    val success: Boolean,
    val sharingUrl: String? = null
) {
    fun toPayload(): Map<String, BridgeValue> {
        val result = mutableMapOf<String, BridgeValue>(
            "success" to BridgeValue.bool(success)
        )
        if (sharingUrl != null) {
            result["sharingUrl"] = BridgeValue.string(sharingUrl)
        }
        return result
    }
}

interface KakaoShareProvider {
    suspend fun isAvailable(): Boolean
    suspend fun shareFeed(payload: Map<String, BridgeValue>): KakaoShareResult
    suspend fun shareCommerce(payload: Map<String, BridgeValue>): KakaoShareResult
    suspend fun shareList(payload: Map<String, BridgeValue>): KakaoShareResult
    suspend fun shareCustom(templateId: Long, templateArgs: Map<String, String>?, serverCallbackArgs: Map<String, String>?): KakaoShareResult
}
