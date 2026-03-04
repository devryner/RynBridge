import Foundation
import RynBridge

public struct Product: Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let price: String
    public let currency: String

    public init(id: String, title: String, description: String, price: String, currency: String) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.currency = currency
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "id": .string(id),
            "title": .string(title),
            "description": .string(description),
            "price": .string(price),
            "currency": .string(currency),
        ]
    }
}

public struct PurchaseResult: Sendable {
    public let transactionId: String
    public let productId: String
    public let receipt: String

    public init(transactionId: String, productId: String, receipt: String) {
        self.transactionId = transactionId
        self.productId = productId
        self.receipt = receipt
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "transactionId": .string(transactionId),
            "productId": .string(productId),
            "receipt": .string(receipt),
        ]
    }
}

public struct Transaction: Sendable {
    public let transactionId: String
    public let productId: String
    public let purchaseDate: String
    public let receipt: String

    public init(transactionId: String, productId: String, purchaseDate: String, receipt: String) {
        self.transactionId = transactionId
        self.productId = productId
        self.purchaseDate = purchaseDate
        self.receipt = receipt
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "transactionId": .string(transactionId),
            "productId": .string(productId),
            "purchaseDate": .string(purchaseDate),
            "receipt": .string(receipt),
        ]
    }
}

public protocol PaymentProvider: Sendable {
    func getProducts(productIds: [String]) async throws -> [Product]
    func purchase(productId: String, quantity: Int) async throws -> PurchaseResult
    func restorePurchases() async throws -> [Transaction]
    func finishTransaction(transactionId: String) async throws
}
