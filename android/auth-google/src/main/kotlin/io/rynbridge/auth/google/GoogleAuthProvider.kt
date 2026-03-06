package io.rynbridge.auth.google

import io.rynbridge.auth.*

/**
 * Google Sign-In Provider for Android.
 *
 * Requires Google Sign-In SDK dependency:
 *   implementation("com.google.android.gms:play-services-auth:21.0.0")
 *
 * Usage:
 *   bridge.register(AuthModule(GoogleAuthProvider(activity)))
 */
class GoogleAuthProvider : AuthProvider {

    override suspend fun login(provider: String, scopes: List<String>): LoginResult {
        // TODO: Implement with Google Sign-In SDK
        // val signInClient = Identity.getSignInClient(activity)
        // val signInRequest = GetSignInIntentRequest.builder()...
        throw UnsupportedOperationException("GoogleAuthProvider requires Google Sign-In SDK integration. Add 'com.google.android.gms:play-services-auth' dependency.")
    }

    override suspend fun logout() {
        // TODO: signInClient.signOut()
        throw UnsupportedOperationException("GoogleAuthProvider requires Google Sign-In SDK integration.")
    }

    override suspend fun getToken(): TokenResult {
        throw UnsupportedOperationException("GoogleAuthProvider requires Google Sign-In SDK integration.")
    }

    override suspend fun refreshToken(): LoginResult {
        throw UnsupportedOperationException("GoogleAuthProvider requires Google Sign-In SDK integration.")
    }

    override suspend fun getUser(): AuthUser? {
        throw UnsupportedOperationException("GoogleAuthProvider requires Google Sign-In SDK integration.")
    }
}
