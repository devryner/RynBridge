import XCTest
@testable import RynBridge
@testable import RynBridgePayment

final class PaymentModuleTests: XCTestCase {
    func testGetProducts() async throws {
        let provider = MockPaymentProvider()
        let module = PaymentModule(provider: provider)
        let handler = module.actions["getProducts"]!

        let result = try await handler([
            "productIds": .array([.string("com.app.premium"), .string("com.app.coins")]),
        ])
        let products = result["products"]?.arrayValue
        XCTAssertNotNil(products)
        XCTAssertEqual(products?.count, 2)
        XCTAssertEqual(products?[0].dictionaryValue?["id"]?.stringValue, "com.app.premium")
        XCTAssertEqual(products?[0].dictionaryValue?["price"]?.stringValue, "9.99")
        XCTAssertEqual(products?[1].dictionaryValue?["id"]?.stringValue, "com.app.coins")
    }

    func testGetProductsPassesIds() async throws {
        let provider = MockPaymentProvider()
        let module = PaymentModule(provider: provider)
        let handler = module.actions["getProducts"]!

        _ = try await handler([
            "productIds": .array([.string("id1"), .string("id2")]),
        ])
        XCTAssertEqual(provider.lastRequestedProductIds, ["id1", "id2"])
    }

    func testPurchase() async throws {
        let provider = MockPaymentProvider()
        let module = PaymentModule(provider: provider)
        let handler = module.actions["purchase"]!

        let result = try await handler([
            "productId": .string("com.app.premium"),
            "quantity": .int(1),
        ])
        XCTAssertEqual(result["transactionId"]?.stringValue, "txn-001")
        XCTAssertEqual(result["productId"]?.stringValue, "com.app.premium")
        XCTAssertEqual(result["receipt"]?.stringValue, "receipt-data-xyz")
    }

    func testPurchaseDefaultQuantity() async throws {
        let provider = MockPaymentProvider()
        let module = PaymentModule(provider: provider)
        let handler = module.actions["purchase"]!

        _ = try await handler(["productId": .string("com.app.premium")])
        XCTAssertEqual(provider.lastPurchaseQuantity, 1)
    }

    func testRestorePurchases() async throws {
        let provider = MockPaymentProvider()
        let module = PaymentModule(provider: provider)
        let handler = module.actions["restorePurchases"]!

        let result = try await handler([:])
        let transactions = result["transactions"]?.arrayValue
        XCTAssertNotNil(transactions)
        XCTAssertEqual(transactions?.count, 1)
        XCTAssertEqual(transactions?[0].dictionaryValue?["transactionId"]?.stringValue, "txn-restored-001")
        XCTAssertEqual(transactions?[0].dictionaryValue?["purchaseDate"]?.stringValue, "2026-01-15T10:30:00Z")
    }

    func testFinishTransaction() async throws {
        let provider = MockPaymentProvider()
        let module = PaymentModule(provider: provider)
        let handler = module.actions["finishTransaction"]!

        let result = try await handler(["transactionId": .string("txn-001")])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastFinishedTransactionId, "txn-001")
    }

    func testModuleNameAndVersion() {
        let provider = MockPaymentProvider()
        let module = PaymentModule(provider: provider)
        XCTAssertEqual(module.name, "payment")
        XCTAssertEqual(module.version, "0.1.0")
    }

    func testEndToEndWithBridge() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))
        let provider = MockPaymentProvider()
        bridge.register(PaymentModule(provider: provider))

        let requestJSON = """
        {"id":"req-1","module":"payment","action":"restorePurchases","payload":{},"version":"0.1.0"}
        """
        transport.simulateIncoming(requestJSON)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(transport.sent.count, 1)
        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.id, "req-1")
        XCTAssertEqual(response.status, .success)
        XCTAssertNotNil(response.payload["transactions"])

        bridge.dispose()
    }
}

private final class MockPaymentProvider: PaymentProvider, @unchecked Sendable {
    var lastRequestedProductIds: [String]?
    var lastPurchaseQuantity: Int?
    var lastFinishedTransactionId: String?

    func getProducts(productIds: [String]) async throws -> [Product] {
        lastRequestedProductIds = productIds
        return productIds.enumerated().map { index, id in
            Product(
                id: id,
                title: "Product \(index + 1)",
                description: "Description for product \(index + 1)",
                price: index == 0 ? "9.99" : "4.99",
                currency: "USD"
            )
        }
    }

    func purchase(productId: String, quantity: Int) async throws -> PurchaseResult {
        lastPurchaseQuantity = quantity
        return PurchaseResult(
            transactionId: "txn-001",
            productId: productId,
            receipt: "receipt-data-xyz"
        )
    }

    func restorePurchases() async throws -> [Transaction] {
        [
            Transaction(
                transactionId: "txn-restored-001",
                productId: "com.app.premium",
                purchaseDate: "2026-01-15T10:30:00Z",
                receipt: "receipt-restored-xyz"
            ),
        ]
    }

    func finishTransaction(transactionId: String) async throws {
        lastFinishedTransactionId = transactionId
    }
}
