# RynBridge 프로젝트 계획서

## 1. 프로젝트 개요

### 1.1 프로젝트명
**RynBridge** — Web ↔ Native 경량 브릿지 프레임워크

### 1.2 목적
WebView 기반 하이브리드 앱에서 Web과 Native(iOS/Android) 간의 통신 인터페이스를 표준화하고, 모듈 단위로 필요한 기능만 선택적으로 사용할 수 있는 경량 오픈소스 라이브러리를 제공한다.

### 1.3 핵심 가치
- **경량화**: 코어는 최소한으로, 기능은 플러그인 모듈로 분리
- **타입 안전**: TypeScript, Swift, Kotlin 전 플랫폼에서 타입 안전한 통신
- **일관성**: 플랫폼에 관계없이 동일한 API 인터페이스
- **개발자 경험**: 쉬운 설정, 명확한 문서, 디버깅 도구 제공

### 1.4 라이선스
MIT License

---

## 2. 배포 채널

| 플랫폼 | 패키지 매니저 | 패키지명 |
|--------|-------------|---------|
| Web | npm | `@rynbridge/core`, `@rynbridge/<module>` |
| iOS | Swift Package Manager | `RynBridge`, `RynBridge<Module>` |
| Android | Gradle (Maven Central) | `io.rynbridge:core`, `io.rynbridge:<module>` |

---

## 3. 아키텍처

### 3.1 전체 구조

```
┌─────────────────────────────────────────────┐
│                  Web (JS/TS)                │
│                                             │
│  @rynbridge/core    @rynbridge/device  ...  │
│        │                   │                │
│        └───────┬───────────┘                │
│                ▼                            │
│        Message Serializer                   │
│                │                            │
└────────────────┼────────────────────────────┘
                 │  JSON (WebView Bridge)
┌────────────────┼────────────────────────────┐
│                ▼                            │
│        Message Deserializer                 │
│                │                            │
│        ┌───────┴───────────┐                │
│        │                   │                │
│  RynBridgeCore    RynBridgeDevice     ...   │
│                                             │
│              Native (iOS / Android)         │
└─────────────────────────────────────────────┘
```

### 3.2 코어 레이어 (`core`)
브릿지 통신의 기반이 되는 최소 기능만 포함한다.

- 메시지 직렬화 / 역직렬화 (JSON)
- 요청-응답 매핑 (콜백 ID 관리)
- Promise 기반 양방향 통신
- 이벤트 구독/발행 (Native → Web 스트림)
- 버전 협상 (Version Negotiation)
- 에러 핸들링 및 타임아웃

### 3.3 메시지 프로토콜

```json
{
  "id": "uuid-v4",
  "module": "device",
  "action": "getCamera",
  "payload": { "quality": "high" },
  "version": "1.0.0"
}
```

```json
{
  "id": "uuid-v4",
  "status": "success",
  "payload": { "imageData": "base64..." },
  "error": null
}
```

### 3.4 통신 방식

| 패턴 | 방향 | 설명 |
|------|------|------|
| Request-Response | Web → Native | Promise 반환, Native에서 resolve/reject |
| Event Stream | Native → Web | 지속적 이벤트 구독 (위치, 배터리 등) |
| Batch Call | Web → Native | 여러 호출을 하나로 묶어 성능 최적화 |
| Fire-and-Forget | 양방향 | 응답이 필요 없는 단방향 알림 |

---

## 4. 모듈 카테고리

각 모듈은 독립적으로 설치 가능하며, `core`만 필수 의존성이다.

### Phase 1 — 핵심 모듈

| 모듈 | npm | SPM | Gradle | 설명 |
|------|-----|-----|--------|------|
| **core** | `@rynbridge/core` | `RynBridge` | `io.rynbridge:core` | 메시지 통신, 직렬화, 콜백 관리 |
| **device** | `@rynbridge/device` | `RynBridgeDevice` | `io.rynbridge:device` | 카메라, GPS, 생체인증, 진동, 센서 |
| **storage** | `@rynbridge/storage` | `RynBridgeStorage` | `io.rynbridge:storage` | SharedPreferences, UserDefaults, 파일시스템 |
| **secure-storage** | `@rynbridge/secure-storage` | `RynBridgeSecureStorage` | `io.rynbridge:secure-storage` | KeyChain/KeyStore, 암호화된 민감 데이터 저장 |
| **ui** | `@rynbridge/ui` | `RynBridgeUI` | `io.rynbridge:ui` | 네이티브 다이얼로그, 토스트, 상태바, 키보드 |

### Phase 2 — 확장 모듈

| 모듈 | npm | SPM | Gradle | 설명 |
|------|-----|-----|--------|------|
| **auth** | `@rynbridge/auth` | `RynBridgeAuth` | `io.rynbridge:auth` | OAuth, 소셜 로그인, 토큰 관리 |
| **push** | `@rynbridge/push` | `RynBridgePush` | `io.rynbridge:push` | FCM/APNs 등록, 수신 처리 |
| **payment** | `@rynbridge/payment` | `RynBridgePayment` | `io.rynbridge:payment` | 인앱결제, PG 연동 |
| **media** | `@rynbridge/media` | `RynBridgeMedia` | `io.rynbridge:media` | 오디오/비디오 재생, 녹음 |
| **crypto** | `@rynbridge/crypto` | `RynBridgeCrypto` | `io.rynbridge:crypto` | 종단간 암호화(E2EE), 키 교환, 메시지 암복호화 |

#### auth 모듈 상세

OAuth 및 소셜 로그인, 토큰 관리를 통합 인터페이스로 제공한다. 구체적인 인증 서비스는 하위 패키지로 분리한다.

| 액션 | 패턴 | 설명 |
|------|------|------|
| `login` | Request-Response | 소셜/OAuth 로그인 수행, 토큰 및 사용자 정보 반환 |
| `logout` | Request-Response | 로그아웃 처리, 토큰 폐기 |
| `getToken` | Request-Response | 현재 저장된 인증 토큰 조회 |
| `refreshToken` | Request-Response | 토큰 갱신 |
| `getUser` | Request-Response | 현재 로그인 사용자 정보 조회 |

**하위 패키지 구조**

| 패키지 | 설명 |
|--------|------|
| `@rynbridge/auth` | 인터페이스만 (Provider protocol/interface) |
| `@rynbridge/auth-google` | Google Sign-In Provider |
| `@rynbridge/auth-apple` | Apple Sign-In Provider |
| `@rynbridge/auth-kakao` | Kakao Login Provider |

**타입**

```typescript
interface LoginResult { token: string; refreshToken: string | null; expiresAt: string | null; user: AuthUser | null }
interface AuthUser { id: string; email: string | null; name: string | null }
interface TokenResult { token: string | null; expiresAt: string | null }
```

```typescript
const auth = new AuthModule(bridge);

const { token, user } = await auth.login({ provider: 'google', scopes: ['email', 'profile'] });
const { token: currentToken } = await auth.getToken();
const refreshed = await auth.refreshToken();
const user = await auth.getUser();
await auth.logout();
```

