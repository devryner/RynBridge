package com.devryner.rynbridge.translation

import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.common.model.RemoteModelManager
import com.google.mlkit.nl.languageid.LanguageIdentification
import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.TranslateRemoteModel
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.TranslatorOptions
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class DefaultTranslationProvider : TranslationProvider {

    override suspend fun translate(text: String, source: String, target: String): TranslateResult {
        val options = TranslatorOptions.Builder()
            .setSourceLanguage(source)
            .setTargetLanguage(target)
            .build()
        val translator = Translation.getClient(options)

        return suspendCancellableCoroutine { cont ->
            translator.downloadModelIfNeeded()
                .addOnSuccessListener {
                    translator.translate(text)
                        .addOnSuccessListener { translated ->
                            cont.resume(TranslateResult(text = translated))
                            translator.close()
                        }
                        .addOnFailureListener { e ->
                            translator.close()
                            cont.resumeWithException(e)
                        }
                }
                .addOnFailureListener { e ->
                    translator.close()
                    cont.resumeWithException(e)
                }
        }
    }

    override suspend fun translateBatch(texts: List<String>, source: String, target: String): TranslateBatchResult {
        val results = texts.map { text ->
            translate(text, source, target).text
        }
        return TranslateBatchResult(results = results)
    }

    override suspend fun detectLanguage(text: String): DetectLanguageResult {
        val identifier = LanguageIdentification.getClient()

        return suspendCancellableCoroutine { cont ->
            identifier.identifyPossibleLanguages(text)
                .addOnSuccessListener { languages ->
                    val topResult = languages.firstOrNull()
                    cont.resume(
                        DetectLanguageResult(
                            language = topResult?.languageTag ?: "und",
                            confidence = topResult?.confidence?.toDouble() ?: 0.0
                        )
                    )
                    identifier.close()
                }
                .addOnFailureListener { e ->
                    identifier.close()
                    cont.resumeWithException(e)
                }
        }
    }

    override suspend fun getSupportedLanguages(): GetSupportedLanguagesResult {
        return GetSupportedLanguagesResult(
            languages = TranslateLanguage.getAllLanguages()
        )
    }

    override suspend fun downloadModel(language: String): DownloadModelResult {
        val model = TranslateRemoteModel.Builder(language).build()
        val modelManager = RemoteModelManager.getInstance()
        val conditions = DownloadConditions.Builder().build()

        return suspendCancellableCoroutine { cont ->
            modelManager.download(model, conditions)
                .addOnSuccessListener { cont.resume(DownloadModelResult(success = true)) }
                .addOnFailureListener { cont.resume(DownloadModelResult(success = false)) }
        }
    }

    override suspend fun deleteModel(language: String): DeleteModelResult {
        val model = TranslateRemoteModel.Builder(language).build()
        val modelManager = RemoteModelManager.getInstance()

        return suspendCancellableCoroutine { cont ->
            modelManager.deleteDownloadedModel(model)
                .addOnSuccessListener { cont.resume(DeleteModelResult(success = true)) }
                .addOnFailureListener { cont.resume(DeleteModelResult(success = false)) }
        }
    }

    override suspend fun getDownloadedModels(): GetDownloadedModelsResult {
        val modelManager = RemoteModelManager.getInstance()

        return suspendCancellableCoroutine { cont ->
            modelManager.getDownloadedModels(TranslateRemoteModel::class.java)
                .addOnSuccessListener { models ->
                    cont.resume(
                        GetDownloadedModelsResult(
                            models = models.map { it.language }
                        )
                    )
                }
                .addOnFailureListener { e ->
                    cont.resumeWithException(e)
                }
        }
    }
}
