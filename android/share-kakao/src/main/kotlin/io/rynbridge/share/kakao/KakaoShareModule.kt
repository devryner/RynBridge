package io.rynbridge.share.kakao

import io.rynbridge.core.*

class KakaoShareModule(provider: KakaoShareProvider) : BridgeModule {

    override val name = "kakaoShare"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "isAvailable" to { _ ->
            val available = provider.isAvailable()
            mapOf("available" to BridgeValue.bool(available))
        },
        "shareFeed" to { payload ->
            val result = provider.shareFeed(payload)
            result.toPayload()
        },
        "shareCommerce" to { payload ->
            val result = provider.shareCommerce(payload)
            result.toPayload()
        },
        "shareList" to { payload ->
            val result = provider.shareList(payload)
            result.toPayload()
        },
        "shareCustom" to { payload ->
            val templateId = payload["templateId"]?.intValue?.toLong()
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: templateId")
            val templateArgs = KakaoTemplateMapper.mapStringDict(payload["templateArgs"])
            val serverCallbackArgs = KakaoTemplateMapper.mapStringDict(payload["serverCallbackArgs"])
            val result = provider.shareCustom(templateId, templateArgs, serverCallbackArgs)
            result.toPayload()
        }
    )
}
