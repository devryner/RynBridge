import Foundation
import RynBridge

public struct AuthUser: Sendable {
    public let id: String
    public let email: String?
    public let name: String?
    public let profileImage: String?

    public init(id: String, email: String? = nil, name: String? = nil, profileImage: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.profileImage = profileImage
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "id": .string(id),
            "email": email.map { .string($0) } ?? .null,
            "name": name.map { .string($0) } ?? .null,
            "profileImage": profileImage.map { .string($0) } ?? .null,
        ]
    }
}

public struct LoginResult: Sendable {
    public let token: String
    public let refreshToken: String?
    public let expiresAt: String
    public let user: AuthUser?

    public init(token: String, refreshToken: String? = nil, expiresAt: String, user: AuthUser? = nil) {
        self.token = token
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.user = user
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "token": .string(token),
            "refreshToken": refreshToken.map { .string($0) } ?? .null,
            "expiresAt": .string(expiresAt),
            "user": user.map { .dictionary($0.toPayload()) } ?? .null,
        ]
    }
}

public struct TokenResult: Sendable {
    public let token: String?
    public let expiresAt: String?

    public init(token: String? = nil, expiresAt: String? = nil) {
        self.token = token
        self.expiresAt = expiresAt
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "token": token.map { .string($0) } ?? .null,
            "expiresAt": expiresAt.map { .string($0) } ?? .null,
        ]
    }
}

public struct AuthStateEvent: Sendable {
    public let authenticated: Bool
    public let user: AuthUser?

    public init(authenticated: Bool, user: AuthUser? = nil) {
        self.authenticated = authenticated
        self.user = user
    }

    public func toPayload() -> [String: AnyCodable] {
        [
            "authenticated": .bool(authenticated),
            "user": user.map { .dictionary($0.toPayload()) } ?? .null,
        ]
    }
}

public protocol AuthProvider: Sendable {
    func login(provider: String, scopes: [String]) async throws -> LoginResult
    func logout() async throws
    func getToken() async throws -> TokenResult
    func refreshToken() async throws -> LoginResult
    func getUser() async throws -> AuthUser?
}
