package io.rynbridge.payment

import io.rynbridge.core.BridgeValue

data class Product(
    val id: String,
    val title: String,
    val description: String,
    val price: String,
    val currency: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "id" to BridgeValue.string(id),
        "title" to BridgeValue.string(title),
        "description" to BridgeValue.string(description),
        "price" to BridgeValue.string(price),
        "currency" to BridgeValue.string(currency)
    )
}

data class PurchaseResult(
    val transactionId: String,
    val productId: String,
    val receipt: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "transactionId" to BridgeValue.string(transactionId),
        "productId" to BridgeValue.string(productId),
        "receipt" to BridgeValue.string(receipt)
    )
}

data class Transaction(
    val transactionId: String,
    val productId: String,
    val purchaseDate: String,
    val receipt: String
) {
    fun toPayload(): Map<String, BridgeValue> = mapOf(
        "transactionId" to BridgeValue.string(transactionId),
        "productId" to BridgeValue.string(productId),
        "purchaseDate" to BridgeValue.string(purchaseDate),
        "receipt" to BridgeValue.string(receipt)
    )
}

interface PaymentProvider {
    suspend fun getProducts(productIds: List<String>): List<Product>
    suspend fun purchase(productId: String, quantity: Int): PurchaseResult
    suspend fun restorePurchases(): List<Transaction>
    suspend fun finishTransaction(transactionId: String)
}
