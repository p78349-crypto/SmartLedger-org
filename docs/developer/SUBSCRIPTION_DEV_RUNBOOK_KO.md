# 구독 개발/운영 런북 (개발자용)

> 대상: SmartLedger 개발자/운영자
> 목적: 구독 모듈 설정, 테스트, 장애 대응 표준화

---

## 1. 구성요소 개요

- 상태 캐시/판정: `lib/services/subscription_access_service.dart`
- 결제 오케스트레이션: `lib/services/subscription_billing_service.dart`
- 스토어 어댑터 인터페이스: `lib/services/subscription_store_adapter.dart`
- Android 어댑터: `lib/services/play_store_subscription_adapter.dart`
- 구매 스트림 동기화: `lib/services/subscription_purchase_sync_service.dart`
- 상품 ID 설정: `lib/config/subscription_product_config.dart`
- 게이트: `lib/widgets/asset_route_auth_gate.dart`

---

## 2. 상품 ID 설정

`dart-define`로 플랫폼 상품 ID를 주입한다.

### Android

flutter run --dart-define=SUBSCRIPTION_PRODUCT_IDS_ANDROID=smartledger_premium_monthly

### iOS

flutter run --dart-define=SUBSCRIPTION_PRODUCT_IDS_IOS=smartledger_premium_monthly_ios

복수 상품은 콤마로 전달:

flutter run --dart-define=SUBSCRIPTION_PRODUCT_IDS_ANDROID=monthly_id,yearly_id

---

## 3. 동작 흐름

1. 구독 필요 라우트 진입
2. `AssetRouteAuthGate`가 구독 상태 선검증
3. 차단 시 구독 관리 화면 이동
4. 구독 관리 화면에서 purchase stream 동기화 시작
5. 구매/복구 이벤트 수신 시 `SubscriptionAccessService` 캐시 갱신

---

## 4. 테스트 가이드

### 필수 명령

- flutter analyze --no-fatal-infos
- flutter test test/services/subscription_access_service_test.dart
- flutter test test/services/subscription_billing_service_test.dart
- flutter test test/smoke/root_asset_auth_smoke_test.dart
- flutter test test/smoke

### 검증 포인트

- 만료 상태에서 차단 UI 표시
- 활성 상태에서 진입 허용
- 차단 화면의 `구독 관리` 액션 동작
- 어댑터 결과(success/notAvailable/failed) 매핑 정확성

---

## 5. 장애 대응 런북

### 증상 A: 결제 요청 시작 실패

- 상품 ID 오타/미등록 확인
- Play Console 테스트 트랙/계정 상태 확인
- `in_app_purchase` 초기화 가능 여부 확인

### 증상 B: 결제 성공 후도 차단 유지

- purchase stream 수신 여부 확인
- `pendingCompletePurchase` 완료 호출 확인
- `SubscriptionAccessService` 캐시 값 확인

### 증상 C: 복구가 동작하지 않음

- 동일 스토어 계정 로그인 여부
- restore 호출 후 상태 재조회 수행 여부

---

## 6. 보안 원칙

- 클라이언트 결제 콜백 단독으로 영구 권한 확정 금지
- 서버 영수증 검증이 붙기 전까지는 임시 상태로 운영
- 최종 권한 소스는 서버 상태로 전환 예정(v2)

---

## 7. v2 전환 TODO

- 서버 영수증 검증 API 연동
- 환불/취소/유예 웹훅 동기화
- 구독 상태 감사 로그 적재
- 운영 대시보드(상태 분포/실패율) 연결