#### push 모듈 상세

FCM/APNs 기반 푸시 알림 등록, 권한 관리, 알림 수신/탭 이벤트를 처리한다. 구체적인 푸시 서비스는 하위 패키지로 분리한다.

| 액션 | 패턴 | 설명 |
|------|------|------|
| `register` | Request-Response | 디바이스 푸시 알림 등록, 토큰 및 플랫폼 반환 |
| `unregister` | Request-Response | 푸시 알림 등록 해제 |
| `getToken` | Request-Response | 현재 푸시 토큰 조회 (미등록 시 null) |
| `requestPermission` | Request-Response | 알림 권한 요청 |
| `getPermissionStatus` | Request-Response | 현재 알림 권한 상태 조회 |
| `getInitialNotification` | Request-Response | 앱 콜드 스타트 시 진입 원인 알림 조회 (푸시 탭으로 앱 실행 시) |
| `onNotification` | Event Stream | 푸시 알림 수신 이벤트 구독 |
| `onTokenRefresh` | Event Stream | 푸시 토큰 갱신 이벤트 구독 |
| `onNotificationOpened` | Event Stream | 백그라운드 상태에서 푸시 탭 이벤트 구독 |

**하위 패키지 구조**

| 패키지 | 설명 |
|--------|------|
| `@rynbridge/push` | 인터페이스만 (Provider protocol/interface) |
| `@rynbridge/push-fcm` | Firebase Cloud Messaging Provider |
| `@rynbridge/push-apns` | Apple Push Notification Service Provider |

**타입**

```typescript
interface PushRegistration { token: string; platform: string }
interface PushToken { token: string | null }
interface PushPermission { granted: boolean }
interface PushPermissionStatus { status: 'granted' | 'denied' | 'notDetermined' }
interface PushNotification { title: string | null; body: string | null; data: Record<string, unknown> | null }
interface PushTokenRefresh { token: string }
interface PushNotificationOpened { title: string | null; body: string | null; data: Record<string, unknown> | null }
```

**푸시 진입 시나리오**

| 시나리오 | 메서드 | 설명 |
|----------|--------|------|
| 콜드 스타트 (앱 종료 → 푸시 탭) | `getInitialNotification()` | 앱 시작 직후 호출하여 진입 원인 알림 확인 |
| 백그라운드 → 포그라운드 (푸시 탭) | `onNotificationOpened()` | 실시간 이벤트로 알림 탭 감지 |
| 포그라운드 수신 | `onNotification()` | 앱 사용 중 푸시 수신 감지 |

```typescript
const push = new PushModule(bridge);

const { granted } = await push.requestPermission();
const { token, platform } = await push.register();

// 콜드 스타트 진입 확인
const initial = await push.getInitialNotification();
if (initial) {
  console.log('Opened from push:', initial.data);
}

// 포그라운드 수신
push.onNotification((notification) => {
  console.log(notification.title, notification.body, notification.data);
});

// 백그라운드 → 포그라운드 탭
push.onNotificationOpened((notification) => {
  console.log('Tapped:', notification.title, notification.data);
});

// 토큰 갱신 감지
push.onTokenRefresh(({ token }) => {
  sendTokenToServer(token);
});
```

#### payment 모듈 상세

인앱결제(In-App Purchase)를 통합 인터페이스로 제공한다. 구체적인 스토어 구현은 하위 패키지로 분리한다.

| 액션 | 패턴 | 설명 |
|------|------|------|
| `getProducts` | Request-Response | 상품 목록 조회 (가격, 제목, 설명 등) |
| `purchase` | Request-Response | 상품 구매 요청, 트랜잭션 정보 반환 |
| `restorePurchases` | Request-Response | 이전 구매 복원 |
| `finishTransaction` | Request-Response | 트랜잭션 완료 처리 (서버 검증 후) |

**하위 패키지 구조**

| 패키지 | 설명 |
|--------|------|
| `@rynbridge/payment` | 인터페이스만 (Provider protocol/interface) |
| `@rynbridge/payment-storekit` | Apple StoreKit 2 Provider |
| `@rynbridge/payment-google-play` | Google Play Billing Provider |

**타입**

```typescript
interface Product { id: string; title: string; description: string; price: string; currency: string }
interface PurchaseResult { transactionId: string; productId: string; receipt: string }
interface Transaction { transactionId: string; productId: string; purchaseDate: string; receipt: string }
```

```typescript
const payment = new PaymentModule(bridge);

const { products } = await payment.getProducts({ productIds: ['premium_monthly', 'premium_yearly'] });
const { transactionId, receipt } = await payment.purchase({ productId: 'premium_monthly', quantity: 1 });
// 서버에서 영수증 검증 후 트랜잭션 완료
await payment.finishTransaction({ transactionId });
const { transactions } = await payment.restorePurchases();
```

#### media 모듈 상세

오디오/비디오 재생, 녹음, 미디어 파일 선택을 통합 인터페이스로 제공한다.

| 액션 | 패턴 | 설명 |
|------|------|------|
| `playAudio` | Request-Response | 오디오 재생 시작, playerId 반환 |
| `pauseAudio` | Request-Response | 오디오 일시 정지 |
| `stopAudio` | Request-Response | 오디오 정지 |
| `getAudioStatus` | Request-Response | 오디오 재생 상태 조회 (위치, 길이, 재생 여부) |
| `startRecording` | Request-Response | 녹음 시작, recordingId 반환 |
| `stopRecording` | Request-Response | 녹음 중지, 파일 경로/길이/크기 반환 |
| `pickMedia` | Request-Response | 네이티브 미디어 선택 UI 표시, 선택한 파일 정보 반환 |

**플랫폼 매핑**

| 기능 | iOS | Android |
|------|-----|---------|
| 오디오 재생 | AVAudioPlayer | MediaPlayer |
| 녹음 | AVAudioRecorder | MediaRecorder |
| 미디어 선택 | PHPickerViewController | MediaStore / Intent |
| 권한 | NSMicrophoneUsageDescription, NSPhotoLibraryUsageDescription | `android.permission.RECORD_AUDIO`, `READ_MEDIA_*` |

**타입**

```typescript
interface AudioStatus { position: number; duration: number; isPlaying: boolean }
interface RecordingResult { filePath: string; duration: number; size: number }
interface MediaFile { name: string; path: string; mimeType: string; size: number }
```

```typescript
const media = new MediaModule(bridge);

// 오디오 재생
const { playerId } = await media.playAudio({ source: 'https://example.com/song.mp3', loop: false, volume: 0.8 });
const { position, duration, isPlaying } = await media.getAudioStatus({ playerId });
await media.pauseAudio({ playerId });
await media.stopAudio({ playerId });

// 녹음
const { recordingId } = await media.startRecording({ format: 'm4a', quality: 'high' });
const { filePath, duration, size } = await media.stopRecording({ recordingId });

// 미디어 선택
const { files } = await media.pickMedia({ type: 'image', multiple: true });
```

