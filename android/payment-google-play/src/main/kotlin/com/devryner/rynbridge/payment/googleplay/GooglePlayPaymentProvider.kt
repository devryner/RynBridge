package com.devryner.rynbridge.payment.googleplay

import android.app.Activity
import com.android.billingclient.api.*
import com.devryner.rynbridge.payment.*
import kotlinx.coroutines.suspendCancellableCoroutine
import java.time.Instant
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Google Play Billing Provider.
 *
 * @param activity Activity context required for launching purchase flows
 */
class GooglePlayPaymentProvider(
    private val activity: Activity
) : PaymentProvider {

    private var billingClient: BillingClient? = null
    private var latestPurchase: com.android.billingclient.api.Purchase? = null

    private suspend fun ensureConnected(): BillingClient {
        billingClient?.let { if (it.isReady) return it }

        return suspendCancellableCoroutine { cont ->
            val client = BillingClient.newBuilder(activity)
                .setListener { billingResult, purchases ->
                    if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                        latestPurchase = purchases?.firstOrNull()
                    }
                }
                .enablePendingPurchases()
                .build()

            client.startConnection(object : BillingClientStateListener {
                override fun onBillingSetupFinished(billingResult: BillingResult) {
                    if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                        billingClient = client
                        cont.resume(client)
                    } else {
                        cont.resumeWithException(
                            RuntimeException("Billing setup failed: ${billingResult.debugMessage}")
                        )
                    }
                }

                override fun onBillingServiceDisconnected() {
                    billingClient = null
                }
            })
        }
    }

    override suspend fun getProducts(productIds: List<String>): List<Product> {
        val client = ensureConnected()

        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(productIds.map { id ->
                QueryProductDetailsParams.Product.newBuilder()
                    .setProductId(id)
                    .setProductType(BillingClient.ProductType.INAPP)
                    .build()
            })
            .build()

        val result = suspendCancellableCoroutine<List<ProductDetails>> { cont ->
            client.queryProductDetailsAsync(params) { billingResult, productDetailsList ->
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    cont.resume(productDetailsList)
                } else {
                    cont.resumeWithException(
                        RuntimeException("Query products failed: ${billingResult.debugMessage}")
                    )
                }
            }
        }

        return result.map { details ->
            val pricing = details.oneTimePurchaseOfferDetails
            Product(
                id = details.productId,
                title = details.title,
                description = details.description,
                price = pricing?.formattedPrice ?: "0",
                currency = pricing?.priceCurrencyCode ?: "USD"
            )
        }
    }

    override suspend fun purchase(productId: String, quantity: Int): PurchaseResult {
        val client = ensureConnected()

        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(listOf(
                QueryProductDetailsParams.Product.newBuilder()
                    .setProductId(productId)
                    .setProductType(BillingClient.ProductType.INAPP)
                    .build()
            ))
            .build()

        val details = suspendCancellableCoroutine<ProductDetails> { cont ->
            client.queryProductDetailsAsync(params) { billingResult, productDetailsList ->
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    val detail = productDetailsList.firstOrNull()
                    if (detail != null) {
                        cont.resume(detail)
                    } else {
                        cont.resumeWithException(RuntimeException("Product not found: $productId"))
                    }
                } else {
                    cont.resumeWithException(
                        RuntimeException("Query failed: ${billingResult.debugMessage}")
                    )
                }
            }
        }

        latestPurchase = null

        val flowParams = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(listOf(
                BillingFlowParams.ProductDetailsParams.newBuilder()
                    .setProductDetails(details)
                    .build()
            ))
            .build()

        val launchResult = client.launchBillingFlow(activity, flowParams)
        if (launchResult.responseCode != BillingClient.BillingResponseCode.OK) {
            throw RuntimeException("Launch billing flow failed: ${launchResult.debugMessage}")
        }

        // Wait for purchase callback
        val purchase = waitForPurchase()

        return PurchaseResult(
            transactionId = purchase.orderId ?: purchase.purchaseToken,
            productId = purchase.products.firstOrNull() ?: productId,
            receipt = purchase.originalJson
        )
    }

    private suspend fun waitForPurchase(): com.android.billingclient.api.Purchase {
        // Poll for the purchase result set by the PurchasesUpdatedListener
        repeat(300) {
            latestPurchase?.let { return it }
            kotlinx.coroutines.delay(100)
        }
        throw RuntimeException("Purchase timed out")
    }

    override suspend fun restorePurchases(): List<Transaction> {
        val client = ensureConnected()

        val params = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.INAPP)
            .build()

        val result = client.queryPurchasesAsync(params)

        return result.purchasesList.map { purchase ->
            Transaction(
                transactionId = purchase.orderId ?: purchase.purchaseToken,
                productId = purchase.products.firstOrNull() ?: "",
                purchaseDate = Instant.ofEpochMilli(purchase.purchaseTime).toString(),
                receipt = purchase.originalJson
            )
        }
    }

    override suspend fun finishTransaction(transactionId: String) {
        val client = ensureConnected()

        val params = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.INAPP)
            .build()

        val result = client.queryPurchasesAsync(params)
        val purchase = result.purchasesList.find {
            it.orderId == transactionId || it.purchaseToken == transactionId
        } ?: return

        if (purchase.purchaseState == com.android.billingclient.api.Purchase.PurchaseState.PURCHASED &&
            !purchase.isAcknowledged) {
            val ackParams = AcknowledgePurchaseParams.newBuilder()
                .setPurchaseToken(purchase.purchaseToken)
                .build()
            client.acknowledgePurchase(ackParams)
        }
    }
}
