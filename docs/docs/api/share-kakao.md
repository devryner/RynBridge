---
sidebar_position: 24
---

# Share Kakao Module API

`@rynbridge/share-kakao` — KakaoTalk sharing with Feed, Commerce, List, and Custom templates.

This is a **platform-specific** module for sharing content via KakaoTalk using the Kakao SDK.

## Setup

### iOS (Package.swift)

```swift
.product(name: "RynBridgeShareKakao", package: "RynBridge")
```

### Android (build.gradle.kts)

```kotlin
implementation(project(":share-kakao"))
```

## Native Registration

### iOS

```swift
import RynBridgeShareKakao

let shareKakao = KakaoShareModule(provider: DefaultKakaoShareProvider())
bridge.register(shareKakao)
```

### Android

```kotlin
import io.rynbridge.share.kakao.KakaoShareModule
import io.rynbridge.share.kakao.DefaultKakaoShareProvider

val shareKakao = KakaoShareModule(DefaultKakaoShareProvider(context))
bridge.register(shareKakao)
```

## Methods

### `isAvailable(): Promise<AvailabilityResult>`

Checks whether KakaoTalk is installed.

```typescript
const { available } = await bridge.call('share-kakao', 'isAvailable', {});
```

### `shareFeed(payload): Promise<ShareResult>`

Shares a Feed template via KakaoTalk.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `content` | `Content` | Yes | Main content (title, imageUrl, link) |
| `social` | `Social` | No | Social counts (likes, comments, shares) |
| `buttons` | `Button[]` | No | Custom buttons |

```typescript
await bridge.call('share-kakao', 'shareFeed', {
  content: {
    title: 'Check this out!',
    imageUrl: 'https://example.com/image.jpg',
    link: { webUrl: 'https://example.com' },
  },
  buttons: [
    { title: 'Open', link: { webUrl: 'https://example.com' } },
  ],
});
```

### `shareCommerce(payload): Promise<ShareResult>`

Shares a Commerce template via KakaoTalk.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `content` | `Content` | Yes | Product content |
| `commerce` | `Commerce` | Yes | Price info |
| `buttons` | `Button[]` | No | Custom buttons |

### `shareList(payload): Promise<ShareResult>`

Shares a List template via KakaoTalk.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `headerTitle` | `string` | Yes | List header |
| `headerLink` | `Link` | Yes | Header link |
| `contents` | `Content[]` | Yes | List items |
| `buttons` | `Button[]` | No | Custom buttons |

### `shareCustom(payload): Promise<ShareResult>`

Shares a custom template registered in Kakao Developer console.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `templateId` | `number` | Yes | Template ID |
| `templateArgs` | `Record<string, string>` | No | Template arguments |

```typescript
await bridge.call('share-kakao', 'shareCustom', {
  templateId: 12345,
  templateArgs: { title: 'My Title', description: 'My Description' },
});
```

## Types

```typescript
interface Content {
  title: string;
  imageUrl: string;
  link: Link;
  description?: string;
  imageWidth?: number;
  imageHeight?: number;
}

interface Link {
  webUrl?: string;
  mobileWebUrl?: string;
  androidExecutionParams?: Record<string, string>;
  iosExecutionParams?: Record<string, string>;
}

interface Social {
  likeCount?: number;
  commentCount?: number;
  sharedCount?: number;
  viewCount?: number;
  subscriberCount?: number;
}

interface Commerce {
  regularPrice: number;
  discountPrice?: number;
  discountRate?: number;
  fixedDiscountPrice?: number;
  productName?: string;
  currencyUnit?: string;
  currencyUnitPosition?: number;
}

interface Button {
  title: string;
  link: Link;
}

interface ShareResult {
  success: boolean;
}

interface AvailabilityResult {
  available: boolean;
}
```

## Native Provider

| Platform | Protocol/Interface | Default Provider |
|----------|-------------------|-----------------|
| iOS | `KakaoShareProvider` | `DefaultKakaoShareProvider` (Kakao iOS SDK) |
| Android | `KakaoShareProvider` | `DefaultKakaoShareProvider` (Kakao Android SDK) |