#### crypto 모듈 상세

Web ↔ Native 간 브릿지 메시지를 종단간 암호화하여 전송 경로에서의 도청/변조를 방지한다.

| 기능 | 설명 |
|------|------|
| 키 교환 | ECDH (Curve25519) 기반 핸드셰이크로 세션 키 생성 |
| 메시지 암호화 | AES-256-GCM 대칭 암호화 |
| 키 저장 | iOS KeyChain / Android KeyStore / Web CryptoKey 활용 |
| 키 로테이션 | 설정 주기 또는 세션 단위 자동 키 갱신 |
| 무결성 검증 | HMAC 기반 메시지 변조 탐지 |
| 선택적 암호화 | 모듈/액션 단위로 암호화 대상 지정 가능 |

```typescript
// Web 사용 예시
import { RynBridge } from '@rynbridge/core';
import { CryptoModule } from '@rynbridge/crypto';

const bridge = new RynBridge();
bridge.use(CryptoModule({ rotationInterval: 3600 }));

// 암호화가 적용된 통신 — 기존 API와 동일하게 사용
const result = await bridge.call('payment', 'checkout', {
  amount: 29900,
  cardToken: 'tok_xxx',
});
```

```swift
// iOS 사용 예시
import RynBridge
import RynBridgeCrypto

let bridge = RynBridge(webView: wkWebView)
bridge.use(CryptoModule(rotationInterval: 3600))
```

```kotlin
// Android 사용 예시
import io.rynbridge.core.RynBridge
import io.rynbridge.crypto.CryptoModule

val bridge = RynBridge(webView)
bridge.use(CryptoModule(rotationInterval = 3600))
```

### Phase 3 — 고급 모듈

| 모듈 | npm | SPM | Gradle | 설명 |
|------|-----|-----|--------|------|
| **analytics** | `@rynbridge/analytics` | `RynBridgeAnalytics` | `io.rynbridge:analytics` | 이벤트 트래킹, 크래시 리포트 연동 |
| **navigation** | `@rynbridge/navigation` | `RynBridgeNavigation` | `io.rynbridge:navigation` | 네이티브 화면 전환, 딥링크 |
| **share** | `@rynbridge/share` | `RynBridgeShare` | `io.rynbridge:share` | 네이티브 공유 시트, 클립보드 |
| **health** | `@rynbridge/health` | `RynBridgeHealth` | `io.rynbridge:health` | HealthKit/Health Connect 연동, 건강 데이터 조회/기록 |
| **bluetooth** | `@rynbridge/bluetooth` | `RynBridgeBluetooth` | `io.rynbridge:bluetooth` | BLE 기기 스캔, 연결, 데이터 교환 |
| **contacts** | `@rynbridge/contacts` | `RynBridgeContacts` | `io.rynbridge:contacts` | 연락처 조회/생성/수정 |
| **calendar** | `@rynbridge/calendar` | `RynBridgeCalendar` | `io.rynbridge:calendar` | 일정/리마인더 조회/생성 |
| **speech** | `@rynbridge/speech` | `RynBridgeSpeech` | `io.rynbridge:speech` | 음성인식(STT), 음성합성(TTS) |
| **background-task** | `@rynbridge/background-task` | `RynBridgeBackgroundTask` | `io.rynbridge:background-task` | 백그라운드 작업 스케줄링, 오프라인 동기화 |
| **webview** | `@rynbridge/webview` | `RynBridgeWebView` | `io.rynbridge:webview` | 멀티 WebView 관리, WebView 간 메시지 통신 |
| **translation** | `@rynbridge/translation` | `RynBridgeTranslation` | `io.rynbridge:translation` | 텍스트 번역, 언어 감지, 오프라인 모델 관리 |

#### health 모듈 상세

iOS HealthKit과 Android Health Connect를 통합 인터페이스로 제공하여, Web에서 건강 데이터를 읽고 쓸 수 있도록 한다.

| 기능 | 설명 |
|------|------|
| 걸음 수 | 일별/주별/월별 걸음 수 조회 |
| 심박수 | 실시간 및 기록 심박수 조회 |
| 수면 | 수면 단계별 데이터 조회 |
| 운동 | 운동 세션 기록/조회 (칼로리, 거리, 시간) |
| 체성분 | 체중, 체지방률, BMI 기록/조회 |
| 영양 | 식사, 수분 섭취 기록/조회 |
| 권한 관리 | 데이터 타입별 읽기/쓰기 권한 요청 및 상태 확인 |
| 백그라운드 전달 | HealthKit Background Delivery / Health Connect 변경 알림 |

**플랫폼 매핑**

| 기능 | iOS | Android |
|------|-----|---------|
| 프레임워크 | HealthKit | Health Connect (Jetpack) |
| 권한 | NSHealthShareUsageDescription | `android.permission.health.*` |
| 데이터 저장소 | Apple Health | Health Connect |

```typescript
// Web 사용 예시
import { RynBridge } from '@rynbridge/core';
import { Health, HealthDataType } from '@rynbridge/health';

const bridge = new RynBridge();
bridge.use(Health());

// 권한 요청
await Health.requestPermission([
  HealthDataType.STEPS,
  HealthDataType.HEART_RATE,
]);

// 걸음 수 조회
const steps = await Health.read({
  type: HealthDataType.STEPS,
  from: '2026-02-01',
  to: '2026-02-25',
  interval: 'day',
});

// 체중 기록
await Health.write({
  type: HealthDataType.BODY_MASS,
  value: 72.5,
  unit: 'kg',
});

// 실시간 심박수 구독
Health.subscribe(HealthDataType.HEART_RATE, (data) => {
  console.log('Heart rate:', data.value, 'bpm');
});
```

#### share 모듈 상세

네이티브 공유 시트와 클립보드 기능을 Web에서 호출할 수 있도록 한다.

| 액션 | 패턴 | 설명 |
|------|------|------|
| `share` | Request-Response | 네이티브 공유 시트 표시 (텍스트, URL, 이미지 등) |
| `shareFile` | Request-Response | 파일을 네이티브 공유 시트로 공유 |
| `copyToClipboard` | Fire-and-Forget | 텍스트를 클립보드에 복사 |
| `readClipboard` | Request-Response | 클립보드 내용 읽기 |
| `canShare` | Request-Response | 공유 가능 여부 확인 |
| `shareToKakao` | Request-Response | 카카오톡으로 메시지 공유 (하위 패키지) |

**하위 패키지 구조**

| 패키지 | 설명 |
|--------|------|
| `@rynbridge/share` | 네이티브 공유 시트 + 클립보드 (외부 의존성 없음) |
| `@rynbridge/share-kakao` | 카카오톡 공유 Provider (KakaoSDK 의존) |

**플랫폼 매핑**

