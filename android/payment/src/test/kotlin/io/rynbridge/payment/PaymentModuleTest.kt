package io.rynbridge.payment

import io.rynbridge.core.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class PaymentModuleTest {

    @Test
    fun `getProducts returns product list`() = runTest {
        val provider = MockPaymentProvider()
        val module = PaymentModule(provider)
        val handler = module.actions["getProducts"]!!

        val result = handler(mapOf(
            "productIds" to BridgeValue.array(listOf(BridgeValue.string("prod-1"), BridgeValue.string("prod-2")))
        ))
        val products = result["products"]?.arrayValue
        assertNotNull(products)
        assertEquals(2, products?.size)
        assertEquals("prod-1", products?.get(0)?.dictionaryValue?.get("id")?.stringValue)
        assertEquals("Product 1", products?.get(0)?.dictionaryValue?.get("title")?.stringValue)
        assertEquals("9.99", products?.get(0)?.dictionaryValue?.get("price")?.stringValue)
        assertEquals("USD", products?.get(0)?.dictionaryValue?.get("currency")?.stringValue)
    }

    @Test
    fun `getProducts passes product ids to provider`() = runTest {
        val provider = MockPaymentProvider()
        val module = PaymentModule(provider)
        val handler = module.actions["getProducts"]!!

        handler(mapOf(
            "productIds" to BridgeValue.array(listOf(BridgeValue.string("abc")))
        ))
        assertEquals(listOf("abc"), provider.lastProductIds)
    }

    @Test
    fun `getProducts missing productIds throws`() = runTest {
        val provider = MockPaymentProvider()
        val module = PaymentModule(provider)
        val handler = module.actions["getProducts"]!!

        val error = assertThrows(RynBridgeError::class.java) {
            kotlinx.coroutines.test.runTest { handler(emptyMap()) }
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, error.code)
    }

    @Test
    fun `purchase returns purchase result`() = runTest {
        val provider = MockPaymentProvider()
        val module = PaymentModule(provider)
        val handler = module.actions["purchase"]!!

        val result = handler(mapOf(
            "productId" to BridgeValue.string("prod-1"),
            "quantity" to BridgeValue.int(2)
        ))
        assertEquals("txn-001", result["transactionId"]?.stringValue)
        assertEquals("prod-1", result["productId"]?.stringValue)
        assertEquals("mock-receipt", result["receipt"]?.stringValue)
        assertEquals("prod-1", provider.lastPurchaseProductId)
        assertEquals(2, provider.lastPurchaseQuantity)
    }

    @Test
    fun `purchase defaults quantity to 1`() = runTest {
        val provider = MockPaymentProvider()
        val module = PaymentModule(provider)
        val handler = module.actions["purchase"]!!

        handler(mapOf("productId" to BridgeValue.string("prod-1")))
        assertEquals(1, provider.lastPurchaseQuantity)
    }

    @Test
    fun `purchase missing productId throws`() = runTest {
        val provider = MockPaymentProvider()
        val module = PaymentModule(provider)
        val handler = module.actions["purchase"]!!

        val error = assertThrows(RynBridgeError::class.java) {
            kotlinx.coroutines.test.runTest { handler(emptyMap()) }
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, error.code)
    }

    @Test
    fun `restorePurchases returns transactions`() = runTest {
        val provider = MockPaymentProvider()
        val module = PaymentModule(provider)
        val handler = module.actions["restorePurchases"]!!

        val result = handler(emptyMap())
        val transactions = result["transactions"]?.arrayValue
        assertNotNull(transactions)
        assertEquals(1, transactions?.size)
        assertEquals("txn-old-001", transactions?.get(0)?.dictionaryValue?.get("transactionId")?.stringValue)
        assertEquals("prod-1", transactions?.get(0)?.dictionaryValue?.get("productId")?.stringValue)
        assertEquals("2026-01-15T10:00:00Z", transactions?.get(0)?.dictionaryValue?.get("purchaseDate")?.stringValue)
    }

    @Test
    fun `finishTransaction returns empty`() = runTest {
        val provider = MockPaymentProvider()
        val module = PaymentModule(provider)
        val handler = module.actions["finishTransaction"]!!

        val result = handler(mapOf("transactionId" to BridgeValue.string("txn-001")))
        assertTrue(result.isEmpty())
        assertEquals("txn-001", provider.lastFinishedTransactionId)
    }

    @Test
    fun `finishTransaction missing transactionId throws`() = runTest {
        val provider = MockPaymentProvider()
        val module = PaymentModule(provider)
        val handler = module.actions["finishTransaction"]!!

        val error = assertThrows(RynBridgeError::class.java) {
            kotlinx.coroutines.test.runTest { handler(emptyMap()) }
        }
        assertEquals(ErrorCode.INVALID_MESSAGE, error.code)
    }

    @Test
    fun `module name and version`() {
        val provider = MockPaymentProvider()
        val module = PaymentModule(provider)
        assertEquals("payment", module.name)
        assertEquals("0.1.0", module.version)
    }

    @Test
    fun `end to end with bridge`() = runTest {
        val transport = MockTransport()
        val bridge = RynBridge(transport = transport, config = BridgeConfig(timeout = 5000L))
        val provider = MockPaymentProvider()
        bridge.register(PaymentModule(provider))

        val requestJSON = """{"id":"req-1","module":"payment","action":"restorePurchases","payload":{},"version":"0.1.0"}"""
        transport.simulateIncoming(requestJSON)

        withContext(Dispatchers.Default) { delay(200) }

        assertEquals(1, transport.sent.size)
        val json = Json { ignoreUnknownKeys = true }
        val response = json.decodeFromString<BridgeResponse>(transport.sent[0])
        assertEquals("req-1", response.id)
        assertEquals(ResponseStatus.success, response.status)
        assertNotNull(response.payload["transactions"]?.arrayValue)

        bridge.dispose()
    }
}

private class MockPaymentProvider : PaymentProvider {
    var lastProductIds: List<String>? = null
    var lastPurchaseProductId: String? = null
    var lastPurchaseQuantity: Int? = null
    var lastFinishedTransactionId: String? = null

    override suspend fun getProducts(productIds: List<String>): List<Product> {
        lastProductIds = productIds
        return productIds.mapIndexed { index, id ->
            Product(
                id = id,
                title = "Product ${index + 1}",
                description = "Description for product ${index + 1}",
                price = "9.99",
                currency = "USD"
            )
        }
    }

    override suspend fun purchase(productId: String, quantity: Int): PurchaseResult {
        lastPurchaseProductId = productId
        lastPurchaseQuantity = quantity
        return PurchaseResult(
            transactionId = "txn-001",
            productId = productId,
            receipt = "mock-receipt"
        )
    }

    override suspend fun restorePurchases(): List<Transaction> {
        return listOf(
            Transaction(
                transactionId = "txn-old-001",
                productId = "prod-1",
                purchaseDate = "2026-01-15T10:00:00Z",
                receipt = "old-receipt"
            )
        )
    }

    override suspend fun finishTransaction(transactionId: String) {
        lastFinishedTransactionId = transactionId
    }
}
