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
- [x] push 모듈
- [x] payment 모듈
- [x] media 모듈
- [x] crypto 모듈 (E2EE 키 교환, AES-256-GCM 암호화, 키 로테이션)

### v0.5.0 — 네이티브 Provider 실구현
- [ ] crypto Provider 구현 (CryptoKit / javax.crypto, 외부 의존성 없음)
- [ ] media Provider 구현 (AVFoundation / MediaPlayer, 외부 의존성 없음)
- [ ] auth 하위 패키지 분리 구조 도입 (`@rynbridge/auth-google`, `@rynbridge/auth-apple`, `@rynbridge/auth-kakao`)
- [ ] push 하위 패키지 분리 (`@rynbridge/push-fcm`, `@rynbridge/push-apns`)
- [ ] payment 하위 패키지 분리 (`@rynbridge/payment-storekit`, `@rynbridge/payment-google-play`)
- [ ] 각 하위 패키지에 외부 SDK transitive dependency 포함 및 Provider 구현
### v0.6.0 — Phase 3 기본 모듈
- [ ] share 모듈 (UIActivityViewController / Intent, 클립보드)
- [ ] contacts 모듈 (Contacts.framework / ContactsContract)
- [ ] calendar 모듈 (EventKit / CalendarContract)
- [ ] 각 모듈 contract 스키마, Web SDK, iOS/Android Provider 구현

### v0.7.0 — Phase 3 중급 모듈
- [ ] navigation 모듈 (네이티브 화면 전환, 딥링크)
- [ ] speech 모듈 (Speech.framework / SpeechRecognizer, STT/TTS)
- [ ] analytics 모듈 + 하위 패키지 분리 (`analytics-firebase`, `analytics-amplitude` 등)
- [ ] 각 모듈 contract 스키마, Web SDK, iOS/Android Provider 구현

### v0.8.0 — Phase 3 고급 모듈
- [ ] bluetooth 모듈 (CoreBluetooth / BluetoothGatt, BLE 스캔/연결/데이터 교환)
- [ ] health 모듈 (HealthKit / Health Connect, 건강 데이터 조회/기록)
- [ ] background-task 모듈 (BGTaskScheduler / WorkManager, 오프라인 동기화)
- [ ] 각 모듈 contract 스키마, Web SDK, iOS/Android Provider 구현

### v0.9.0 — 배포 파이프라인
- [ ] npm publish 워크플로우 (GitHub Actions, 태그 기반 자동 배포)
- [ ] NPM_TOKEN 시크릿 및 `.npmrc` 레지스트리 설정
- [ ] 모노레포 버전 관리 도구 도입 (changesets)
- [ ] iOS SPM 릴리스 (GitHub Release 태그)
- [ ] Android Maven Central 배포 설정

### v0.9.1 — 전체 모듈 단위 테스트
- [ ] Phase 1 모듈 테스트 보강 (device, storage, secure-storage, ui)
- [ ] Phase 2 모듈 플랫폼별 단위 테스트 (auth, push, payment, media, crypto)
- [ ] Phase 3 기본 모듈 테스트 (share, contacts, calendar)
- [ ] Phase 3 중급 모듈 테스트 (navigation, speech, analytics)
- [ ] Phase 3 고급 모듈 테스트 (bluetooth, health, background-task)
- [ ] 각 테스트 3플랫폼 대응 (Web: Vitest, iOS: XCTest, Android: JUnit)
- [ ] CI 파이프라인에 전체 테스트 통합

### v1.0.0 — Stable Release
- [ ] 전체 API 안정화
- [ ] 성능 최적화 및 벤치마크
- [ ] 마이그레이션 가이드
- [ ] Phase 3 모듈 (analytics, navigation, share, health, bluetooth, contacts, calendar, speech, background-task)

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