| 기능 | iOS | Android |
|------|-----|---------|
| 공유 시트 | UIActivityViewController | Intent.ACTION_SEND / ShareSheet |
| 클립보드 | UIPasteboard | ClipboardManager |
| 카카오 공유 | KakaoSDK ShareApi | KakaoSDK ShareClient |

```typescript
const share = new ShareModule(bridge);

// 텍스트 + URL 공유
await share.share({ text: 'Check this out!', url: 'https://example.com' });

// 파일 공유
await share.shareFile({ filePath: '/tmp/photo.jpg', mimeType: 'image/jpeg' });

// 클립보드
share.copyToClipboard({ text: 'Hello' });
const { text } = await share.readClipboard();

// 카카오톡 공유 (@rynbridge/share-kakao)
await share.shareToKakao({
  templateId: 12345,
  templateArgs: { title: '제목', description: '설명' },
});
```

#### contacts 모듈 상세

네이티브 연락처 데이터에 접근하여 조회, 생성, 수정, 삭제를 수행한다.

| 액션 | 패턴 | 설명 |
|------|------|------|
| `getContacts` | Request-Response | 연락처 목록 조회 (페이지네이션, 검색 지원) |
| `getContact` | Request-Response | 단일 연락처 상세 조회 |
| `createContact` | Request-Response | 새 연락처 생성 |
| `updateContact` | Request-Response | 기존 연락처 수정 |
| `deleteContact` | Request-Response | 연락처 삭제 |
| `pickContact` | Request-Response | 네이티브 연락처 선택 UI 표시 |
| `requestPermission` | Request-Response | 연락처 접근 권한 요청 |
| `getPermissionStatus` | Request-Response | 현재 권한 상태 확인 |

**플랫폼 매핑**

| 기능 | iOS | Android |
|------|-----|---------|
| 프레임워크 | Contacts.framework | ContactsContract |
| 권한 | NSContactsUsageDescription | `android.permission.READ/WRITE_CONTACTS` |
| 선택 UI | CNContactPickerViewController | ContactsContract.Intents |

```typescript
const contacts = new ContactsModule(bridge);

await contacts.requestPermission();
const { contacts: list } = await contacts.getContacts({ query: '김', limit: 20 });
const { contact } = await contacts.getContact({ id: list[0].id });
await contacts.createContact({
  givenName: '길동',
  familyName: '홍',
  phoneNumbers: [{ label: 'mobile', number: '010-1234-5678' }],
  emailAddresses: [{ label: 'home', address: 'gildong@example.com' }],
});
```

#### calendar 모듈 상세

네이티브 캘린더의 일정(Event)과 리마인더(Reminder)에 접근한다.

| 액션 | 패턴 | 설명 |
|------|------|------|
| `getCalendars` | Request-Response | 캘린더 목록 조회 |
| `getEvents` | Request-Response | 날짜 범위로 일정 조회 |
| `getEvent` | Request-Response | 단일 일정 상세 조회 |
| `createEvent` | Request-Response | 새 일정 생성 |
| `updateEvent` | Request-Response | 기존 일정 수정 |
| `deleteEvent` | Request-Response | 일정 삭제 |
| `createReminder` | Request-Response | 리마인더 생성 |
| `requestPermission` | Request-Response | 캘린더 접근 권한 요청 |
| `getPermissionStatus` | Request-Response | 현재 권한 상태 확인 |

**플랫폼 매핑**

| 기능 | iOS | Android |
|------|-----|---------|
| 프레임워크 | EventKit (EKEventStore) | CalendarContract |
| 권한 | NSCalendarsUsageDescription | `android.permission.READ/WRITE_CALENDAR` |
| 리마인더 | EKReminder | CalendarContract.Reminders |

```typescript
const calendar = new CalendarModule(bridge);

await calendar.requestPermission();
const { calendars } = await calendar.getCalendars();
const { events } = await calendar.getEvents({
  calendarId: calendars[0].id,
  from: '2026-03-01',
  to: '2026-03-31',
});
await calendar.createEvent({
  title: '팀 미팅',
  startDate: '2026-03-10T14:00:00',
  endDate: '2026-03-10T15:00:00',
  location: '회의실 A',
  notes: '주간 스프린트 리뷰',
});
```

#### navigation 모듈 상세

네이티브 화면 전환(push/pop/present)과 딥링크 처리를 Web에서 제어한다.

| 액션 | 패턴 | 설명 |
|------|------|------|
| `push` | Request-Response | 네이티브 화면 push (스택에 추가) |
| `pop` | Request-Response | 현재 화면 pop (스택에서 제거) |
| `popToRoot` | Request-Response | 루트 화면까지 pop |
| `present` | Request-Response | 모달로 화면 표시 |
| `dismiss` | Request-Response | 모달 닫기 |
| `openURL` | Request-Response | 외부 URL 또는 딥링크 열기 |
| `canOpenURL` | Request-Response | URL 열기 가능 여부 확인 |
| `getInitialURL` | Request-Response | 앱 콜드 스타트 시 진입 원인 딥링크 URL 조회 (딥링크로 앱 실행 시) |
| `onDeepLink` | Event Stream | 딥링크 수신 이벤트 구독 (앱 실행 중) |
| `getAppState` | Request-Response | 현재 앱 상태 조회 (`active`, `inactive`, `background`) |
| `onAppStateChange` | Event Stream | 앱 포그라운드/백그라운드 상태 변경 이벤트 구독 |

**딥링크 진입 시나리오**

| 시나리오 | 메서드 | 설명 |
|----------|--------|------|
| 콜드 스타트 (링크로 앱 실행) | `getInitialURL()` | 앱 시작 직후 호출하여 진입 원인 URL 확인, 없으면 `null` |
| 앱 실행 중 딥링크 수신 | `onDeepLink()` | 실시간 이벤트로 딥링크 감지 |

**플랫폼 매핑**

| 기능 | iOS | Android |
|------|-----|---------|
| 화면 전환 | UINavigationController (push/pop) | Fragment / Activity Intent |
| 모달 | present(_, animated:) | DialogFragment / BottomSheet |
| 딥링크 | UIApplicationDelegate / SceneDelegate | Intent filter / App Links |
| 외부 URL | UIApplication.shared.open() | Intent(Intent.ACTION_VIEW) |
| 앱 상태 | UIApplication Notification (didBecomeActive, didEnterBackground) | ProcessLifecycleOwner / ActivityLifecycleCallbacks |

```typescript
const nav = new NavigationModule(bridge);

await nav.push({ screen: 'settings', params: { section: 'profile' } });
await nav.pop();
await nav.present({ screen: 'login', style: 'fullScreen' });
await nav.openURL({ url: 'https://example.com' });

// 콜드 스타트 딥링크 확인
const initialURL = await nav.getInitialURL();
if (initialURL) {
  console.log('App opened from deep link:', initialURL.url);
}

// 앱 실행 중 딥링크 수신
nav.onDeepLink((event) => {
  console.log('Deep link received:', event.url);
});

// 앱 상태 조회
const { state } = await nav.getAppState(); // 'active' | 'inactive' | 'background'

// 앱 상태 변경 감지
nav.onAppStateChange((event) => {
  console.log('App state:', event.state);
  if (event.state === 'background') {
    saveProgress();
  }
});
```

