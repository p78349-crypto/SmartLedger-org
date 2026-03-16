# SmartLedger 구독결제 설계서 v1

> 작성일: 2026-02-28  
> 목적: 구현보다 먼저, 구독 기능의 정책/아키텍처/데이터 경계를 확정한다.

---

## 1) 설계 목표

- 앱 내 프리미엄 기능 접근을 **구독 상태 기반**으로 통제한다.
- 결제 SDK(Play/iOS)는 어댑터로 분리해 교체 가능하게 설계한다.
- 클라이언트 단독 판정이 아닌 **서버 검증 우선** 구조를 기본 원칙으로 한다.
- 장애/오프라인 상황에서도 권한 상승이 발생하지 않게 fail-safe를 유지한다.

---

## 2) 범위 정의 (In/Out)

### In Scope

- 구독 상태 모델/상태머신 정의
- 기능 접근 게이트(Asset/Stats 고급 화면)
- 결제/복구 호출 인터페이스(어댑터)
- 구독 관리 화면 UX(상태확인/결제진행/복구)
- 테스트 전략(서비스 단위 + 스모크)

### Out of Scope (v1)

- 실제 서버 영수증 검증 엔드포인트 구현
- 결제 완료 웹훅 파이프라인
- 다국가 가격/세금 정책 엔진
- 구독 상품 A/B 운영 대시보드

---

## 3) 핵심 정책

1. 권한 판정 우선순위: **서버 상태 > 로컬 캐시**
2. 로컬 캐시는 임시 판정용(짧은 TTL)으로만 사용
3. 상태가 불명확하면 접근 허용이 아니라 제한 처리
4. `grace`는 정책적으로 허용 가능(기본 허용), 필요 시 즉시 차단 가능

---

## 4) 구독 상태머신

상태: `active`, `grace`, `paused`, `expired`, `refunded`, `revoked`, `unknown`

- `active`: 프리미엄 접근 허용
- `grace`: 정책 플래그에 따라 허용/차단
- `paused`/`expired`/`refunded`/`revoked`: 차단
- `unknown`: 차단(결제 유도)

권한 함수 기준:

- `hasPremiumAccess(state, allowGrace)`
- 현재 구현에서 `active`/`grace(옵션)`만 허용

---

## 5) 아키텍처 구성

### 5.1 클라이언트 계층

- `SubscriptionAccessService`
  - 상태 저장/조회/권한 판정
  - SharedPreferences 캐시 관리

- `SubscriptionBillingService`
  - 상태 조회/결제 시작/복구 오케스트레이션
  - 스토어 어댑터 결과를 도메인 결과로 매핑

- `SubscriptionStoreAdapter` (추상)
  - 플랫폼별 결제 SDK 호출 추상화

- `PlayStoreSubscriptionAdapter`
  - Android `in_app_purchase` 기반 결제/복구 요청

- `AssetRouteAuthGate`
  - `requiresSubscription` 옵션으로 구독 선검증
  - 차단 시 구독 관리 화면으로 이동 액션 제공

### 5.2 라우팅 계층

- 전용 경로: `AppRoutes.subscriptionManage`
- 적용 화면(현재):
  - 자산: 포트폴리오 분석, 투자 로드맵
  - 통계: 월간 통계, 지출 분석

---

## 6) 데이터 계약 (클라이언트 캐시)

키(유저별 suffix):

- `subscription_status_v1`
- `subscription_product_id_v1`
- `subscription_platform_v1`
- `subscription_expires_at_ms_v1`
- `subscription_updated_at_ms_v1`

최소 레코드 필드:

- `status`, `productId`, `platform`, `expiresAtMs`, `updatedAtMs`

---

## 7) 결제 흐름 (v1/v2 분리)

### v1 (현재 단계)

- 결제 요청 시작/복구 요청 API 호출 가능
- 상태 갱신은 캐시 기반(테스트/운영 초기)
- 서버 미연동 시 안내 메시지 중심

### v2 (필수 전환)

1. 결제 완료 이벤트 수신
2. 서버 영수증 검증 API 호출
3. 서버가 최종 상태 확정
4. 클라이언트 캐시 동기화
5. 게이트 접근 재평가

---

## 8) 보안 설계 원칙

- 클라이언트 결제 성공 콜백만으로 권한 상승 금지
- 만료/환불/취소 이벤트는 즉시 차단 경로 보장
- 계정 변경 시 구독 캐시 분리 강제
- 감사 로그(상태 변경 시점/원인) 추적 포인트 확보

---

## 9) 장애/예외 처리

- 스토어 미가용: `notAvailable`
- 사용자 취소: `cancelled`
- SDK 실패/예외: `failed` → 도메인 `error` 매핑
- 상태 불명확: `unknown`으로 처리 후 차단

---

## 10) 테스트 전략

### 단위 테스트

- 상태 판정 함수(`active/grace/expired`) 검증
- BillingService 어댑터 결과 매핑 검증

### 스모크 테스트

- 구독 만료 시 게이트 차단
- 활성 시 접근 허용
- 차단 화면의 구독 관리 액션 동작

---

## 11) 단계별 실행 계획

### Phase A (완료)

- 상태 서비스/게이트/라우팅/구독관리 화면/테스트 기본 구축

### Phase B (다음)

- 서버 검증 API 계약서 확정
- purchase stream 반영하여 상태 갱신 자동화
- 상품 ID/플랜 정책 외부 설정화

### Phase C (출시 전)

- 환불/취소/유예 시나리오 E2E 검증
- 스토어 심사 체크리스트(가격/해지/환불 고지) 확정
- 운영 모니터링/로그 대시보드 연결

---

## 12) 의사결정 필요 항목

1. `grace` 접근 허용 정책: 허용(기본) vs 즉시 차단
2. 구독 단위: 계정(accountName) vs 사용자(userId)
3. 서버 우선 동기화 주기: 앱 시작 시/백그라운드 복귀 시/주기 폴링
4. 상품 라인업: 월간 1종 vs 월/연 2종
