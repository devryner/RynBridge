---
sidebar_position: 17
---

# Speech Module API

`@rynbridge/speech` — Text-to-speech and speech recognition.

## Setup

```typescript
import { SpeechModule } from '@rynbridge/speech';

const speech = new SpeechModule(bridge);
```

## Methods

### `speak(payload): Promise<void>`

Speaks the given text aloud using the device text-to-speech engine.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | `string` | Yes | Text to speak |
| `language` | `string` | No | BCP 47 language tag (e.g., `'en-US'`) |
| `rate` | `number` | No | Speech rate (0.0 - 1.0) |
| `pitch` | `number` | No | Voice pitch (0.0 - 2.0) |

```typescript
await speech.speak({ text: 'Hello from RynBridge!', language: 'en-US', rate: 0.5, pitch: 1.0 });
```

### `stopSpeaking(): Promise<void>`

Stops any currently active text-to-speech playback.

```typescript
await speech.stopSpeaking();
```

### `startRecognition(payload): Promise<RecognitionResult>`

Starts speech recognition and returns the recognized text.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `language` | `string` | No | BCP 47 language tag (e.g., `'en-US'`) |
| `continuous` | `boolean` | No | Whether to keep recognizing after the first result |

```typescript
const result = await speech.startRecognition({ language: 'en-US', continuous: false });
// { text: 'Hello world', isFinal: true, confidence: 0.95 }
```

### `stopRecognition(): Promise<void>`

Stops an active speech recognition session.

```typescript
await speech.stopRecognition();
```

### `getSupportedLanguages(): Promise<LanguageList>`

Returns the list of languages supported by the device for speech recognition and synthesis.

```typescript
const { languages } = await speech.getSupportedLanguages();
// { languages: ['en-US', 'ko-KR', 'ja-JP', 'zh-CN', ...] }
```

### `onRecognitionResult(listener): () => void`

Subscribes to real-time speech recognition results during a continuous session. Returns an unsubscribe function.

```typescript
const unsubscribe = speech.onRecognitionResult((event) => {
  console.log(`Heard: "${event.text}" (final: ${event.isFinal}, confidence: ${event.confidence})`);
});

// Start continuous recognition
await speech.startRecognition({ continuous: true });

// Later: stop listening
unsubscribe();
```

## Types

```typescript
interface SpeakPayload {
  text: string;
  language?: string;
  rate?: number;
  pitch?: number;
}

interface StartRecognitionPayload {
  language?: string;
  continuous?: boolean;
}

interface RecognitionResult {
  text: string;
  isFinal: boolean;
  confidence: number;
}

interface LanguageList {
  languages: string[];
}

interface RecognitionEvent {
  text: string;
  isFinal: boolean;
  confidence: number;
}
```

## Native Provider

| Platform | Protocol/Interface | Key Methods |
|----------|-------------------|-------------|
| iOS | `SpeechProvider` | `speak`, `stopSpeaking`, `startRecognition`, `stopRecognition`, `getSupportedLanguages` |
| Android | `SpeechProvider` | Same as iOS |