#### speech 모듈 상세

음성인식(STT)과 음성합성(TTS)을 통합 인터페이스로 제공한다.

| 액션 | 패턴 | 설명 |
|------|------|------|
| `startRecognition` | Request-Response | 음성인식 시작, 세션 ID 반환 |
| `stopRecognition` | Request-Response | 음성인식 중지, 최종 결과 반환 |
| `onRecognitionResult` | Event Stream | 실시간 음성인식 중간 결과 스트림 |
| `speak` | Request-Response | 텍스트를 음성으로 합성하여 재생 |
| `stopSpeaking` | Fire-and-Forget | 음성합성 재생 중지 |
| `getVoices` | Request-Response | 사용 가능한 TTS 음성 목록 조회 |
| `requestPermission` | Request-Response | 마이크 권한 요청 |
| `getPermissionStatus` | Request-Response | 현재 권한 상태 확인 |

**플랫폼 매핑**

| 기능 | iOS | Android |
|------|-----|---------|
| STT | Speech.framework (SFSpeechRecognizer) | SpeechRecognizer |
| TTS | AVSpeechSynthesizer | TextToSpeech |
| 권한 | NSSpeechRecognitionUsageDescription, NSMicrophoneUsageDescription | `android.permission.RECORD_AUDIO` |

```typescript
const speech = new SpeechModule(bridge);

await speech.requestPermission();

// 음성인식 (STT)
const { sessionId } = await speech.startRecognition({ language: 'ko-KR' });
speech.onRecognitionResult((result) => {
  console.log(result.transcript, result.isFinal);
});
const { transcript } = await speech.stopRecognition({ sessionId });

// 음성합성 (TTS)
await speech.speak({ text: '안녕하세요', language: 'ko-KR', rate: 1.0 });
const { voices } = await speech.getVoices();
```

#### analytics 모듈 상세

이벤트 트래킹과 사용자 속성을 관리하며, 구체적인 analytics 서비스는 하위 패키지로 분리한다.

| 액션 | 패턴 | 설명 |
|------|------|------|
| `logEvent` | Fire-and-Forget | 커스텀 이벤트 로깅 |
| `setUserProperty` | Fire-and-Forget | 사용자 속성 설정 |
| `setUserId` | Fire-and-Forget | 사용자 ID 설정 |
| `setScreen` | Fire-and-Forget | 현재 화면 이름 설정 |
| `resetUser` | Fire-and-Forget | 사용자 정보 초기화 |
| `setEnabled` | Request-Response | 트래킹 활성화/비활성화 (GDPR 대응) |
| `isEnabled` | Request-Response | 현재 트래킹 활성화 상태 조회 |

**하위 패키지 구조**

| 패키지 | 설명 |
|--------|------|
| `@rynbridge/analytics` | 인터페이스만 (Provider protocol/interface) |
| `@rynbridge/analytics-firebase` | Firebase Analytics Provider |
| `@rynbridge/analytics-amplitude` | Amplitude Provider |
| `@rynbridge/analytics-mixpanel` | Mixpanel Provider |

```typescript
const analytics = new AnalyticsModule(bridge);

analytics.setUserId({ userId: 'user_123' });
analytics.setUserProperty({ key: 'plan', value: 'premium' });
analytics.setScreen({ name: 'HomeScreen' });
analytics.logEvent({ name: 'purchase_complete', params: { amount: 29900, currency: 'KRW' } });
await analytics.setEnabled({ enabled: false }); // GDPR opt-out
```

#### bluetooth 모듈 상세

BLE(Bluetooth Low Energy) 기기 스캔, 연결, 서비스/특성 탐색, 데이터 읽기/쓰기를 수행한다.

| 액션 | 패턴 | 설명 |
|------|------|------|
| `startScan` | Request-Response | BLE 기기 스캔 시작 |
| `stopScan` | Fire-and-Forget | 스캔 중지 |
| `onDeviceFound` | Event Stream | 스캔 중 발견된 기기 이벤트 |
| `connect` | Request-Response | 기기 연결 |
| `disconnect` | Request-Response | 기기 연결 해제 |
| `getServices` | Request-Response | 연결된 기기의 서비스 목록 조회 |
| `readCharacteristic` | Request-Response | 특성 값 읽기 |
| `writeCharacteristic` | Request-Response | 특성 값 쓰기 |
| `onCharacteristicChange` | Event Stream | 특성 값 변경 알림 구독 |
| `requestPermission` | Request-Response | 블루투스 권한 요청 |
| `getState` | Request-Response | 블루투스 어댑터 상태 확인 (on/off) |
| `onStateChange` | Event Stream | 블루투스 상태 변경 이벤트 |

**플랫폼 매핑**

| 기능 | iOS | Android |
|------|-----|---------|
| 프레임워크 | CoreBluetooth (CBCentralManager) | BluetoothGatt / BluetoothLeScanner |
| 권한 | NSBluetoothAlwaysUsageDescription | `android.permission.BLUETOOTH_SCAN/CONNECT` |
| 백그라운드 | UIBackgroundModes: bluetooth-central | FOREGROUND_SERVICE |

```typescript
const bt = new BluetoothModule(bridge);

await bt.requestPermission();
const { state } = await bt.getState(); // 'poweredOn' | 'poweredOff' | ...

// 스캔
await bt.startScan({ serviceUUIDs: ['180D'] }); // Heart Rate Service
bt.onDeviceFound((device) => {
  console.log(device.name, device.rssi);
});

// 연결 및 데이터 읽기
await bt.connect({ deviceId: 'AA:BB:CC:DD:EE:FF' });
const { services } = await bt.getServices({ deviceId: 'AA:BB:CC:DD:EE:FF' });
const { value } = await bt.readCharacteristic({
  deviceId: 'AA:BB:CC:DD:EE:FF',
  serviceUUID: '180D',
  characteristicUUID: '2A37',
});

// 실시간 알림 구독
bt.onCharacteristicChange((event) => {
  console.log('Heart rate:', event.value);
});
```

#### background-task 모듈 상세

백그라운드 작업 스케줄링과 오프라인 동기화를 관리한다.

| 액션 | 패턴 | 설명 |
|------|------|------|
| `scheduleTask` | Request-Response | 백그라운드 작업 스케줄링 |
| `cancelTask` | Request-Response | 예약된 작업 취소 |
| `cancelAllTasks` | Request-Response | 모든 예약 작업 취소 |
| `getScheduledTasks` | Request-Response | 예약된 작업 목록 조회 |
| `onTaskExecute` | Event Stream | 백그라운드 작업 실행 이벤트 |
| `completeTask` | Fire-and-Forget | 작업 완료 알림 (시스템에 완료 보고) |
| `requestPermission` | Request-Response | 백그라운드 실행 권한 요청 (Android) |

