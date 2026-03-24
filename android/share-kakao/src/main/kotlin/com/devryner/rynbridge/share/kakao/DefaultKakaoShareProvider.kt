package com.devryner.rynbridge.share.kakao

import android.app.Activity
import android.content.Context
import com.kakao.sdk.share.ShareClient
import com.kakao.sdk.share.WebSharerClient
import com.devryner.rynbridge.core.BridgeValue
import com.devryner.rynbridge.core.RynBridgeError
import com.devryner.rynbridge.core.ErrorCode
import kotlinx.coroutines.suspendCancellableCoroutine
import java.lang.ref.WeakReference
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class DefaultKakaoShareProvider(activity: Activity) : KakaoShareProvider {

    private val activityRef = WeakReference(activity)
    private val context: Context = activity.applicationContext

    override suspend fun isAvailable(): Boolean {
        return ShareClient.instance.isKakaoTalkSharingAvailable(context)
    }

    override suspend fun shareFeed(payload: Map<String, BridgeValue>): KakaoShareResult {
        val template = KakaoTemplateMapper.feedTemplate(payload)
        return shareDefault(template)
    }

    override suspend fun shareCommerce(payload: Map<String, BridgeValue>): KakaoShareResult {
        val template = KakaoTemplateMapper.commerceTemplate(payload)
        return shareDefault(template)
    }

    override suspend fun shareList(payload: Map<String, BridgeValue>): KakaoShareResult {
        val template = KakaoTemplateMapper.listTemplate(payload)
        return shareDefault(template)
    }

    override suspend fun shareCustom(
        templateId: Long,
        templateArgs: Map<String, String>?,
        serverCallbackArgs: Map<String, String>?
    ): KakaoShareResult {
        val activity = activityRef.get()
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Activity is no longer available")

        if (ShareClient.instance.isKakaoTalkSharingAvailable(context)) {
            return suspendCancellableCoroutine { cont ->
                ShareClient.instance.shareCustom(
                    context,
                    templateId,
                    templateArgs,
                    serverCallbackArgs
                ) { sharingResult, error ->
                    if (error != null) {
                        cont.resumeWithException(
                            RynBridgeError(code = ErrorCode.UNKNOWN, message = "Kakao custom share failed: ${error.message}")
                        )
                    } else if (sharingResult != null) {
                        activity.startActivity(sharingResult.intent)
                        cont.resume(
                            KakaoShareResult(success = true, sharingUrl = sharingResult.intent.data?.toString())
                        )
                    } else {
                        cont.resume(KakaoShareResult(success = false))
                    }
                }
            }
        } else {
            val url = WebSharerClient.instance.makeCustomUrl(templateId, templateArgs, serverCallbackArgs)
            return KakaoShareResult(success = true, sharingUrl = url.toString())
        }
    }

    private suspend fun shareDefault(template: com.kakao.sdk.template.model.DefaultTemplate): KakaoShareResult {
        val activity = activityRef.get()
            ?: throw RynBridgeError(code = ErrorCode.UNKNOWN, message = "Activity is no longer available")

        if (ShareClient.instance.isKakaoTalkSharingAvailable(context)) {
            return suspendCancellableCoroutine { cont ->
                ShareClient.instance.shareDefault(context, template) { sharingResult, error ->
                    if (error != null) {
                        cont.resumeWithException(
                            RynBridgeError(code = ErrorCode.UNKNOWN, message = "Kakao share failed: ${error.message}")
                        )
                    } else if (sharingResult != null) {
                        activity.startActivity(sharingResult.intent)
                        cont.resume(
                            KakaoShareResult(success = true, sharingUrl = sharingResult.intent.data?.toString())
                        )
                    } else {
                        cont.resume(KakaoShareResult(success = false))
                    }
                }
            }
        } else {
            val url = WebSharerClient.instance.makeDefaultUrl(template)
            return KakaoShareResult(success = true, sharingUrl = url.toString())
        }
    }
}
