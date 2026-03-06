package io.rynbridge.payment.googleplay

import io.rynbridge.payment.*

/**
 * Google Play Billing Provider for Android.
 *
 * Requires Google Play Billing SDK dependency:
 *   implementation("com.android.billingclient:billing-ktx:7.0.0")
 *
 * Usage:
 *   bridge.register(PaymentModule(GooglePlayPaymentProvider(activity)))
 */
class GooglePlayPaymentProvider : PaymentProvider {

    override suspend fun getProducts(productIds: List<String>): List<Product> {
        // TODO: Implement with BillingClient
        // val billingClient = BillingClient.newBuilder(context)...
        throw UnsupportedOperationException("GooglePlayPaymentProvider requires Play Billing SDK. Add 'com.android.billingclient:billing-ktx' dependency.")
    }

    override suspend fun purchase(productId: String, quantity: Int): PurchaseResult {
        throw UnsupportedOperationException("GooglePlayPaymentProvider requires Play Billing SDK.")
    }

    override suspend fun restorePurchases(): List<Transaction> {
        throw UnsupportedOperationException("GooglePlayPaymentProvider requires Play Billing SDK.")
    }

    override suspend fun finishTransaction(transactionId: String) {
        throw UnsupportedOperationException("GooglePlayPaymentProvider requires Play Billing SDK.")
    }
}
