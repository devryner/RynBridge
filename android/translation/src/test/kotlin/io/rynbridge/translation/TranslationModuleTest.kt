package io.rynbridge.translation

import io.rynbridge.core.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

class TranslationModuleTest {

    @Test
    fun `translate returns translated text`() = runTest {
        val provider = MockTranslationProvider()
        val module = TranslationModule(provider)
        val handler = module.actions["translate"]!!

        val result = handler(mapOf(
            "text" to BridgeValue.string("Hello"),
            "source" to BridgeValue.string("en"),
            "target" to BridgeValue.string("ko")
        ))
        assertEquals("Translated: Hello", result["text"]?.stringValue)
    }

    @Test
    fun `translateBatch returns translated texts`() = runTest {
        val provider = MockTranslationProvider()
        val module = TranslationModule(provider)
        val handler = module.actions["translateBatch"]!!

        val result = handler(mapOf(
            "texts" to BridgeValue.array(listOf(BridgeValue.string("Hello"), BridgeValue.string("World"))),
            "source" to BridgeValue.string("en"),
            "target" to BridgeValue.string("ko")
        ))
        val results = result["results"]?.arrayValue
        assertNotNull(results)
        assertEquals(2, results!!.size)
        assertEquals("Translated: Hello", results[0].stringValue)
        assertEquals("Translated: World", results[1].stringValue)
    }

    @Test
    fun `detectLanguage returns language and confidence`() = runTest {
        val provider = MockTranslationProvider()
        val module = TranslationModule(provider)
        val handler = module.actions["detectLanguage"]!!

        val result = handler(mapOf("text" to BridgeValue.string("Hello")))
        assertEquals("en", result["language"]?.stringValue)
        assertEquals(0.95, result["confidence"]?.doubleValue)
    }

    @Test
    fun `getSupportedLanguages returns language list`() = runTest {
        val provider = MockTranslationProvider()
        val module = TranslationModule(provider)
        val handler = module.actions["getSupportedLanguages"]!!

        val result = handler(emptyMap())
        val languages = result["languages"]?.arrayValue
        assertNotNull(languages)
        assertEquals(3, languages!!.size)
        assertEquals("en", languages[0].stringValue)
    }

    @Test
    fun `downloadModel returns success`() = runTest {
        val provider = MockTranslationProvider()
        val module = TranslationModule(provider)
        val handler = module.actions["downloadModel"]!!

        val result = handler(mapOf("language" to BridgeValue.string("ko")))
        assertEquals(true, result["success"]?.boolValue)
    }

    @Test
    fun `deleteModel returns success`() = runTest {
        val provider = MockTranslationProvider()
        val module = TranslationModule(provider)
        val handler = module.actions["deleteModel"]!!

        val result = handler(mapOf("language" to BridgeValue.string("ko")))
        assertEquals(true, result["success"]?.boolValue)
    }

    @Test
    fun `getDownloadedModels returns model list`() = runTest {
        val provider = MockTranslationProvider()
        val module = TranslationModule(provider)
        val handler = module.actions["getDownloadedModels"]!!

        val result = handler(emptyMap())
        val models = result["models"]?.arrayValue
        assertNotNull(models)
        assertEquals(2, models!!.size)
        assertEquals("en", models[0].stringValue)
        assertEquals("ko", models[1].stringValue)
    }

    @Test
    fun `module name and version`() {
        val provider = MockTranslationProvider()
        val module = TranslationModule(provider)
        assertEquals("translation", module.name)
        assertEquals("0.1.0", module.version)
    }
}

private class MockTranslationProvider : TranslationProvider {
    override suspend fun translate(text: String, source: String, target: String): TranslateResult =
        TranslateResult(text = "Translated: $text")

    override suspend fun translateBatch(texts: List<String>, source: String, target: String): TranslateBatchResult =
        TranslateBatchResult(results = texts.map { "Translated: $it" })

    override suspend fun detectLanguage(text: String): DetectLanguageResult =
        DetectLanguageResult(language = "en", confidence = 0.95)

    override suspend fun getSupportedLanguages(): GetSupportedLanguagesResult =
        GetSupportedLanguagesResult(languages = listOf("en", "ko", "ja"))

    override suspend fun downloadModel(language: String): DownloadModelResult =
        DownloadModelResult(success = true)

    override suspend fun deleteModel(language: String): DeleteModelResult =
        DeleteModelResult(success = true)

    override suspend fun getDownloadedModels(): GetDownloadedModelsResult =
        GetDownloadedModelsResult(models = listOf("en", "ko"))
}