**작업 유형**

| 유형 | 설명 |
|------|------|
| `oneTime` | 1회성 백그라운드 작업 |
| `periodic` | 주기적 반복 작업 (최소 15분 간격) |
| `connectivity` | 네트워크 연결 시 실행 (오프라인 동기화) |

**플랫폼 매핑**

| 기능 | iOS | Android |
|------|-----|---------|
| 프레임워크 | BGTaskScheduler (BGAppRefreshTask, BGProcessingTask) | WorkManager |
| 주기적 작업 | BGAppRefreshTask | PeriodicWorkRequest |
| 조건부 실행 | BGProcessingTask (requiresNetworkConnectivity) | Constraints (NetworkType) |
| 최소 간격 | 시스템 결정 (~15분) | 15분 |

```typescript
const tasks = new BackgroundTaskModule(bridge);

// 주기적 데이터 동기화
await tasks.scheduleTask({
  taskId: 'sync-data',
  type: 'periodic',
  interval: 900, // 15분 (초)
  requiresNetwork: true,
});

// 1회성 작업
await tasks.scheduleTask({
  taskId: 'upload-logs',
  type: 'oneTime',
  delay: 60, // 60초 후
  requiresCharging: true,
});

// 작업 실행 이벤트 수신
tasks.onTaskExecute((event) => {
  console.log('Task executing:', event.taskId);
  // 작업 수행 후 완료 보고
  tasks.completeTask({ taskId: event.taskId, success: true });
});

const { tasks: scheduled } = await tasks.getScheduledTasks();
await tasks.cancelTask({ taskId: 'sync-data' });
```

#### webview 모듈 상세

새로운 WebView를 열고, WebView 간 메시지/이벤트를 주고받으며, 닫힘 이벤트를 수신한다. 보안을 위해 통신에 참여하는 모든 WebView는 webview 모듈이 등록되어 있어야 한다.

| 액션 | 패턴 | 설명 |
|------|------|------|
| `open` | Request-Response | 새 WebView 열기, webviewId 반환 |
| `close` | Request-Response | 특정 WebView 닫기 |
| `sendMessage` | Request-Response | 대상 WebView에 메시지 전달 |
| `postEvent` | Fire-and-Forget | 대상 WebView에 이벤트 발행 |
| `onMessage` | Event Stream | 다른 WebView로부터 메시지 수신 |
| `onClose` | Event Stream | WebView 닫힘 이벤트 수신 (결과 데이터 포함) |
| `getWebViews` | Request-Response | 현재 열려있는 WebView 목록 조회 |
| `setResult` | Fire-and-Forget | 닫히기 전 결과 데이터 설정 |

**보안 모델**

| 규칙 | 설명 |
|------|------|
| 모듈 필수 | 양쪽 WebView 모두 webview 모듈이 등록되어야 통신 가능 |
| Origin 제한 | `allowedOrigins` 옵션으로 통신 가능한 출처를 화이트리스트로 제한 |
| ID 기반 라우팅 | 각 WebView는 고유 `webviewId`를 가지며, 메시지는 ID로 라우팅 |
| 부모-자식 관계 | 자식 WebView는 부모의 `webviewId`를 알고 있음 (`parent` 예약어로 접근 가능) |

**플랫폼 매핑**

| 기능 | iOS | Android |
|------|-----|---------|
| WebView 생성 | WKWebView + UIViewController (present/push) | WebView + Activity/Fragment |
| 메시지 라우팅 | WKWebViewTransport 간 네이티브 브릿지 라우팅 | WebViewTransport 간 네이티브 브릿지 라우팅 |
| 닫기 감지 | viewDidDisappear / dismiss completion | onDestroy / Activity result |
| 표시 스타일 | modal / push (UINavigationController) | Activity launch mode / DialogFragment |

```typescript
// 부모 WebView
const webview = new WebViewModule(bridge);

// 새 WebView 열기
const { webviewId } = await webview.open({
  url: 'https://example.com/child',
  title: 'Child Page',
  style: 'modal', // 'modal' | 'push' | 'fullScreen'
  allowedOrigins: ['https://example.com'],
});

// 자식에게 메시지 전달
await webview.sendMessage({ targetId: webviewId, data: { token: 'abc' } });

// 자식으로부터 메시지 수신
webview.onMessage((event) => {
  console.log(event.sourceId, event.data);
});

// 자식 WebView 닫힘 감지
webview.onClose((event) => {
  console.log('Closed:', event.webviewId, event.result);
});
```

```typescript
// 자식 WebView
const webview = new WebViewModule(bridge);

// 부모로부터 메시지 수신
webview.onMessage((event) => {
  console.log('From parent:', event.data);
});

// 부모에게 메시지 전달
await webview.sendMessage({ targetId: 'parent', data: { selected: 'item_1' } });

// 닫히기 전 결과 설정
webview.setResult({ data: { confirmed: true } });
```

#### translation 모듈 상세

네이티브 번역 API를 활용하여 텍스트 번역, 언어 감지, 오프라인 모델 관리를 수행한다. 구체적인 번역 엔진은 하위 패키지로 분리한다.

| 액션 | 패턴 | 설명 |
|------|------|------|
| `translate` | Request-Response | 텍스트 번역 |
| `translateBatch` | Request-Response | 여러 텍스트 일괄 번역 |
| `detectLanguage` | Request-Response | 텍스트 언어 감지 |
| `getSupportedLanguages` | Request-Response | 지원 언어 목록 조회 |
| `downloadModel` | Request-Response | 오프라인 번역 모델 다운로드 |
| `deleteModel` | Request-Response | 다운로드된 모델 삭제 |
| `getDownloadedModels` | Request-Response | 다운로드된 모델 목록 조회 |
| `onDownloadProgress` | Event Stream | 모델 다운로드 진행률 |

**하위 패키지 구조**

| 패키지 | iOS | Android | 설명 |
|--------|-----|---------|------|
| `@rynbridge/translation` | — | — | 인터페이스만 (Provider protocol/interface) |
| `@rynbridge/translation-apple` | Translation framework (iOS 17.4+) | — | Apple 내장 번역 Provider |
| `@rynbridge/translation-mlkit` | — | ML Kit Translation | Google ML Kit 번역 Provider |

**플랫폼 매핑**

| 기능 | iOS (translation-apple) | Android (translation-mlkit) |
|------|------------------------|---------------------------|
| 번역 엔진 | Translation framework | ML Kit Translation |
| 언어 감지 | NLLanguageRecognizer | ML Kit Language ID |
| 오프라인 | 시스템 자동 모델 관리 | 수동 모델 다운로드/삭제 |
| 지원 언어 | Apple 서버 + 로컬 모델 | ML Kit 지원 언어 (~60개) |

