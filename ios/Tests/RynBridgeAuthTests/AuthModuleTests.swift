import XCTest
@testable import RynBridge
@testable import RynBridgeAuth

final class AuthModuleTests: XCTestCase {
    func testLogin() async throws {
        let provider = MockAuthProvider()
        let module = AuthModule(provider: provider)
        let handler = module.actions["login"]!

        let result = try await handler([
            "provider": .string("google"),
            "scopes": .array([.string("email"), .string("profile")]),
        ])
        XCTAssertEqual(result["token"]?.stringValue, "mock-token-123")
        XCTAssertEqual(result["refreshToken"]?.stringValue, "mock-refresh-456")
        XCTAssertEqual(result["expiresAt"]?.stringValue, "2026-12-31T23:59:59Z")
        XCTAssertNotNil(result["user"])
    }

    func testLoginPassesProviderAndScopes() async throws {
        let provider = MockAuthProvider()
        let module = AuthModule(provider: provider)
        let handler = module.actions["login"]!

        _ = try await handler([
            "provider": .string("apple"),
            "scopes": .array([.string("openid")]),
        ])
        XCTAssertEqual(provider.lastLoginProvider, "apple")
        XCTAssertEqual(provider.lastLoginScopes, ["openid"])
    }

    func testLoginWithoutScopes() async throws {
        let provider = MockAuthProvider()
        let module = AuthModule(provider: provider)
        let handler = module.actions["login"]!

        _ = try await handler(["provider": .string("google")])
        XCTAssertEqual(provider.lastLoginScopes, [])
    }

    func testLogout() async throws {
        let provider = MockAuthProvider()
        let module = AuthModule(provider: provider)
        let handler = module.actions["logout"]!

        let result = try await handler([:])
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(provider.logoutCalled)
    }

    func testGetToken() async throws {
        let provider = MockAuthProvider()
        let module = AuthModule(provider: provider)
        let handler = module.actions["getToken"]!

        let result = try await handler([:])
        XCTAssertEqual(result["token"]?.stringValue, "current-token-789")
        XCTAssertEqual(result["expiresAt"]?.stringValue, "2026-12-31T23:59:59Z")
    }

    func testRefreshToken() async throws {
        let provider = MockAuthProvider()
        let module = AuthModule(provider: provider)
        let handler = module.actions["refreshToken"]!

        let result = try await handler([:])
        XCTAssertEqual(result["token"]?.stringValue, "refreshed-token-000")
        XCTAssertEqual(result["expiresAt"]?.stringValue, "2027-01-01T00:00:00Z")
    }

    func testGetUser() async throws {
        let provider = MockAuthProvider()
        let module = AuthModule(provider: provider)
        let handler = module.actions["getUser"]!

        let result = try await handler([:])
        let user = result["user"]?.dictionaryValue
        XCTAssertNotNil(user)
        XCTAssertEqual(user?["id"]?.stringValue, "user-1")
        XCTAssertEqual(user?["email"]?.stringValue, "test@example.com")
        XCTAssertEqual(user?["name"]?.stringValue, "Test User")
    }

    func testModuleNameAndVersion() {
        let provider = MockAuthProvider()
        let module = AuthModule(provider: provider)
        XCTAssertEqual(module.name, "auth")
        XCTAssertEqual(module.version, "0.1.0")
    }

    func testEndToEndWithBridge() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))
        let provider = MockAuthProvider()
        bridge.register(AuthModule(provider: provider))

        let requestJSON = """
        {"id":"req-1","module":"auth","action":"getToken","payload":{},"version":"0.1.0"}
        """
        transport.simulateIncoming(requestJSON)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(transport.sent.count, 1)
        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.id, "req-1")
        XCTAssertEqual(response.status, .success)
        XCTAssertEqual(response.payload["token"]?.stringValue, "current-token-789")

        bridge.dispose()
    }
}

private final class MockAuthProvider: AuthProvider, @unchecked Sendable {
    var lastLoginProvider: String?
    var lastLoginScopes: [String]?
    var logoutCalled = false

    func login(provider: String, scopes: [String]) async throws -> LoginResult {
        lastLoginProvider = provider
        lastLoginScopes = scopes
        return LoginResult(
            token: "mock-token-123",
            refreshToken: "mock-refresh-456",
            expiresAt: "2026-12-31T23:59:59Z",
            user: AuthUser(id: "user-1", email: "test@example.com", name: "Test User", profileImage: nil)
        )
    }

    func logout() async throws {
        logoutCalled = true
    }

    func getToken() async throws -> TokenResult {
        TokenResult(token: "current-token-789", expiresAt: "2026-12-31T23:59:59Z")
    }

    func refreshToken() async throws -> LoginResult {
        LoginResult(
            token: "refreshed-token-000",
            expiresAt: "2027-01-01T00:00:00Z"
        )
    }

    func getUser() async throws -> AuthUser? {
        AuthUser(id: "user-1", email: "test@example.com", name: "Test User", profileImage: nil)
    }
}
