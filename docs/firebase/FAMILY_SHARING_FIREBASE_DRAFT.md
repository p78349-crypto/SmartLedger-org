# 가족 공유(Firebase) – 초안 설계 (SmartLedger)

이 문서는 SmartLedger의 **미래 기능(가족 공유)** 설계 초안입니다.

- 현재 기본 모드: Firebase 미사용(로컬 저장만)
- Firebase 재도입 시: 아래 모델/규칙을 참고하여 구현

## 목표
- 여러 기기/여러 가족 구성원이 같은 데이터(재고/쇼핑준비)를 안전하게 공유.
- 권한/보안 규칙이 명확하고, 나중에 기능 확장(초대 링크, 역할, 감사 로그) 가능.
- 현재 앱 구조는 로컬(SharedPreferences) 기반이므로, Remote를 추가해도 로컬 UX/흐름은 유지.

## 전제(권장)
- 로그인 허용: Firebase Auth (Google/Apple/이메일 중 1개 이상)
- 동기화: Firestore(오프라인 캐시 + 실시간)

## 데이터 모델(권장 컬렉션)

### 1) 사용자
- `users/{uid}`
  - `displayName` (string)
  - `activeFamilyId` (string?)
  - `createdAt` (timestamp)
  - `lastSeenAt` (timestamp)

### 2) 가족(그룹)
- `families/{familyId}`
  - `name` (string)
  - `createdAt` (timestamp)
  - `createdBy` (uid)

- `families/{familyId}/members/{uid}`
  - `role` ("owner" | "admin" | "member")
  - `joinedAt` (timestamp)

### 3) 공유 데이터
- `families/{familyId}/consumables/{itemId}`
  - 로컬 `ConsumableInventoryItem`의 json을 대부분 그대로 보관(필드 호환)
  - 권장 추가 필드: `updatedAt`(timestamp), `updatedBy`(uid)

- `families/{familyId}/shoppingCartItems/{cartItemId}`
  - 로컬 `ShoppingCartItem`과 동일한 구조
  - 권장 추가 필드: `updatedAt`, `updatedBy`

- (선택) `families/{familyId}/shoppingCartHistory/{entryId}`

## 초대/가입 흐름(MVP)
- `families/{familyId}` 생성 시 `owner`로 등록.
- 초대는 1차 MVP에서는 “가족 ID + 초대코드” 입력.
  - 이후 확장: Dynamic Links + Cloud Functions로 초대 토큰 발급/만료.

## 보안 규칙(요지)
- 가족 데이터는 해당 family의 members에 포함된 uid만 접근 가능.
- members 관리(추가/삭제)는 role=owner(또는 admin)만.

## 클라이언트 구조(이미 준비된 seam)
- `AppRepositories.consumableInventory` / `AppRepositories.shoppingCart`
  - 현재: 로컬 구현
  - Firebase 적용 시: Firestore 구현체로 교체

## 구현 순서(추천)
1. Auth 연결 + activeFamily 선택
2. Firestore Rules 확정
3. repository를 Firestore로 교체(로컬과 동등 동작)
4. 충돌 정책/감사 로그 필요 시 추가

## 충돌/오프라인 정책(권장 최소)
- 문서 단위 last-write-wins(서버 타임스탬프 기반)
- 필드별 merge는 2단계에서 고려
