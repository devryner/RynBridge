package io.rynbridge.playground.providers

import io.rynbridge.payment.*
import java.time.Instant
import java.util.UUID

class MockPaymentProvider : PaymentProvider {
    override suspend fun getProducts(productIds: List<String>): List<Product> {
        return productIds.map { id ->
            Product(
                id = id,
                title = if (id == "premium_monthly") "Premium Monthly" else "Premium Yearly",
                description = "Unlock all features",
                price = if (id == "premium_monthly") "9.99" else "99.99",
                currency = "USD"
            )
        }
    }

    override suspend fun purchase(productId: String, quantity: Int): PurchaseResult {
        return PurchaseResult(
            transactionId = "txn_${UUID.randomUUID().toString().take(8)}",
            productId = productId,
            receipt = "mock_receipt_data"
        )
    }

    override suspend fun restorePurchases(): List<Transaction> {
        return listOf(
            Transaction(
                transactionId = "txn_restored_1",
                productId = "premium_monthly",
                purchaseDate = Instant.now().minusSeconds(86400).toString(),
                receipt = "mock_receipt_restored"
            )
        )
    }

    override suspend fun finishTransaction(transactionId: String) {}
}
