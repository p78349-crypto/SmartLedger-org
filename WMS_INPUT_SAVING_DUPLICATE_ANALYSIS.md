# WMS 기능 지출입력/저장 방법 검토 보고서

**작성일**: 2026-02-03  
**검토 대상**: WMS (Warehouse Management System) 입출고 기능  
**핵심 질문**: 지출입력 및 저장방법의 문제점 / 중복 처리 방식

---

## 📋 Executive Summary

WMS 입출고 기능의 현재 구조를 분석한 결과:
- ✅ **입출고 입력 방식**: 기본적으로 정상
- ⚠️ **저장 방법**: 논리적으로는 정상이나 **사용자 경험상 일부 개선 여지**
- ⚠️ **중복 처리**: **정책 불명확** - 현재는 **강제 거부 방식**인데, 경우에 따라 "추가" 선택 가능

---

## 🔍 현재 구조 분석

### 1. 지출입력 방법 (입고/출고)

#### 위치: [lib/screens/wms_io_screen.dart](lib/screens/wms_io_screen.dart)

**입고 프로세스:**
```dart
1. 품목명 입력 (필수)
2. 현재 재고 수량 입력
3. 기본 배송 단위, 보관 위치, 건강 태그 선택
4. [입고] 버튼 → WmsInventoryGateway.addItem() 호출
5. 결과에 따라:
   - success: 입고 완료 메시지 + 폼 초기화
   - duplicate: 중복 다이얼로그 표시
   - error: 에러 메시지 표시
```

**평가:**
- ✅ 단순하고 직관적
- ✅ 입력 필드별 UI 배치 적절
- ✅ 예시값 제공 (재고:0, 기본:1, 단위:개)

---

### 2. 저장 방법 분석

