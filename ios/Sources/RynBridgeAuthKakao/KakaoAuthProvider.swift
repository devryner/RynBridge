import Foundation
import RynBridge
import RynBridgeAuth

#if canImport(KakaoSDKUser)
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

@available(iOS 17.0, *)
public final class KakaoAuthProvider: AuthProvider, @unchecked Sendable {
    private var currentToken: String?
    private var currentUser: AuthUser?

    public init() {
        self.currentToken = nil
        self.currentUser = nil
    }

    public func login(provider: String, scopes: [String]) async throws -> LoginResult {
        let token = try await loginWithKakao()
        currentToken = token.accessToken

        let user = try await fetchUser()
        currentUser = user

        let expiresAt = token.expiredAt.map { ISO8601DateFormatter().string(from: $0) }
            ?? ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600))

        return LoginResult(
            token: token.accessToken,
            refreshToken: token.refreshToken,
            expiresAt: expiresAt,
            user: user
        )
    }

    private func loginWithKakao() async throws -> OAuthToken {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                if UserApi.isKakaoTalkLoginAvailable() {
                    UserApi.shared.loginWithKakaoTalk { token, error in
                        if let error {
                            // Fallback to Kakao Account login
                            UserApi.shared.loginWithKakaoAccount { token, error in
                                if let error { continuation.resume(throwing: error) }
                                else if let token { continuation.resume(returning: token) }
                                else { continuation.resume(throwing: RynBridgeError(code: .unknown, message: "Kakao login failed")) }
                            }
                        } else if let token {
                            continuation.resume(returning: token)
                        } else {
                            continuation.resume(throwing: RynBridgeError(code: .unknown, message: "Kakao login failed"))
                        }
                    }
                } else {
                    UserApi.shared.loginWithKakaoAccount { token, error in
                        if let error { continuation.resume(throwing: error) }
                        else if let token { continuation.resume(returning: token) }
                        else { continuation.resume(throwing: RynBridgeError(code: .unknown, message: "Kakao login failed")) }
                    }
                }
            }
        }
    }

    private func fetchUser() async throws -> AuthUser? {
        return try await withCheckedThrowingContinuation { continuation in
            UserApi.shared.me { user, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let user else {
                    continuation.resume(returning: nil)
                    return
                }
                let authUser = AuthUser(
                    id: String(user.id ?? 0),
                    email: user.kakaoAccount?.email,
                    name: user.kakaoAccount?.profile?.nickname,
                    profileImage: user.kakaoAccount?.profile?.thumbnailImageUrl?.absoluteString
                )
                continuation.resume(returning: authUser)
            }
        }
    }

    public func logout() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UserApi.shared.logout { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        currentToken = nil
        currentUser = nil
    }

    public func getToken() async throws -> TokenResult {
        return TokenResult(token: currentToken, expiresAt: nil)
    }

    public func refreshToken() async throws -> LoginResult {
        return try await login(provider: "kakao", scopes: [])
    }

    public func getUser() async throws -> AuthUser? {
        if let currentUser { return currentUser }
        return try await fetchUser()
    }
}
#endif
