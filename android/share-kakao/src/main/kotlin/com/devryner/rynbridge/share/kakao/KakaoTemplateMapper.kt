package com.devryner.rynbridge.share.kakao

import com.kakao.sdk.template.model.*
import com.devryner.rynbridge.core.BridgeValue
import com.devryner.rynbridge.core.RynBridgeError
import com.devryner.rynbridge.core.ErrorCode

object KakaoTemplateMapper {

    fun feedTemplate(from: Map<String, BridgeValue>): FeedTemplate {
        val contentMap = from["content"]?.dictionaryValue
            ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: content")
        val content = mapContent(contentMap)
        val social = from["social"]?.dictionaryValue?.let { mapSocial(it) }
        val buttons = mapButtons(from["buttons"])
        return FeedTemplate(content = content, social = social, buttons = buttons)
    }

    fun commerceTemplate(from: Map<String, BridgeValue>): CommerceTemplate {
        val contentMap = from["content"]?.dictionaryValue
            ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: content")
        val commerceMap = from["commerce"]?.dictionaryValue
            ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: commerce")
        val content = mapContent(contentMap)
        val commerce = mapCommerce(commerceMap)
        val buttons = mapButtons(from["buttons"])
        return CommerceTemplate(content = content, commerce = commerce, buttons = buttons)
    }

    fun listTemplate(from: Map<String, BridgeValue>): ListTemplate {
        val headerTitle = from["headerTitle"]?.stringValue
            ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: headerTitle")
        val headerLinkMap = from["headerLink"]?.dictionaryValue
            ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: headerLink")
        val contentsArray = from["contents"]?.arrayValue
            ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: contents")

        val headerLink = mapLink(headerLinkMap)
        val contents = contentsArray.mapNotNull { item ->
            item.dictionaryValue?.let { mapContent(it) }
        }
        val buttons = mapButtons(from["buttons"])
        return ListTemplate(headerTitle = headerTitle, headerLink = headerLink, contents = contents, buttons = buttons)
    }

    private fun mapContent(dict: Map<String, BridgeValue>): Content {
        val title = dict["title"]?.stringValue
            ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: content.title")
        val imageUrl = dict["imageUrl"]?.stringValue
            ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: content.imageUrl")
        val linkMap = dict["link"]?.dictionaryValue ?: emptyMap()
        val link = mapLink(linkMap)
        val description = dict["description"]?.stringValue
        val imageWidth = dict["imageWidth"]?.intValue?.toInt()
        val imageHeight = dict["imageHeight"]?.intValue?.toInt()

        return Content(
            title = title,
            imageUrl = imageUrl,
            imageWidth = imageWidth,
            imageHeight = imageHeight,
            description = description,
            link = link
        )
    }

    private fun mapLink(dict: Map<String, BridgeValue>): Link {
        return Link(
            webUrl = dict["webUrl"]?.stringValue,
            mobileWebUrl = dict["mobileWebUrl"]?.stringValue,
            androidExecutionParams = mapStringDict(dict["androidExecutionParams"]),
            iosExecutionParams = mapStringDict(dict["iosExecutionParams"])
        )
    }

    private fun mapSocial(dict: Map<String, BridgeValue>): Social {
        return Social(
            likeCount = dict["likeCount"]?.intValue?.toInt(),
            commentCount = dict["commentCount"]?.intValue?.toInt(),
            sharedCount = dict["sharedCount"]?.intValue?.toInt(),
            viewCount = dict["viewCount"]?.intValue?.toInt(),
            subscriberCount = dict["subscriberCount"]?.intValue?.toInt()
        )
    }

    private fun mapCommerce(dict: Map<String, BridgeValue>): Commerce {
        return Commerce(
            regularPrice = dict["regularPrice"]?.intValue?.toInt() ?: 0,
            discountPrice = dict["discountPrice"]?.intValue?.toInt(),
            discountRate = dict["discountRate"]?.intValue?.toInt(),
            fixedDiscountPrice = dict["fixedDiscountPrice"]?.intValue?.toInt(),
            productName = dict["productName"]?.stringValue,
            currencyUnit = dict["currencyUnit"]?.stringValue,
            currencyUnitPosition = dict["currencyUnitPosition"]?.intValue?.toInt()
        )
    }

    private fun mapButtons(value: BridgeValue?): List<Button>? {
        val array = value?.arrayValue ?: return null
        val buttons = array.mapNotNull { item ->
            val dict = item.dictionaryValue ?: return@mapNotNull null
            val title = dict["title"]?.stringValue ?: return@mapNotNull null
            val linkMap = dict["link"]?.dictionaryValue ?: emptyMap()
            val link = mapLink(linkMap)
            Button(title = title, link = link)
        }
        return buttons.ifEmpty { null }
    }

    fun mapStringDict(value: BridgeValue?): Map<String, String>? {
        val dict = value?.dictionaryValue ?: return null
        val result = mutableMapOf<String, String>()
        for ((key, v) in dict) {
            v.stringValue?.let { result[key] = it }
        }
        return result.ifEmpty { null }
    }
}