#### 저장 위치
[lib/utils/wms_data_gateway.dart - addItem()](lib/utils/wms_data_gateway.dart#L100)

**저장 흐름:**
```dart
1️⃣ 입력값 유효성 검사 (WmsInventoryInput.validate())
   - 품목명 필수
   - 재고 >= 0
   - 알림기준 >= 0
   - 묶음크기 > 0
   - 보관위치 유효성

2️⃣ 중복 체크 (findByName())
   ⚠️ 현재: 정규화 방식 (trim + lowercase)
   - "우유" vs "  우유  " → 같음 처리
   - "우유" vs "우유" (다른 case) → 같음 처리

3️⃣ Service 호출 (ConsumableInventoryService.addItem())
   - SQLite DB에 저장

4️⃣ 캐시 무효화 + 반환
```

**평가:**
- ✅ 유효성 검사 충분
- ✅ 중복 체크 구현됨
- ⚠️ **문제 1**: 중복 검사가 "이름만" 기준
  - 같은 이름, 다른 위치(냉장 vs 냉동)? → 중복 판정
  - 같은 이름, 다른 카테고리? → 중복 판정

---

## 🚨 중복 처리 방식 상세 분석

### 문제점 1: 중복 판정 기준이 "이름만"

**현재 코드:**
```dart
Future<ConsumableInventoryItem?> findByName(String name) async {
  final items = await getItems();
  final normalized = name.trim().toLowerCase();
  
  for (final item in items) {
    if (item.name.trim().toLowerCase() == normalized) {
      return item;  // 첫 번째 매칭 반환
    }
  }
  return null;
}
```

**시나리오별 분석:**

| 시나리오 | 현재 동작 | 예상 동작 | 문제 |
|---------|---------|---------|------|
| 우유 (냉장) vs 우유 (냉동) | 중복 판정 | 다름 처리? | ⚠️ 같은 상품명이지만 보관위치가 다른 경우 처리 불명확 |
| 우유 (생활용품) vs 우유 (식품) | 중복 판정 | 다름 처리? | ⚠️ 카테고리가 다른 경우도 구분 불명확 |
| "우유" vs "  우유  " | 중복 판정 | 중복 (정상) | ✅ 정상 |
| "우유" vs "牛乳" (일본어) | 구분 처리 | 다른 상품 | ✅ 정상 |

---

### 문제점 2: 중복 발견 시 사용자 선택 구조 불명확

**현재 코드 (wms_io_screen.dart Line 149-177):**
```dart
Future<void> _showDuplicateDialog(
  ConsumableInventoryItem existing,
) async {
  final addMore = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('이미 존재하는 품목'),
      content: Text(
        '${existing.name}이(가) 이미 등록되어 있습니다.\n'
        '현재 재고: ${existing.currentStock}${existing.unit}\n\n'
        '입력한 수량을 추가하시겠습니까?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('추가'),
        ),
      ],
    ),
  );

  if (addMore == true) {
    final addStock = double.tryParse(_stockController.text) ?? 0.0;
    final updated = existing.copyWith(
      currentStock: existing.currentStock + addStock,
    );
    await ConsumableInventoryService.instance.updateItem(updated);
    // ...
  }
}
```

**평가:**
- ✅ 사용자에게 선택 기회 제공
- ⚠️ **문제**: 다이얼로그 내용이 혼동을 야기
  - "추가하시겠습니까?" → 재고 수량을 더하는 것인지?
  - 아니면 새로운 품목으로 추가하는 것인지?
  - 명확하지 않음

---

## 🛠️ 권장 개선사항

### 개선안 1: 중복 판정 기준 명확화

**옵션 A**: 이름 + 위치 기준 (권장)
```dart
Future<ConsumableInventoryItem?> findByNameAndLocation(
  String name,
  String location,
) async {
  final items = await getItems();
  final normalized = name.trim().toLowerCase();
  
  for (final item in items) {
    if (item.name.trim().toLowerCase() == normalized &&
        item.location == location) {
      return item;
    }
  }
  return null;
}
```

**옵션 B**: 이름 + 카테고리 기준
```dart
Future<ConsumableInventoryItem?> findByNameAndCategory(
  String name,
  String category,
) async {
  // ...
}
```

---

### 개선안 2: 중복 다이얼로그 명확화

**개선 전:**
```
이미 존재하는 품목
우유이(가) 이미 등록되어 있습니다.
현재 재고: 12개

입력한 수량을 추가하시겠습니까?
[취소] [추가]
```

**개선 후 (이름+위치 기준):**
```
이미 존재하는 품목
상품명: 우유 (냉장)
현재 재고: 12개
보관 위치: 냉장

이 상품의 재고에 5개를 추가하시겠습니까?
[취소] [추가] [다른 상품으로 등록]
```

---

### 개선안 3: 저장 방법 흐름도 추가

**현재 문제:** 사용자가 저장 흐름을 모를 수 있음

**권장 사항:**
1. 입고/출고 완료 후 **어디에 저장되는지 명시**
2. 임시저장(Draft) vs 영구저장 구분
3. 실시간 DB 연동 vs 주기적 동기화 여부 명시

---

## 📊 현재 상태 요약

| 항목 | 현재 상태 | 평가 | 개선 필요 |
|------|---------|------|---------|
| 입력 방식 | 단순 폼 입력 | ✅ 좋음 | ❌ 없음 |
| 입력 검증 | 6개 필드 검사 | ✅ 충분 | ❌ 없음 |
| 중복 감지 | 이름 기준 (case-insensitive) | ⚠️ 부분적 | ✅ 필요 |
| 중복 처리 | 사용자 선택 (추가/취소) | ⚠️ 모호함 | ✅ 필요 |
| 저장 위치 | SQLite DB 직접 저장 | ✅ 명확 | ❌ 없음 |
| 캐시 관리 | 저장 후 즉시 무효화 | ✅ 좋음 | ❌ 없음 |
| Draft 기능 | WmsDraftManager 별도 구현 | ✅ 있음 | ❌ 없음 |

---

## 🎯 권장 조치

### 우선순위 1: 중복 판정 기준 재정의
- [ ] 중복 판정을 "이름 + 위치" 또는 "이름 + 카테고리"로 변경
- [ ] 같은 이름 상품을 다른 위치에서 관리할 수 있도록 지원

### 우선순위 2: 다이얼로그 UX 개선
- [ ] 다이얼로그에 현재 상품의 모든 정보(위치, 카테고리 등) 표시
- [ ] "재고 추가" 의도를 명확히 표현

### 우선순위 3: 사용자 가이드 추가
- [ ] 입출고 화면에 "입력된 정보는 즉시 저장됩니다" 안내
- [ ] 중복 발견 시 "이름과 위치가 모두 일치하는 경우만 중복으로 판정합니다" 명시

---

## 💾 Draft 시스템 현황

[WMS_DRAFT_SYSTEM_IMPLEMENTATION_2026-02-02.md](WMS_DRAFT_SYSTEM_IMPLEMENTATION_2026-02-02.md) 참조

**현재 구현 상황:**
- ✅ WmsInventoryDraftEntry 모델 완성
- ✅ WmsDraftManager 완성
- ✅ UserPrefService에 Draft 메서드 6개 추가
- ✅ SharedPreferences 키: `wms_inventory_drafts_v1`

**Draft 저장 특징:**
- 최대 30개 항목 관리
- 자동 중복 제거 (ID 기준)
- 영구저장 전에 검토 가능

---

## 결론

**WMS 입출고 기능의 지출입력과 저장방법은 기본적으로 정상이지만, 중복 처리 정책이 불명확합니다.**

### 핵심 개선점:
1. **중복 판정 기준**: "이름만" → "이름 + 위치/카테고리"로 변경
2. **사용자 안내**: 중복 발견 시 정확한 판정 기준 명시
3. **UX 개선**: 다이얼로그에 전체 정보 표시

이러한 개선을 통해 같은 상품명을 여러 위치에서 관리할 수 있도록 확장할 수 있습니다.