```typescript
const translation = new TranslationModule(bridge);

// 단일 번역
const { text } = await translation.translate({
  text: '안녕하세요',
  source: 'ko',
  target: 'en',
});
// → "Hello"

// 일괄 번역
const { results } = await translation.translateBatch({
  texts: ['안녕하세요', '감사합니다'],
  source: 'ko',
  target: 'ja',
});

// 언어 감지
const { language, confidence } = await translation.detectLanguage({
  text: 'Bonjour le monde',
});
// → { language: 'fr', confidence: 0.98 }

// 오프라인 모델 관리
const { languages } = await translation.getSupportedLanguages();
await translation.downloadModel({ language: 'ja' });
translation.onDownloadProgress((event) => {
  console.log(event.language, event.progress); // 'ja', 0.75
});
const { models } = await translation.getDownloadedModels();
await translation.deleteModel({ language: 'ja' });
```

---

## 5. 사용 예시

### 5.1 Web (TypeScript)

```typescript
import { RynBridge } from '@rynbridge/core';
import { Camera } from '@rynbridge/device';

const bridge = new RynBridge();

// Request-Response
const photo = await Camera.capture({ quality: 'high' });

// Event Stream
Camera.onPermissionChange((status) => {
  console.log('Permission changed:', status);
});
```

### 5.2 iOS (Swift)

```swift
import RynBridge
import RynBridgeDevice

let bridge = RynBridge(webView: wkWebView)

bridge.register(DeviceModule()) // device 모듈 등록

// 커스텀 핸들러 등록
bridge.on("myAction") { (params: MyParams) -> MyResponse in
    return MyResponse(result: "done")
}
```

### 5.3 Android (Kotlin)

```kotlin
import io.rynbridge.core.RynBridge
import io.rynbridge.device.DeviceModule

val bridge = RynBridge(webView)

bridge.register(DeviceModule()) // device 모듈 등록

// 커스텀 핸들러 등록
bridge.on<MyParams, MyResponse>("myAction") { params ->
    MyResponse(result = "done")
}
```

---

## 6. 개발자 도구

### 6.1 CLI (`rynbridge-cli`)
```bash
npx rynbridge init          # 프로젝트 스캐폴딩
npx rynbridge add device    # 모듈 추가
npx rynbridge generate      # 타입 정의 → Swift/Kotlin 코드 생성
npx rynbridge doctor        # 환경 진단
```

### 6.2 DevTools
- 브릿지 메시지 실시간 모니터링 패널
- 요청/응답 타임라인 시각화
- 메시지 모킹 및 리플레이
- Web 브라우저에서 Native 호출 시뮬레이션

### 6.3 타입 공유 시스템
```
contracts/
  device.schema.json     ← 공유 스키마 정의
        ↓ codegen
  web/  → TypeScript 타입 자동 생성
  ios/  → Swift Codable 자동 생성
  android/ → Kotlin data class 자동 생성
```

---

## 7. 레포지토리 구조

