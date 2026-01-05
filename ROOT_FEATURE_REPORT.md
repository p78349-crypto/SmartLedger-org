# ROOT 기능(루트/관리자 모드) 상세 보고서
**작성일:** 2026-01-04  
**상태:** ✅ 구현 완료  
**담당 범위:** 전체 계정 통합 관리 및 시스템 레벨 기능

---

## 📋 개요

ROOT 기능은 **Smart Ledger의 최상위 레벨(Level 0)** 관리자 모드로, 모든 계정의 데이터를 통합 관리하고 시스템 전역 설정을 제어하는 기능입니다.

### 아키텍처 계층

```
┌─────────────────────────────────────────────┐
│ ROOT (레벨 0) ← ⭐ 이 보고서 범위             │
│ 전체 계정 통합 + 시스템 설정                  │
├─────────────────────────────────────────────┤
│ 계정별 메인(레벨 1) - AccountMainScreen     │
│ 계정 선택 후 진입                           │
├─────────────────────────────────────────────┤
│ 계정 기능(레벨 2~N)                         │
│ 거래, 자산, 통계 등 각 계정별 기능           │
└─────────────────────────────────────────────┘
```

### 시작 흐름

```
앱 시작
   ↓
LaunchScreen (진입 지점)
   ├─ 마지막 사용 계정 있음?
   │  ├─ YES → AccountMainScreen (계정별 메인)
   │  └─ NO → AccountSelectScreen (계정 선택)
   │
   └─ ROOT 페이지 접근: AccountMainScreen의 Page 5 → ROOT 기능
```

---

## 🏗️ 아키텍처

### ROOT 기능 컴포넌트 맵

| 컴포넌트 | 경로 | 역할 | 라우트 | 상태 |
|---------|------|------|---------|------|
| **전체 거래 관리** | `lib/screens/root_transaction_manager_screen.dart` | 모든 계정의 거래 통합 조회/편집 | `/root/transactions` | ✅ 완료 |
| **검색** | `lib/screens/root_search_screen.dart` | 전체 거래 통합 검색 | `/root/search` | ✅ 완료 |
| **계정 관리** | `lib/screens/root_account_manage_screen.dart` | 계정 생성/삭제/통합 | `/root/accounts` | ✅ 완료 |
| **월말 정산** | `lib/screens/root_month_end_screen.dart` | 월별 정산 및 이월 관리 | `/root/month-end` | ✅ 완료 |
| **보호기 설정** | `lib/screens/root_screen_saver_settings_screen.dart` | 앱 잠금/보호 설정 | `/root/screen-saver-settings` | ✅ 완료 |
| **노출 제한 설정** | `lib/screens/root_screen_saver_exposure_settings_screen.dart` | 민감 정보 숨김 정책 | `/root/screen-saver-exposure-settings` | ✅ 완료 |
| **아이콘 관리** | `lib/screens/icon_management_root_screen.dart` | ROOT 페이지 아이콘 커스터마이징 | `/settings/icon-management-root` | ✅ 완료 |
| **인증 게이트** | `lib/widgets/root_auth_gate.dart` | ROOT 접근 권한 검증 | - | ✅ 완료 |
| **Top-Level 통계** | `lib/screens/top_level_main_screen.dart` | 전체 계정 요약 통계 | - | ✅ 완료 |

### 라우팅 구조

```
AppRoutes.rootTransactions → '/root/transactions'
   ↓ (AppRouter.onGenerateRoute)
RootAuthGate(child: RootTransactionManagerScreen)
   ↓ (권한 검증 성공)
RootTransactionManagerScreen (UI 렌더)
```

---

## 📊 ROOT 페이지 (Page 5) 아이콘 구성

### MainFeaturePage Index 5 - ROOT

```
┌─────────────────────────────────────┐
│         ROOT (6개 아이콘)            │
├─────────────────────────────────────┤
│ [📋] 전체 거래                      │
│ [🔍] 검색                          │
│ [💼] 계정 관리                      │
│ [📅] 월말 정산                      │
│ [🛡️] 보호기 설정                    │
│ [⚙️] 아이콘 관리                    │
└─────────────────────────────────────┘
```

