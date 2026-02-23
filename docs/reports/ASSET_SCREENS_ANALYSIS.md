# 자산 관리 화면 분석

## 현재 구조

### 페이지 4 (자산) 아이콘
```
1. assetDashboard    → "자산 대시보드"    (/asset/dashboard)
2. assetAllocation   → "자산 할당"       (/asset/allocation)
3. assetManagement   → "자산 평가"       (/asset/management)
4. assetSimpleInput  → "자산 입력"       (/asset/input/simple)
5. assetProject100m  → "1억 프로젝트"    (/asset/project-100m)
```

---

## 화면별 역할 분석

### 1️⃣ AssetDashboardScreen (`asset_dashboard_screen.dart`)
**라우트:** `/asset/dashboard`

**기능:**
- 총 자산액 표시
- 총 손익 표시
- 손익률(%)
- 자산별 카드 뷰 (현재가, 원가, 손익)
- 최근 타임라인

**특징:** 
- ✅ 자산 조회 전용 (읽기)
- ✅ AssetRouteAuthGate로 보호됨
- ✅ 데이터 시각화 중심

---

### 2️⃣ AssetManagementScreen (`asset_management_screen.dart`)
**라우트:** `/asset/management`

**현재 구조:**
```dart
class AssetManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자산 관리')),
      actions: [
        PopupMenuButton (자산 입력 메뉴)
      ],
      body: AssetTabScreen(accountName: accountName),  // ← 본체
    );
  }
}
```

**문제:**
- ❌ 단순 래퍼 (AssetTabScreen 로드)
- ❌ 별도 기능 없음
- ❌ AppBar에만 메뉴 추가

---

### 3️⃣ AssetTabScreen (`asset_tab_screen.dart`)  
**라우트:** 없음 (AssetManagementScreen에 포함됨)

**기능:**
- 생체인증 (지문/PIN/비밀번호)
- 자산 입력 (간편/상세)
- 자산 배분 분석
- 자산 대시보드 (포함됨)
- 비상금 관리
- 엑셀/CSV 내보내기

---

## 🔴 발견된 문제

### A. 중복/래퍼 구조
```
/asset/management
    ↓
AssetManagementScreen
    ↓ (본체)
AssetTabScreen
    ↓ (내부 포함)
AssetDashboardScreen
```

**문제:** AssetManagementScreen은 단순 래퍼일 뿐

### B. 라우트 혼란
- `/asset/dashboard` → AssetDashboardScreen (조회)
- `/asset/management` → AssetManagementScreen → AssetTabScreen (입력 + 조회)

**중복:** 둘 다 자산 조회 기능 포함

### C. 보안 불일치
- AssetDashboardScreen: ✅ AssetRouteAuthGate 적용
- AssetManagementScreen: ❌ 보호 없음 (AssetTabScreen 내부에서만 인증)

---

## ✅ 해결 옵션

### 옵션 1: AssetManagementScreen 제거
```
/asset/management → AssetTabScreen 직접 라우팅
(AssetManagementScreen 제거)

결과:
- /asset/dashboard → 조회 (대시보드)
- /asset/management → 관리 (입력/삭제/배분)
```

### 옵션 2: 역할 명확화
```
/asset/dashboard → 조회 전용 (AssetDashboardScreen)
/asset/management → 관리/편집 (AssetTabScreen)
/asset/tab → 제거 또는 내부용으로 변경

AssetManagementScreen → 래퍼 제거, AssetTabScreen 직접 사용
```

### 옵션 3: 아이콘 통합
```
페이지 4 아이콘 수정:
1. assetDashboard    → "자산 조회"       (/asset/dashboard)
2. assetAllocation   → "자산 배분"       (/asset/allocation) 
3. assetManagement   → "자산 관리"       (/asset/management)  ← AssetTabScreen 직접
4. assetSimpleInput  → 제거 (AssetTabScreen에 포함)
5. assetProject100m  → "1억 프로젝트"    (/asset/project-100m)
```

---

## 🎯 권장 조치

1. **AssetManagementScreen 단순화**
   - 현재: 단순 래퍼 (불필요)
   - 변경: AssetTabScreen 직접 라우팅
   - 또는: 역할 분명화

2. **보안 통일**
   - AssetManagementScreen에 권한 검사 통합

3. **아이콘 라벨 정확화**
   - "자산 평가" → "자산 관리" 또는 "자산 입력"

---

## 작업 필요 여부

**현재:** 기능상 중복/래퍼 존재
**영향:** 코드 복잡도, 사용자 혼동 가능성
**우선순위:** 🟡 중간 (작동은 정상, 정리 필요)