```
RynBridge/
├── packages/                    # npm 패키지 (Web)
│   ├── core/
│   ├── device/
│   ├── storage/
│   ├── ui/
│   └── cli/
├── ios/                         # Swift 패키지 (SPM)
│   ├── Sources/
│   │   ├── RynBridge/           # core
│   │   ├── RynBridgeDevice/
│   │   ├── RynBridgeStorage/
│   │   └── RynBridgeUI/
│   └── Package.swift
├── android/                     # Gradle 모듈
│   ├── core/
│   ├── device/
│   ├── storage/
│   └── ui/
├── contracts/                   # 공유 메시지 스키마
│   ├── device.schema.json
│   └── storage.schema.json
├── playground/                  # 데모 앱
│   ├── web/
│   ├── ios/
│   └── android/
├── docs/                        # 문서 사이트
├── .github/                     # CI/CD
│   └── workflows/
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

---

## 8. 기술 스택

| 영역 | 기술 |
|------|------|
| Web SDK | TypeScript, Rollup (번들링) |
| iOS SDK | Swift 5.9+, WKWebView |
| Android SDK | Kotlin, WebView, Gradle KTS |
| 코드 생성 | JSON Schema → TypeScript / Swift / Kotlin |
| 모노레포 | Turborepo |
| 테스트 | Vitest (Web), XCTest (iOS), JUnit (Android) |
| CI/CD | GitHub Actions |
| 문서 | Docusaurus |
| 린트 | ESLint, SwiftLint, ktlint |

---

## 9. 품질 전략

### 9.1 테스트
- **Unit Test**: 각 플랫폼별 모듈 단위 테스트
- **Integration Test**: 실제 WebView에서 Web ↔ Native 통신 테스트
- **Contract Test**: 스키마 변경 시 하위 호환성 검증

### 9.2 호환성
- **버전 협상**: Web SDK와 Native SDK 버전 불일치 시 graceful degradation
- **Semantic Versioning**: 모든 모듈에 SemVer 적용
- **최소 지원 버전**: iOS 17+, Android API 30+ (Android 11), ES2022+

### 9.3 성능 목표
- 코어 번들 사이즈: < 5KB (gzipped)
- 개별 모듈 번들 사이즈: < 3KB (gzipped)
- 메시지 라운드트립: < 10ms

---

## 10. 로드맵

### v0.1.0 — Foundation
- [x] 코어 메시지 프로토콜 설계 및 구현
- [x] Web (TypeScript) core SDK
- [x] iOS (Swift) core SDK
- [x] Android (Kotlin) core SDK
- [x] 기본 통신 (Request-Response) 동작 검증
- [x] Playground 앱 (Web + iOS + Android)

### v0.2.0 — Phase 1 모듈
- [x] device 모듈 (카메라, GPS, 생체인증)
- [x] storage 모듈 (SharedPreferences, UserDefaults, 파일시스템)
- [x] secure-storage 모듈 (KeyChain/KeyStore, 암호화 저장)
- [x] ui 모듈 (다이얼로그, 토스트, 상태바, 키보드)
- [x] Event Stream 통신 패턴

### v0.3.0 — DX 강화
- [x] CLI 도구 (`rynbridge init`, `rynbridge add`)
- [x] 타입 공유 코드 생성 시스템
- [x] DevTools 디버그 패널
- [x] Docusaurus 문서 사이트

### v0.4.0 — Phase 2 모듈
- [x] auth 모듈
- [x] push 모듈 (등록/해제, 권한 관리, getInitialNotification, onNotificationOpened)
- [x] payment 모듈
- [x] media 모듈
- [x] crypto 모듈 (E2EE 키 교환, AES-256-GCM 암호화, 키 로테이션)

### v0.5.0 — 네이티브 Provider 실구현
- [x] crypto Provider 구현 (CryptoKit / javax.crypto, 외부 의존성 없음)
- [x] media Provider 구현 (AVFoundation / MediaPlayer, 외부 의존성 없음)
- [x] auth 하위 패키지 분리 구조 도입 (iOS: `RynBridgeAuthApple`, Android: `auth-google`)
- [x] push 하위 패키지 분리 (iOS: `RynBridgePushAPNs`, Android: `push-fcm`)
- [x] payment 하위 패키지 분리 (iOS: `RynBridgePaymentStoreKit`, Android: `payment-google-play`)
- [x] Android auth-google Provider 실구현 (Credential Manager + Google ID)
- [x] Android push-fcm Provider 실구현 (Firebase Messaging SDK)
- [x] Android payment-google-play Provider 실구현 (Play Billing SDK)
- [x] auth-kakao 하위 패키지 추가 (iOS: KakaoSDK, Android: KakaoSDK)
### v0.6.0 — Phase 3 기본 모듈
- [x] share 모듈 (UIActivityViewController / Intent, 클립보드) + share-kakao 하위 패키지
- [x] contacts 모듈 (Contacts.framework / ContactsContract)
- [x] calendar 모듈 (EventKit / CalendarContract)
- [x] 각 모듈 contract 스키마, Web SDK, iOS/Android Provider 구현

### v0.7.0 — Phase 3 중급 모듈
- [x] navigation 모듈 (네이티브 화면 전환, 딥링크)
- [x] webview 모듈 (멀티 WebView 관리, WebView 간 메시지 통신, 보안 모델)
- [x] speech 모듈 (Speech.framework / SpeechRecognizer, STT/TTS)
- [x] analytics 모듈 + 하위 패키지 분리 (`analytics-firebase`, `analytics-amplitude` 등)
- [x] translation 모듈 + 하위 패키지 분리 (`translation-apple`, `translation-mlkit`)
- [x] 각 모듈 contract 스키마, Web SDK, iOS/Android Provider 구현

### v0.8.0 — Phase 3 고급 모듈
- [x] bluetooth 모듈 (CoreBluetooth / BluetoothGatt, BLE 스캔/연결/데이터 교환)
- [x] health 모듈 (HealthKit / Health Connect, 건강 데이터 조회/기록)
- [x] background-task 모듈 (BGTaskScheduler / WorkManager, 오프라인 동기화)
- [x] 각 모듈 contract 스키마, Web SDK, iOS/Android Provider 구현

### v0.9.0 — 배포 파이프라인
- [x] npm publish 워크플로우 (GitHub Actions, 태그 기반 자동 배포)
- [x] NPM_TOKEN 시크릿 및 `.npmrc` 레지스트리 설정
- [x] 모노레포 버전 관리 도구 도입 (changesets)
- [x] iOS SPM 릴리스 (GitHub Release 태그)
- [x] Android Maven Central 배포 설정

### v0.9.1 — 전체 모듈 단위 테스트
- [x] Phase 1 모듈 테스트 보강 (device, storage, secure-storage, ui)
- [x] Phase 2 모듈 플랫폼별 단위 테스트 (auth, push, payment, media, crypto)
- [x] Phase 3 기본 모듈 테스트 (share, contacts, calendar)
- [x] Phase 3 중급 모듈 테스트 (navigation, speech, analytics)
- [x] Phase 3 고급 모듈 테스트 (bluetooth, health, background-task)
- [x] 각 테스트 3플랫폼 대응 (Web: Vitest, iOS: XCTest, Android: JUnit)
- [x] CI 파이프라인에 전체 테스트 통합

### v0.9.2 — CLI doctor 강화
- [x] 모듈 간 의존성 검증 (core 누락, 버전 불일치 감지)
- [x] 하위 패키지 외부 SDK 설치 여부 확인 (auth-google → Google Sign-In SDK 등)
- [x] 플랫폼별 네이티브 설정 검증 (iOS: Info.plist 권한 키, Android: AndroidManifest 권한)
- [x] contract 스키마 ↔ 코드 동기화 상태 확인 (outdated 타입 감지)
- [x] Playground 빌드 상태 및 web asset 동기화 확인
- [x] 진단 결과 리포트 출력 (pass/warn/fail 요약)

### v0.9.3 — Stable Release 준비
- [x] 전체 API 안정화
- [x] 성능 최적화 및 벤치마크
- [x] 번들 사이즈 체크 CI 추가 (core < 5KB, 모듈 < 3KB gzip 자동 검증)
- [x] 루트 package.json에 `doctor` 스크립트 추가

### v0.9.4 — Native → Web 이벤트 발행
- [x] 이벤트 메시지 포맷: 기존 BridgeRequest 포맷 재사용 (별도 event 타입 불필요)
  - Web의 `handleIncomingMessage`가 모듈 핸들러 미등록 시 `EventEmitter`로 디스패치
- [x] Web core: 기존 구현이 이미 이벤트 수신 처리 (`${module}:${action}` 패턴 emit)
- [x] iOS core: `RynBridge.emitEvent(module:action:payload:)` 메서드 추가
- [x] Android core: `RynBridge.emitEvent(module, action, payload)` 메서드 추가
- [x] 이벤트 발행은 앱 레이어에서 `bridge.emitEvent()` 호출 방식 (Provider 주입 불필요)
- [x] 단위 테스트 (3 플랫폼)
- [x] 대상 이벤트:
  - push: `onNotification`, `onTokenRefresh`, `onNotificationOpened`
  - navigation: `onDeepLink`, `onAppStateChange`
  - device: `onBatteryChange`, `onLocationChange`
  - bluetooth: `onDeviceFound`, `onCharacteristicChange`, `onStateChange`
  - speech: `onRecognitionResult`
  - health: `onDataChange`
  - 기타 `on*` 이벤트 전체

### v1.0.0 — Stable Release + 오픈소스 운영
- [x] CONTRIBUTING.md (기여 가이드)
- [x] CODE_OF_CONDUCT.md (행동 강령)
- [x] GitHub Issue Template (bug_report, feature_request)
- [x] GitHub PR Template
- [ ] v1.0.0 태깅 및 최초 배포

---

## 11. 오픈소스 운영

### 11.1 기여 가이드
- Issue Template (Bug Report, Feature Request)
- PR Template
- Code of Conduct
- CONTRIBUTING.md

### 11.2 CI/CD 파이프라인

```
Push / PR
  ├── Lint (ESLint, SwiftLint, ktlint)
  ├── Build (Web, iOS, Android)
  ├── Test (Unit + Integration)
  └── Bundle Size Check

Tag (vX.Y.Z)
  ├── npm publish
  ├── SPM release (GitHub Release)
  └── Maven Central publish
```

### 11.3 커뮤니케이션
- GitHub Discussions — Q&A, 아이디어 논의
- GitHub Issues — 버그 리포트, 기능 요청
- README — 빠른 시작 가이드

---

## 12. 경쟁 분석 및 차별점

| | RynBridge | WebViewJavascriptBridge | Capacitor |
|---|---|---|---|
| 모듈 단위 경량화 | O | X | 부분적 |
| 타입 안전 (3 플랫폼) | O | X | 부분적 |
| 코드 생성 | O | X | X |
| 번들 사이즈 | 최소 | 중간 | 큼 |
| 커스텀 모듈 확장 | 쉬움 | 어려움 | 보통 |
| DevTools | O | X | O |
