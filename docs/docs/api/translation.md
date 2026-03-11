---
sidebar_position: 19
---

# Translation Module API

`@rynbridge/translation` — On-device text translation and language detection.

## Setup

```typescript
import { TranslationModule } from '@rynbridge/translation';

const translation = new TranslationModule(bridge);
```

## Methods

### `translate(payload): Promise<TranslationResult>`

Translates text from source to target language.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | `string` | Yes | Text to translate |
| `sourceLanguage` | `string` | Yes | Source language code (e.g., `'en'`) |
| `targetLanguage` | `string` | Yes | Target language code (e.g., `'ko'`) |

```typescript
const result = await translation.translate({
  text: 'Hello, world!',
  sourceLanguage: 'en',
  targetLanguage: 'ko',
});
// { translatedText: '안녕, 세상아!' }
```

### `detectLanguage(payload): Promise<DetectionResult>`

Detects the language of the given text.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | `string` | Yes | Text to analyze |

```typescript
const result = await translation.detectLanguage({ text: '안녕하세요' });
// { languageCode: 'ko', confidence: 0.98 }
```

### `getSupportedLanguages(): Promise<LanguageList>`

Returns the list of supported language codes.

```typescript
const { languages } = await translation.getSupportedLanguages();
// ['en', 'ko', 'ja', 'zh', ...]
```

### `downloadModel(payload): Promise<void>`

Downloads an offline translation model.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `languageCode` | `string` | Yes | Language code to download |

```typescript
await translation.downloadModel({ languageCode: 'ko' });
```

### `deleteModel(payload): Promise<void>`

Deletes a downloaded offline translation model.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `languageCode` | `string` | Yes | Language code to delete |

```typescript
await translation.deleteModel({ languageCode: 'ko' });
```

## Types

```typescript
interface TranslatePayload {
  text: string;
  sourceLanguage: string;
  targetLanguage: string;
}

interface TranslationResult {
  translatedText: string;
}

interface DetectLanguagePayload {
  text: string;
}

interface DetectionResult {
  languageCode: string;
  confidence: number;
}

interface LanguageList {
  languages: string[];
}
```

## Native Provider

| Platform | Protocol/Interface | Default Provider |
|----------|-------------------|-----------------|
| iOS | `TranslationProvider` | `DefaultTranslationProvider` (Apple Translation) |
| Android | `TranslationProvider` | `DefaultTranslationProvider` (ML Kit Translate) |
