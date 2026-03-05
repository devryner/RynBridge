---
sidebar_position: 9
---

# Media Module API

`@rynbridge/media` — Audio playback, recording, and media picker.

## Setup

```typescript
import { MediaModule } from '@rynbridge/media';

const media = new MediaModule(bridge);
```

## Methods

### `playAudio(payload): Promise<PlayAudioResult>`

Starts audio playback and returns a player ID.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source` | `string` | Yes | Audio URL or file path |
| `loop` | `boolean` | No | Loop playback (default: false) |
| `volume` | `number` | No | Volume 0.0–1.0 (default: 1.0) |

```typescript
const { playerId } = await media.playAudio({ source: 'https://example.com/song.mp3', volume: 0.8 });
```

### `pauseAudio(payload): Promise<void>`

Pauses a playing audio instance.

```typescript
await media.pauseAudio({ playerId });
```

### `stopAudio(payload): Promise<void>`

Stops and releases an audio instance.

```typescript
await media.stopAudio({ playerId });
```

### `getAudioStatus(payload): Promise<AudioStatus>`

Returns the current playback status.

```typescript
const status = await media.getAudioStatus({ playerId });
// { position: 30.5, duration: 180.0, isPlaying: true }
```

### `startRecording(payload?): Promise<StartRecordingResult>`

Starts audio recording.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `format` | `'wav' \| 'mp3' \| 'm4a' \| 'aac'` | No | Audio format |
| `quality` | `'low' \| 'medium' \| 'high'` | No | Recording quality |

```typescript
const { recordingId } = await media.startRecording({ format: 'm4a', quality: 'high' });
```

### `stopRecording(payload): Promise<StopRecordingResult>`

Stops recording and returns the recorded file info.

```typescript
const result = await media.stopRecording({ recordingId });
// { filePath: '/path/to/recording.m4a', duration: 65.3, size: 1048576 }
```

### `pickMedia(payload?): Promise<PickMediaResult>`

Opens the native media picker.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `type` | `'image' \| 'video' \| 'any'` | No | Media type filter |
| `multiple` | `boolean` | No | Allow multiple selection |

```typescript
const { files } = await media.pickMedia({ type: 'image', multiple: true });
files.forEach((f) => console.log(f.name, f.mimeType, f.size));
```

### `onPlaybackComplete(listener): () => void`

Subscribes to playback completion events. Returns an unsubscribe function.

```typescript
const unsub = media.onPlaybackComplete(({ playerId }) => {
  console.log('Playback finished:', playerId);
});
```

## Types

```typescript
interface PlayAudioPayload { source: string; loop?: boolean; volume?: number }
interface PlayAudioResult { playerId: string }
interface PlayerPayload { playerId: string }
interface AudioStatus { position: number; duration: number; isPlaying: boolean }
interface StartRecordingPayload { format?: 'wav' | 'mp3' | 'm4a' | 'aac'; quality?: 'low' | 'medium' | 'high' }
interface StartRecordingResult { recordingId: string }
interface StopRecordingPayload { recordingId: string }
interface StopRecordingResult { filePath: string; duration: number; size: number }
interface PickMediaPayload { type?: 'image' | 'video' | 'any'; multiple?: boolean }
interface MediaFile { name: string; path: string; mimeType: string; size: number }
interface PickMediaResult { files: MediaFile[] }
interface PlaybackCompleteEvent { playerId: string }
```

## Native Provider

| Platform | Protocol/Interface | Key Methods |
|----------|-------------------|-------------|
| iOS | `MediaProvider` | `playAudio`, `pauseAudio`, `stopAudio`, `getAudioStatus`, `startRecording`, `stopRecording`, `pickMedia` |
| Android | `MediaProvider` | Same as iOS |
