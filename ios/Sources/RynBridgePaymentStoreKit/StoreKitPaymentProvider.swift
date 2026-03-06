import Foundation
import StoreKit
import RynBridge
import RynBridgePayment

@available(iOS 17.0, *)
public final class StoreKitPaymentProvider: PaymentProvider, @unchecked Sendable {

    public init() {}

    public func getProducts(productIds: [String]) async throws -> [Product] {
        let storeProducts = try await StoreKit.Product.products(for: Set(productIds))
        return storeProducts.map { product in
            Product(
                id: product.id,
                title: product.displayName,
                description: product.description,
                price: product.displayPrice,
                currency: product.priceFormatStyle.currencyCode
            )
        }
    }

    public func purchase(productId: String, quantity: Int) async throws -> PurchaseResult {
        let products = try await StoreKit.Product.products(for: [productId])
        guard let product = products.first else {
            throw RynBridgeError(code: .unknown, message: "Product not found: \(productId)")
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            return PurchaseResult(
                transactionId: String(transaction.id),
                productId: transaction.productID,
                receipt: transaction.jsonRepresentation.base64EncodedString()
            )
        case .userCancelled:
            throw RynBridgeError(code: .unknown, message: "Purchase cancelled by user")
        case .pending:
            throw RynBridgeError(code: .unknown, message: "Purchase is pending approval")
        @unknown default:
            throw RynBridgeError(code: .unknown, message: "Unknown purchase result")
        }
    }

    public func restorePurchases() async throws -> [Transaction] {
        var transactions: [Transaction] = []
        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                transactions.append(Transaction(
                    transactionId: String(transaction.id),
                    productId: transaction.productID,
                    purchaseDate: ISO8601DateFormatter().string(from: transaction.purchaseDate),
                    receipt: transaction.jsonRepresentation.base64EncodedString()
                ))
            }
        }
        return transactions
    }

    public func finishTransaction(transactionId: String) async throws {
        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               String(transaction.id) == transactionId {
                await transaction.finish()
                return
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw RynBridgeError(code: .unknown, message: "Verification failed: \(error.localizedDescription)")
        case .verified(let item):
            return item
        }
    }
}
