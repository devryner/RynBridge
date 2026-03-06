import Foundation
import AuthenticationServices
import RynBridge
import RynBridgeAuth

#if canImport(UIKit)
@available(iOS 17.0, *)
public final class AppleAuthProvider: NSObject, AuthProvider, @unchecked Sendable {
    private var currentUser: AuthUser?
    private var currentToken: String?

    public override init() {
        super.init()
    }

    public func login(provider: String, scopes: [String]) async throws -> LoginResult {
        return try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            var requestedScopes: [ASAuthorization.Scope] = []
            if scopes.contains("email") { requestedScopes.append(.email) }
            if scopes.contains("fullName") || scopes.contains("name") { requestedScopes.append(.fullName) }
            request.requestedScopes = requestedScopes

            let delegate = AppleSignInDelegate(continuation: continuation, onComplete: { [weak self] result in
                self?.currentToken = result.token
                self?.currentUser = result.user
            })

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = delegate
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            controller.performRequests()
        }
    }

    public func logout() async throws {
        currentToken = nil
        currentUser = nil
    }

    public func getToken() async throws -> TokenResult {
        return TokenResult(token: currentToken, expiresAt: nil)
    }

    public func refreshToken() async throws -> LoginResult {
        return try await login(provider: "apple", scopes: [])
    }

    public func getUser() async throws -> AuthUser? {
        return currentUser
    }
}

@available(iOS 17.0, *)
private final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, @unchecked Sendable {
    private let continuation: CheckedContinuation<LoginResult, Error>
    private let onComplete: (LoginResult) -> Void
    private var resumed = false

    init(continuation: CheckedContinuation<LoginResult, Error>, onComplete: @escaping (LoginResult) -> Void) {
        self.continuation = continuation
        self.onComplete = onComplete
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard !resumed else { return }
        resumed = true

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation.resume(throwing: RynBridgeError(code: .unknown, message: "Invalid Apple ID credential"))
            return
        }

        let token: String
        if let tokenData = credential.identityToken, let tokenStr = String(data: tokenData, encoding: .utf8) {
            token = tokenStr
        } else {
            token = credential.user
        }

        let fullName = credential.fullName
        let name = [fullName?.givenName, fullName?.familyName].compactMap { $0 }.joined(separator: " ")

        let user = AuthUser(
            id: credential.user,
            email: credential.email,
            name: name.isEmpty ? nil : name
        )

        let result = LoginResult(
            token: token,
            refreshToken: nil,
            expiresAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)),
            user: user
        )

        onComplete(result)
        continuation.resume(returning: result)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard !resumed else { return }
        resumed = true
        continuation.resume(throwing: RynBridgeError(code: .unknown, message: "Apple Sign-In failed: \(error.localizedDescription)"))
    }
}
#endif