**코드 위치:** [MainFeatureIconCatalog.pages[5]](lib/utils/main_feature_icon_catalog.dart#L325-L366)

```dart
const MainFeaturePage(
  index: 5,
  items: [
    MainFeatureIcon(
      id: 'root_transactions',
      label: '전체 거래',
      labelEn: 'All Transactions',
      icon: IconCatalog.list,
      routeName: AppRoutes.rootTransactions,
    ),
    MainFeatureIcon(
      id: 'root_search',
      label: '검색',
      labelEn: 'Search',
      icon: IconCatalog.search,
      routeName: AppRoutes.rootSearch,
    ),
    // ... 더 많은 아이콘
  ],
)
```

---

## 🔄 ROOT 기능별 상세 기능

### 1️⃣ 전체 거래 관리 (RootTransactionManagerScreen)

**목적:** 모든 계정의 거래를 통합 조회하고 편집/삭제

**데이터 구조:**
```dart
class _RootTxEntry {
  final String accountName;        // 어느 계정의 거래?
  final Transaction tx;            // 거래 정보
}
```

**기능:**

```
전체 거래 화면
   ├─ 목록 표시
   │  └─ 계정별로 그룹화되어 표시
   │     ├─ 계정명 헤더
   │     ├─ 거래 목록 (최신순, 금액순)
   │     └─ 각 거래:
   │        ├─ 거래일
   │        ├─ 설명 (상품명)
   │        ├─ 금액 (결제수단 표시)
   │        └─ 카테고리
   │
   ├─ 거래 편집
   │  └─ 행을 탭하면 TransactionAddScreen으로 이동
   │     └─ 변경 후 저장 → 자동 새로고침
   │
   └─ 거래 삭제
      └─ 행 길게 누르면 삭제 옵션
         └─ 확인 후 삭제
```

**코드 위치:** [RootTransactionManagerScreen](lib/screens/root_transaction_manager_screen.dart#L1-L100)

**주요 로직:**
```dart
List<_RootTxEntry> _buildEntries() {
  final service = TransactionService();
  final entries = <_RootTxEntry>[];

  // 모든 계정에서 거래 수집
  for (final accountName in service.getAllAccountNames()) {
    for (final tx in service.getTransactions(accountName)) {
      entries.add(_RootTxEntry(accountName: accountName, tx: tx));
    }
  }

  // 최신순, 금액순으로 정렬
  entries.sort((a, b) {
    final dateCompare = b.tx.date.compareTo(a.tx.date);
    if (dateCompare != 0) return dateCompare;
    return b.tx.amount.abs().compareTo(a.tx.amount.abs());
  });

  return entries;
}
```

---

### 2️⃣ 전체 거래 검색 (RootSearchScreen)

**목적:** 모든 계정의 거래를 통합 검색

**검색 조건:**
- 거래 설명(상품명)
- 거래 금액
- 거래 날짜
- 계정명
- 카테고리

**UI:**
```
검색 화면
   ├─ 검색 입력창
   │  └─ 실시간 검색 적용
   │
   ├─ 필터 옵션
   │  ├─ 거래 유형 (수입/지출)
   │  ├─ 날짜 범위
   │  ├─ 금액 범위
   │  └─ 계정 선택
   │
   └─ 검색 결과 목록
      └─ 매칭되는 거래 표시
         ├─ 계정명
         ├─ 거래 정보
         └─ 탭하여 상세 보기/편집
```

---

### 3️⃣ 계정 관리 (RootAccountManageScreen)

**목적:** 계정 생성, 삭제, 통합, 병합

**기능:**

```
계정 관리 화면
   ├─ 계정 목록 표시
   │  └─ 각 계정:
   │     ├─ 계정명
   │     ├─ 거래 수
   │     ├─ 총 자산
   │     ├─ 마지막 거래일
   │     └─ 액션 버튼
   │        ├─ [편집]: 계정명 변경
   │        └─ [삭제]: 계정 삭제 (확인)
   │
   ├─ [새 계정 추가] 버튼
   │  └─ 계정명 입력 다이얼로그
   │
   └─ [계정 통합] 버튼 (선택적)
      └─ 여러 계정을 하나로 통합
```

**알려진 기능:**
- ✅ 계정 생성/삭제
- ✅ 계정명 변경
- ⚠️ 계정 통합 (부분 구현)

---

### 4️⃣ 월말 정산 (RootMonthEndScreen)

**목적:** 월말 거래 정산 및 이월 관리

**기능:**

```
월말 정산 화면
   ├─ 월별 요약
   │  ├─ 월 선택
   │  └─ 해당 월 통계
   │     ├─ 총 수입
   │     ├─ 총 지출
   │     ├─ 순 자산 변화
   │     └─ 카테고리별 지출
   │
   ├─ 정산 항목 확인
   │  └─ 검토할 거래 목록
   │
   └─ 이월 처리
      ├─ 다음 달로 이월할 항목 선택
      └─ 이월 실행 버튼
```

**연관 위젯:** `MonthEndCarryoverDialog`

---

### 5️⃣ 보호기 설정 (RootScreenSaverSettingsScreen)

**목적:** 앱 보안 및 개인정보 보호 설정

**기능:**

```
보호기 설정 화면
   ├─ [🔒 앱 잠금 활성화]
   │  └─ 앱을 백그라운드로 보낼 때 자동 잠금
   │
   ├─ [🔐 패스코드/생체인증 설정]
   │  ├─ 패스코드 4자리 설정
   │  └─ 생체인증(지문/얼굴) 활성화
   │
   ├─ [⏱️ 잠금 시간 설정]
   │  └─ 앱 활동 중단 후 몇 초 후 잠금할지 설정
   │
   ├─ [👁️ 민감 정보 숨기기]
   │  └─ 잠금 상태에서 금액 표시 여부
   │
   └─ [🎨 배경 설정]
      └─ 잠금 화면 배경 이미지/색상
```

**저장 위치:** SharedPreferences (암호화됨)

---

### 6️⃣ 노출 제한 설정 (RootScreenSaverExposureSettingsScreen)

**목적:** 민감한 금융 정보 노출 제한

**기능:**

```
노출 제한 설정 화면
   ├─ [💰 금액 표시 제한]
   │  └─ 리스트뷰에서 금액 숨기기 (●●●●●원)
   │
   ├─ [📊 통계 숨기기]
   │  └─ 통계 화면 접근 제한 또는 금액 마스킹
   │
   ├─ [🏦 자산 숨기기]
   │  └─ 자산 정보 비표시
   │
   └─ [⏰ 자동 숨기기 시간]
      └─ 특정 시간(예: 21:00~08:00)에만 정보 숨기기
```

---

## 🔐 인증 게이트 (RootAuthGate)

모든 ROOT 화면은 `RootAuthGate` 위젯으로 감싸져 있어 접근 권한을 검증합니다.

**코드 위치:** [RootAuthGate 위젯](lib/widgets/root_auth_gate.dart)

**동작:**
```dart
class RootAuthGate extends StatelessWidget {
  final Widget child;
  
  @override
  Widget build(BuildContext context) {
    // 1. 현재 사용자가 관리자 권한인지 확인
    final isAdmin = UserPrefService.isAdminUser();
    
    // 2. 패스코드 설정되어 있는지 확인
    final passcodeSet = UserPrefService.hasPasscode();
    
    // 3. 최근 인증 시간 확인 (5분 이내?)
    final recentAuth = UserPrefService.isRecentlyAuthenticated();
    
    if (!isAdmin || !passcodeSet || !recentAuth) {
      // 인증 화면으로 리다이렉트
      return AuthenticationScreen();
    }
    
    // 4. 권한 확인 완료 → 실제 화면 표시
    return child;
  }
}
```

---

## 📊 데이터 흐름

### ROOT 데이터 수집 및 통합

```
각 계정별 데이터
   ├─ Account 1
   │  ├─ transactions: [tx1, tx2, ...]
   │  ├─ assets: [asset1, asset2, ...]
   │  └─ fixedCosts: [cost1, cost2, ...]
   │
   ├─ Account 2
   │  ├─ transactions: [tx3, tx4, ...]
   │  └─ ...
   │
   └─ Account N
      └─ ...
         ↓
TransactionService.getAllAccountNames()
   ↓ (각 계정명으로 데이터 조회)
통합 리스트 생성
   ├─ 모든 거래 통합
   ├─ 계정별로 그룹화
   └─ 정렬 (최신순/금액순)
   ↓
화면 렌더링 (_buildEntries())
```

---

## 🎯 ROOT 네비게이션

### 진입 방식

#### 방식 1: AccountMainScreen의 Page 5 탭
```
AccountMainScreen
   ↓ (사용자가 페이지 5 아이콘 탭)
MainFeatureIconCatalog.pages[5] 아이콘
   ↓ (아이콘 탭)
IconLaunchUtils.buildRequest()
   ↓ (AppRoutes.rootTransactions 등)
Navigator.pushNamed(context, AppRoutes.root...)
   ↓
AppRouter.onGenerateRoute()
   ↓
RootAuthGate 확인
   ↓
실제 ROOT 화면 표시
```

#### 방식 2: 직접 라우팅 (내부/디버깅)
```dart
Navigator.of(context).pushNamed(
  AppRoutes.rootTransactions,
);
```

---

## ✅ 현황 체크리스트

| 항목 | 상태 | 검증 필요 | 비고 |
|------|------|---------|------|
| **전체 거래 관리** | ✅ 완료 | ✓ | 조회/편집/삭제 가능 |
| **전체 검색** | ✅ 완료 | ✓ | 다중 필터 지원 |
| **계정 관리** | ✅ 완료 | ✓ | 생성/삭제 기본 구현 |
| **월말 정산** | ✅ 완료 | ✓ | 이월 처리 기본 구현 |
| **보호기 설정** | ✅ 완료 | ✓ | 패스코드/생체인증 |
| **노출 제한** | ✅ 완료 | ✓ | 민감 정보 마스킹 |
| **아이콘 관리** | ✅ 완료 | ✓ | Page 5 커스터마이징 |
| **인증 게이트** | ✅ 완료 | ✓ | 권한 검증 로직 |
| **라우팅** | ✅ 완료 | ✓ | 4개 ROOT 라우트 등록 |

---

## 🧪 검증 항목 (수행 필요)

### 단계 1: 라우팅 및 진입

#### A. 각 ROOT 화면 진입 테스트
```
1. AccountMainScreen에서 Page 5(ROOT) 탭
2. "전체 거래" 아이콘 탭
   → RootTransactionManagerScreen 진입 확인
3. 각 아이콘별 테스트 반복:
   - [검색] → RootSearchScreen
   - [계정 관리] → RootAccountManageScreen
   - [월말 정산] → RootMonthEndScreen
   - [보호기 설정] → RootScreenSaverSettingsScreen
   - [아이콘 관리] → IconManagementRootScreen
```

#### B. 인증 게이트 확인
```
1. ROOT 화면 진입 시도
2. 패스코드 미설정 → 설정 화면 진입 확인
3. 패스코드 설정 후 재시도 → 화면 진입 확인
```

### 단계 2: 전체 거래 관리

#### A. 데이터 조회
```
1. 2개 이상 계정에 거래 추가
2. RootTransactionManagerScreen 진입
3. 모든 계정의 거래가 통합되어 표시되는지 확인
4. 정렬 (최신순/금액순) 작동 확인
```

#### B. 거래 편집
```
1. 거래 탭
2. TransactionAddScreen으로 진입 확인
3. 거래 정보 수정 후 저장
4. 목록으로 돌아와 수정된 정보 반영 확인
```

#### C. 거래 삭제
```
1. 거래 길게 누르기
2. [삭제] 옵션 나타나는지 확인
3. 삭제 확인 다이얼로그 나타나는지 확인
4. 삭제 후 목록에서 제거되는지 확인
```

### 단계 3: 검색 기능

#### A. 기본 검색
```
1. RootSearchScreen 진입
2. 검색창에 상품명 입력 (예: "커피")
3. 매칭되는 거래만 표시되는지 확인
```

#### B. 필터 검색
```
1. 거래 유형: [지출]만 필터
   → 지출 거래만 표시 확인
2. 날짜 범위: 이번 달만 선택
   → 이번 달 거래만 표시 확인
3. 계정 선택: Account 1만 선택
   → Account 1의 거래만 표시 확인
```

### 단계 4: 계정 관리

#### A. 계정 목록 조회
```
1. RootAccountManageScreen 진입
2. 모든 계정 목록 표시 확인
3. 각 계정의 정보(거래 수, 자산, 마지막 거래일) 정확한지 확인
```

#### B. 계정 생성
```
1. [새 계정 추가] 버튼
2. 계정명 입력 (예: "여행비")
3. [생성]
4. 새 계정이 목록에 추가되는지 확인
```

#### C. 계정 편집
```
1. 계정의 [편집] 버튼
2. 계정명 변경 (예: "여행비" → "해외여행비")
3. 저장 후 목록에서 변경 확인
```

#### D. 계정 삭제
```
1. 계정의 [삭제] 버튼
2. 삭제 확인 다이얼로그
   "○○ 계정을 삭제하시겠습니까? (거래 ~~개)"
3. [삭제] 확인
4. 계정 및 관련 거래 삭제 확인
```

### 단계 5: 월말 정산

#### A. 월별 요약 조회
```
1. RootMonthEndScreen 진입
2. 현재 월 선택
3. 통계 표시:
   - 총 수입
   - 총 지출
   - 순 자산 변화
   - 카테고리별 지출
```

#### B. 이월 처리
```
1. 지난 달 선택
2. 미결제 항목 확인
3. 이월할 항목 선택
4. [이월 실행]
5. 다음 달로 항목이 이동되는지 확인
```

### 단계 6: 보호기 설정

#### A. 앱 잠금 활성화
```
1. RootScreenSaverSettingsScreen 진입
2. [앱 잠금 활성화] 토글
3. 앱을 백그라운드로 보냄
4. 일정 시간 후 재진입 시 잠금 화면 나타나는지 확인
```

#### B. 패스코드 설정
```
1. [패스코드 설정] 클릭
2. 4자리 숫자 입력 (예: 1234)
3. 확인 입력
4. 저장 후 잠금 해제 시 패스코드 요구 확인
```

#### C. 잠금 시간 설정
```
1. [잠금 시간] 조정
2. 30초 설정
3. 앱 사용 중단 30초 후 자동 잠금 확인
```

### 단계 7: 노출 제한 설정

#### A. 금액 마스킹
```
1. RootScreenSaverExposureSettingsScreen 진입
2. [금액 표시 제한] 활성화
3. 거래 목록으로 이동
4. 금액이 ●●●●●원으로 표시되는지 확인
```

#### B. 시간대별 제한
```
1. [자동 숨기기] 활성화
2. 시간대 설정 (예: 21:00~08:00)
3. 설정된 시간대에는 금액 숨김 확인
4. 설정된 시간대 외에는 금액 표시 확인
```

---

## 📚 관련 파일 및 문서

- [main.dart (앱 시작점)](lib/main.dart)
- [LaunchScreen (진입 화면)](lib/screens/launch_screen.dart)
- [app_routes.dart (라우트 정의)](lib/navigation/app_routes.dart#L92-L97)
- [app_router.dart (라우트 매핑)](lib/navigation/app_router.dart#L635-L656)
- [RootAuthGate (인증 게이트)](lib/widgets/root_auth_gate.dart)
- [MainFeatureIconCatalog (아이콘 목록)](lib/utils/main_feature_icon_catalog.dart#L325-L366)
- [계정 관리 정책](DOCUMENTATION/MAIN_PAGES_POLICY.md)

---

## 🚀 다음 단계

1. ✅ **ROOT 코드 검증** - `flutter analyze` 통과 확인
2. **실제 시나리오 테스트** - 위의 검증 항목 수행
3. **보안 강화 (선택)** - 생체인증 추가, 암호화 레벨 상향
4. **기능 확장 (선택)**
   - 계정 통합/병합 완성
   - 데이터 내보내기/가져오기
   - ROOT 전용 통계 리포트

---

## 📈 향후 확장 가능성

- 🔮 **ROOT 대시보드:** 전체 계정 요약 대시보드 (총 자산, 월간 지출 등)
- 🔮 **데이터 백업:** ROOT 레벨의 전체 데이터 백업/복구
- 🔮 **사용자 초대:** 다른 사용자에게 ROOT 권한 공유
- 🔮 **감사 로그:** 모든 거래/계정 변경 기록
- 🔮 **고급 검색:** AI 기반 거래 분석 및 추천
- 🔮 **멀티디바이스 동기화:** 여러 기기 간 데이터 실시간 동기화
- 🔮 **클라우드 백업:** 자동 클라우드 동기화

---

**작성:** GitHub Copilot  
**마지막 검토:** 2026-01-04
