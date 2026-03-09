#if canImport(UIKit)
import Foundation
import RynBridge
import KakaoSDKTemplate

enum KakaoTemplateMapper {

    // MARK: - Feed Template

    static func feedTemplate(from payload: [String: AnyCodable]) throws -> FeedTemplate {
        guard let contentDict = payload["content"]?.dictionaryValue else {
            throw RynBridgeError(code: .invalidMessage, message: "Missing required field: content")
        }
        let content = try mapContent(from: contentDict)
        let social = payload["social"]?.dictionaryValue.flatMap { mapSocial(from: $0) }
        let buttons = mapButtons(from: payload["buttons"])
        return FeedTemplate(content: content, social: social, buttons: buttons)
    }

    // MARK: - Commerce Template

    static func commerceTemplate(from payload: [String: AnyCodable]) throws -> CommerceTemplate {
        guard let contentDict = payload["content"]?.dictionaryValue else {
            throw RynBridgeError(code: .invalidMessage, message: "Missing required field: content")
        }
        guard let commerceDict = payload["commerce"]?.dictionaryValue else {
            throw RynBridgeError(code: .invalidMessage, message: "Missing required field: commerce")
        }
        let content = try mapContent(from: contentDict)
        let commerce = mapCommerce(from: commerceDict)
        let buttons = mapButtons(from: payload["buttons"])
        return CommerceTemplate(content: content, commerce: commerce, buttons: buttons)
    }

    // MARK: - List Template

    static func listTemplate(from payload: [String: AnyCodable]) throws -> ListTemplate {
        guard let headerTitle = payload["headerTitle"]?.stringValue else {
            throw RynBridgeError(code: .invalidMessage, message: "Missing required field: headerTitle")
        }
        guard let headerLinkDict = payload["headerLink"]?.dictionaryValue else {
            throw RynBridgeError(code: .invalidMessage, message: "Missing required field: headerLink")
        }
        guard let contentsArray = payload["contents"]?.arrayValue else {
            throw RynBridgeError(code: .invalidMessage, message: "Missing required field: contents")
        }

        let headerLink = mapLink(from: headerLinkDict)
        let contents = try contentsArray.compactMap { item -> Content? in
            guard let dict = item.dictionaryValue else { return nil }
            return try mapContent(from: dict)
        }
        let buttons = mapButtons(from: payload["buttons"])
        return ListTemplate(headerTitle: headerTitle, headerLink: headerLink, contents: contents, buttons: buttons)
    }

    // MARK: - Shared Mappers

    static func mapContent(from dict: [String: AnyCodable]) throws -> Content {
        guard let title = dict["title"]?.stringValue else {
            throw RynBridgeError(code: .invalidMessage, message: "Missing required field: content.title")
        }
        guard let imageUrlString = dict["imageUrl"]?.stringValue,
              let imageUrl = URL(string: imageUrlString) else {
            throw RynBridgeError(code: .invalidMessage, message: "Missing or invalid field: content.imageUrl")
        }

        let linkDict = dict["link"]?.dictionaryValue ?? [:]
        let link = mapLink(from: linkDict)
        let description = dict["description"]?.stringValue
        let imageWidth = dict["imageWidth"]?.intValue
        let imageHeight = dict["imageHeight"]?.intValue

        return Content(
            title: title,
            imageUrl: imageUrl,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            description: description,
            link: link
        )
    }

    static func mapLink(from dict: [String: AnyCodable]) -> Link {
        let webUrl = dict["webUrl"]?.stringValue.flatMap { URL(string: $0) }
        let mobileWebUrl = dict["mobileWebUrl"]?.stringValue.flatMap { URL(string: $0) }
        let androidExecutionParams = mapStringDict(dict["androidExecutionParams"])
        let iosExecutionParams = mapStringDict(dict["iosExecutionParams"])
        return Link(
            webUrl: webUrl,
            mobileWebUrl: mobileWebUrl,
            androidExecutionParams: androidExecutionParams,
            iosExecutionParams: iosExecutionParams
        )
    }

    static func mapSocial(from dict: [String: AnyCodable]) -> Social? {
        Social(
            likeCount: dict["likeCount"]?.intValue,
            commentCount: dict["commentCount"]?.intValue,
            sharedCount: dict["sharedCount"]?.intValue,
            viewCount: dict["viewCount"]?.intValue,
            subscriberCount: dict["subscriberCount"]?.intValue
        )
    }

    static func mapCommerce(from dict: [String: AnyCodable]) -> CommerceDetail {
        return CommerceDetail(
            regularPrice: dict["regularPrice"]?.intValue ?? 0,
            discountPrice: dict["discountPrice"]?.intValue,
            discountRate: dict["discountRate"]?.intValue,
            fixedDiscountPrice: dict["fixedDiscountPrice"]?.intValue,
            productName: dict["productName"]?.stringValue,
            currencyUnit: dict["currencyUnit"]?.stringValue,
            currencyUnitPosition: dict["currencyUnitPosition"]?.intValue
        )
    }

    static func mapButtons(from value: AnyCodable?) -> [Button]? {
        guard let array = value?.arrayValue else { return nil }
        let buttons = array.compactMap { item -> Button? in
            guard let dict = item.dictionaryValue,
                  let title = dict["title"]?.stringValue else { return nil }
            let linkDict = dict["link"]?.dictionaryValue ?? [:]
            let link = mapLink(from: linkDict)
            return Button(title: title, link: link)
        }
        return buttons.isEmpty ? nil : buttons
    }

    static func mapStringDict(_ value: AnyCodable?) -> [String: String]? {
        guard let dict = value?.dictionaryValue else { return nil }
        var result: [String: String] = [:]
        for (key, val) in dict {
            if let str = val.stringValue {
                result[key] = str
            }
        }
        return result.isEmpty ? nil : result
    }
}
#endif
