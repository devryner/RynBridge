package io.rynbridge.payment

import io.rynbridge.core.*

class PaymentModule(provider: PaymentProvider) : BridgeModule {

    override val name = "payment"
    override val version = "0.1.0"
    override val actions: Map<String, ActionHandler> = mapOf(
        "getProducts" to { payload ->
            val ids = payload["productIds"]?.arrayValue
                ?.mapNotNull { it.stringValue }
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: productIds")
            val products = provider.getProducts(ids)
            mapOf("products" to BridgeValue.array(products.map { BridgeValue.obj(it.toPayload()) }))
        },
        "purchase" to { payload ->
            val productId = payload["productId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: productId")
            val quantity = payload["quantity"]?.intValue?.toInt() ?: 1
            val result = provider.purchase(productId, quantity)
            result.toPayload()
        },
        "restorePurchases" to { _ ->
            val transactions = provider.restorePurchases()
            mapOf("transactions" to BridgeValue.array(transactions.map { BridgeValue.obj(it.toPayload()) }))
        },
        "finishTransaction" to { payload ->
            val transactionId = payload["transactionId"]?.stringValue
                ?: throw RynBridgeError(code = ErrorCode.INVALID_MESSAGE, message = "Missing required field: transactionId")
            provider.finishTransaction(transactionId)
            emptyMap()
        }
    )
}
