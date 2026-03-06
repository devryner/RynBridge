package io.rynbridge.auth.google

import android.content.Context
import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import io.rynbridge.auth.*
import java.time.Instant

/**
 * Google Sign-In Provider using Credential Manager API.
 *
 * @param context Application or Activity context
 * @param serverClientId Web client ID from Google Cloud Console
 */
class GoogleAuthProvider(
    private val context: Context,
    private val serverClientId: String
) : AuthProvider {

    private val credentialManager = CredentialManager.create(context)
    private var currentToken: String? = null
    private var currentUser: AuthUser? = null

    override suspend fun login(provider: String, scopes: List<String>): LoginResult {
        val googleIdOption = GetGoogleIdOption.Builder()
            .setFilterByAuthorizedAccounts(false)
            .setServerClientId(serverClientId)
            .build()

        val request = GetCredentialRequest.Builder()
            .addCredentialOption(googleIdOption)
            .build()

        val result = credentialManager.getCredential(context, request)
        val credential = result.credential

        val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)
        val idToken = googleIdTokenCredential.idToken

        currentToken = idToken
        val user = AuthUser(
            id = googleIdTokenCredential.id,
            email = googleIdTokenCredential.id,
            name = googleIdTokenCredential.displayName,
            profileImage = googleIdTokenCredential.profilePictureUri?.toString()
        )
        currentUser = user

        return LoginResult(
            token = idToken,
            refreshToken = null,
            expiresAt = Instant.now().plusSeconds(3600).toString(),
            user = user
        )
    }

    override suspend fun logout() {
        credentialManager.clearCredentialState(ClearCredentialStateRequest())
        currentToken = null
        currentUser = null
    }

    override suspend fun getToken(): TokenResult {
        return TokenResult(
            token = currentToken,
            expiresAt = currentToken?.let { Instant.now().plusSeconds(3600).toString() }
        )
    }

    override suspend fun refreshToken(): LoginResult {
        return login("google", emptyList())
    }

    override suspend fun getUser(): AuthUser? {
        return currentUser
    }
}
