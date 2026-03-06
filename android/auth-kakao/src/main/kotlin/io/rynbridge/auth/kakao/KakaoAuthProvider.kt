package io.rynbridge.auth.kakao

import android.content.Context
import com.kakao.sdk.auth.model.OAuthToken
import com.kakao.sdk.common.model.ClientError
import com.kakao.sdk.common.model.ClientErrorCause
import com.kakao.sdk.user.UserApiClient
import io.rynbridge.auth.*
import kotlinx.coroutines.suspendCancellableCoroutine
import java.time.Instant
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Kakao Login Provider.
 *
 * Requires KakaoSDK initialization in Application.onCreate:
 *   KakaoSdk.init(this, "YOUR_NATIVE_APP_KEY")
 *
 * @param context Activity or Application context
 */
class KakaoAuthProvider(
    private val context: Context
) : AuthProvider {

    private var currentToken: String? = null
    private var currentUser: AuthUser? = null

    override suspend fun login(provider: String, scopes: List<String>): LoginResult {
        val token = loginWithKakao()
        currentToken = token.accessToken

        val user = fetchUser()
        currentUser = user

        return LoginResult(
            token = token.accessToken,
            refreshToken = token.refreshToken,
            expiresAt = token.accessTokenExpiresAt?.let { Instant.ofEpochMilli(it.time).toString() }
                ?: Instant.now().plusSeconds(3600).toString(),
            user = user
        )
    }

    private suspend fun loginWithKakao(): OAuthToken {
        return suspendCancellableCoroutine { cont ->
            val callback: (OAuthToken?, Throwable?) -> Unit = { token, error ->
                if (error != null) {
                    cont.resumeWithException(error)
                } else if (token != null) {
                    cont.resume(token)
                } else {
                    cont.resumeWithException(RuntimeException("Kakao login failed: no token"))
                }
            }

            if (UserApiClient.instance.isKakaoTalkLoginAvailable(context)) {
                UserApiClient.instance.loginWithKakaoTalk(context) { token, error ->
                    if (error != null) {
                        if (error is ClientError && error.reason == ClientErrorCause.Cancelled) {
                            cont.resumeWithException(error)
                            return@loginWithKakaoTalk
                        }
                        UserApiClient.instance.loginWithKakaoAccount(context, callback = callback)
                    } else {
                        callback(token, null)
                    }
                }
            } else {
                UserApiClient.instance.loginWithKakaoAccount(context, callback = callback)
            }
        }
    }

    private suspend fun fetchUser(): AuthUser? {
        return suspendCancellableCoroutine { cont ->
            UserApiClient.instance.me { user, error ->
                if (error != null) {
                    cont.resume(null)
                } else {
                    cont.resume(user?.let {
                        AuthUser(
                            id = it.id?.toString() ?: "",
                            email = it.kakaoAccount?.email,
                            name = it.kakaoAccount?.profile?.nickname,
                            profileImage = it.kakaoAccount?.profile?.thumbnailImageUrl
                        )
                    })
                }
            }
        }
    }

    override suspend fun logout() {
        suspendCancellableCoroutine { cont ->
            UserApiClient.instance.logout { error ->
                if (error != null) {
                    cont.resumeWithException(error)
                } else {
                    currentToken = null
                    currentUser = null
                    cont.resume(Unit)
                }
            }
        }
    }

    override suspend fun getToken(): TokenResult {
        return TokenResult(token = currentToken, expiresAt = null)
    }

    override suspend fun refreshToken(): LoginResult {
        return login("kakao", emptyList())
    }

    override suspend fun getUser(): AuthUser? {
        return currentUser ?: fetchUser()
    }
}
