import Foundation
import RynBridge

public struct PaymentModule: BridgeModule, Sendable {
    public let name = "payment"
    public let version = "0.1.0"
    public let actions: [String: ActionHandler]

    public init(provider: PaymentProvider) {
        actions = [
            "getProducts": { payload in
                guard let ids = payload["productIds"]?.arrayValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: productIds")
                }
                let productIds = ids.compactMap { $0.stringValue }
                let products = try await provider.getProducts(productIds: productIds)
                return ["products": .array(products.map { .dictionary($0.toPayload()) })]
            },
            "purchase": { payload in
                guard let productId = payload["productId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: productId")
                }
                let quantity = payload["quantity"]?.intValue ?? 1
                let result = try await provider.purchase(productId: productId, quantity: quantity)
                return result.toPayload()
            },
            "restorePurchases": { _ in
                let transactions = try await provider.restorePurchases()
                return ["transactions": .array(transactions.map { .dictionary($0.toPayload()) })]
            },
            "finishTransaction": { payload in
                guard let transactionId = payload["transactionId"]?.stringValue else {
                    throw RynBridgeError(code: .invalidMessage, message: "Missing required field: transactionId")
                }
                try await provider.finishTransaction(transactionId: transactionId)
                return [:]
            },
        ]
    }
}
