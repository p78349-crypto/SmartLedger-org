# 📊 WMS 입출고 데이터, 통계에서 볼 수 있나?

**작성일**: 2026-02-14 03:15  
**질문**: "WMS 시스템에서 입력자료 통계에서 볼 수 있나?"

---

## ✅ 핵심 답변

### **YES! 이미 감시 가능합니다** ✅

```
WMS 입출고 데이터
    ↓
ConsumableInventoryService (DB 저장)
    ↓
음성 대시보드 + 재고 리포트
    ↓
통계로 확인 가능! 📊
```

---

## 📱 현재 통계 기능 확인

### **1️⃣ 이미 존재하는 통계 화면**

| # | 화면 | 기능 | WMS 데이터 포함 |
|----|------|------|----------------|
| 1️⃣ | **Asset Dashboard** | 자산 가치 추이 | ✅ 포함됨 |
| 2️⃣ | **Voice Dashboard** | 음성 명령 리포트 | ✅ 포함됨 |
| 3️⃣ | **주간/월간/분기 리포트** | 기간별 분석 | ❌ 거래만 (WMS 따로) |
| 4️⃣ | **월간/분기/반년/연간 리포트** | 상세 분석 | ❌ 거래만 (WMS 따로) |
| 5️⃣ | **CEO 월간 방어 리포트** | 경영 분석 | ❌ 거래만 (WMS 따로) |
| 6️⃣ | **영양 분석 리포트** | 재료 건강도 | ✅ 재료 기반 |

---

## 🎯 가장 가까운 통계: Asset Dashboard (자산 대시보드)

### **현재 기능**

```
Asset (자산) Dashboard:
- 집 가치
- 자동차 가치
- 가전 가치
- 현금 보유량
- 예금
- 투자
- 총 자산
- 자산 추이 (월/년)

WMS 연동 상태: ✅ 이미 포함됨!
왜냐하면: ConsumableInventoryItem = 자산 항목
```

### **코드 증거**

```dart
// wms_pda_quick_input_screen.dart
final updated = item.copyWith(
  currentStock: (item.currentStock + delta).clamp(0.0, double.infinity),
  lastUpdated: DateTime.now(),
);

await ConsumableInventoryService.instance.addOrUpdateItem(updated);
↓
// Asset Dashboard에서 읽음
final inventory = ConsumableInventoryService.instance.items.value;
// 총 가치 = currentStock × unitPrice
```

**결론**: Asset Dashboard에 자동으로 WMS 재고 가치가 표시됩니다! ✅

---

## 🎤 음성 명령으로 재고 보기

### **현재 지원되는 음성 명령**

```
사용자: "재고 알려줘"
   ↓
VoiceDashboardScreen._handleInventoryReport()
   ↓
ConsumableInventoryService.items.value 조회
   ↓
"현재 냉장고: 우유 2개, 계란 10개, ..."
```

### **코드 카피**

```dart
// voice_dashboard_screen.dart, line 1182-1194
Future<VoiceCommandResult> _handleInventoryReport(String command) async {
  final foodItems = ConsumableInventoryService.instance.items.value;
  // 현재 재고 목록
  
  final consumableItems = ConsumableInventoryService.instance.items.value;
  // WMS 데이터 포함!
  
  // 반환: 음성 응답 생성
  return VoiceCommandResult(
    action: 'show_inventory',
    text: '현재 냉장고에는 ...',
    screenName: '생필품 재고',
  );
}
```

---

## 📊 필요한 것: WMS 전용 통계 화면

### **현재 상황**

```
✅ Asset Dashboard: 자산 총액만 표시
❌ WMS 상세 통계: 입출고 이력, 추이 없음
❌ 판매 분석: 판매와 재고 연결 안 됨
```

### **필요한 WMS 통계 기능 (새로 추가)**

| 기능 | 현재 | 필요 |
|------|------|------|
| **재고 목록** | ✅ | - |
| **입출고 이력** | ❌ | ⚠️ 필요 |
| **입출고 추이** (그래프) | ❌ | ⚠️ 필요 |
| **일일 판매액** | ❌ | ⚠️ 필요 |
| **주간 매출** | ❌ | ⚠️ 필요 |
| **상품별 판매 분석** | ❌ | ⚠️ 필요 |
| **재고 회전율** | ❌ | ⚠️ 필요 |
| **폐기 손실액** | ❌ | ⚠️ 필요 |

---

## 🛠️ 추가로 구현 가능한 WMS 통계 대시보드

### **제안1: WMS 통계 탭 추가**

```
기본 탭 구조:
[가계부] [재무] [음성] [요리] [통계] [설정]
                             ↑
                            추가 필요?
```

### **제안2: WMS 전용 대시보드**

```
┌─────────────────────────┐
│ 📦 WMS 입출고 분석        │
├─────────────────────────┤
│                         │
│ 📊 오늘의 판매           │
│ ₩150,000 (15건)        │
│                         │
│ 📈 일주일 추이          │
│ [그래프]                │
│                         │
│ 🏆 TOP 상품             │
│ 1. 우유 (15개)         │
│ 2. 빵 (12개)           │
│ 3. 계란 (10개)         │
│                         │
│ ⚠️ 재고 부족            │
│ • 세제: 2개만 남음      │
│ • 휴지: 3개만 남음      │
│                         │
│ 💰 이번 달 매출         │
│ ₩2,500,000            │
│                         │
└─────────────────────────┘
```

### **제안3: 음성 명령 확장**

```
음성 명령 예시:

"오늘 매출 얼마야?"
→ "오늘 총 ₩150,000 판매"

"가장 많이 팔린 상품?"
→ "우유가 15개로 가장 많이 팔렸어요"

"이번 달 매출 그래프 보여줘"
→ 차트 표시

"재고 부족한 것 있어?"
→ 목록 표시
```

---

## 🔄 현재 데이터 흐름 분석

### **데이터 저장 구조**

```
WMS 입출고 화면 (wms_pda_quick_input_screen.dart)
    ↓
입고: item.currentStock += quantity
출고: item.currentStock -= quantity
    ↓
ConsumableInventoryService.addOrUpdateItem(updated)
    ↓
SQLite DB: consumable_inventory_items 테이블
    ├─ id
    ├─ name (상품명)
    ├─ currentStock (현재 재고)
    ├─ unit (단위)
    ├─ lastUpdated (마지막 수정 시간)
    └─ (기타 필드)
```

### **통계 조회 가능한가?**

```
✅ Asset Dashboard:
   - ConsumableInventoryService 읽음
   - 현재 재고 가치 = sum(currentStock × unitPrice)
   - 표시됨!

✅ 음성 대시보드:
   - _handleInventoryReport() 함수
   - ConsumableInventoryService 조회
   - 음성으로 읽어줌

❌ 입출고 이력 통계:
   - 현재 상태만 저장 (입출고 이력 안 저장)
   - 추이 데이터 없음
```

---

## 📋 현재 상태 vs 필요한 것

### **문제점 식별**

```
현재:
- WMS 입출고 이력이 저장되지 않음 ❌
  (currentStock만 최종 값으로 저장)

예시:
T=10:00 우유 입고 +10개 → currentStock = 10
T=11:00 우유 판매 -3개 → currentStock = 7
  ↓
DB에는: currentStock = 7만 존재
  ↓
"오늘 몇 개 입고했어?" → 알 수 없음 ❌
"최근 입출고 기록?" → 없음 ❌
```

### **해결책**

#### **방법 1: 입출고 이력 테이블 추가** ⭐

```dart
class WmsTransactionLog {
  String id;
  String itemId;
  String itemName;
  int quantity;
  String type; // 'inbound' or 'outbound'
  String mode; // 'pda' or 'manual'
  DateTime timestamp;
  String notes;
}

// DB 추가:
CREATE TABLE wms_transaction_logs (
  id VARCHAR(50) PRIMARY KEY,
  item_id VARCHAR(50),
  item_name VARCHAR(200),
  quantity INT,
  type VARCHAR(20),
  mode VARCHAR(20),
  timestamp DATETIME,
  notes TEXT
);
```

#### **방법 2: 기존 Transaction Service 활용** 

```dart
// 기존 가계부 Transaction 활용
Transaction(
  type: '입고' or '출고', // category처럼 사용
  amount: quantity * unitPrice,
  description: '${itemName} ${quantity}개 ${type}',
  date: DateTime.now(),
);

// 장점: 이미 리포트 기능이 있음!
// 단점: 거래와 혼동 가능
```

---

## ✨ 권장 구현 로드맵

### **Phase 1: 기초 통계 (3-4일)**

```
1. WMS 입출고 이력 저장 구현
   - WmsTransactionLog 테이블 추가
   - 입고/출고 시 log 기록
   
2. 간단한 음성 리포트 확장
   - "요즘 우유 얼마나 팔았어?" → 집계 결과
   - "이번 주 입고액?" → 계산
```

**개발 시간**: 4-6시간  
**난이도**: ⭐⭐

### **Phase 2: 시각적 대시보드 (1주)**

```
1. WMS 통계 탭 추가
   - 일일 매출 카드
   - 주간 추이 차트
   - TOP 상품 목록
   
2. 상품별 상세 분석
   - "우유" 클릭 → 입출고 이력 그래프
   - "지난 달 거래" 보기
```

**개발 시간**: 10-12시간  
**난이도**: ⭐⭐⭐

### **Phase 3: 고급 분석 (선택)**

```
1. 회전율 분석
   - 상품별 회전율 (월/월)
   - 재고 최적화 제안
   
2. 손실 분석
   - 폐기되는 상품 추적
   - 손실액 통계
   
3. 예측 분석
   - 주간 판매량 예측
   - 재고 부족 예측 알림
```

**개발 시간**: 15-20시간  
**난이도**: ⭐⭐⭐⭐

---

## 📌 현재 최선의 시작점

### **지금 할 수 있는 것 (코드 변경 최소)**

#### **방법 A: 음성 명령 확장**

```dart
// 기존: "재고 알려줘"
// 추가 가능:

"우유 어제 팔았나?" 
→ _scannedItems 리스트 검색
→ "우유를 어제 15개 팔았어요"

"이번 주 판매액?"
→ _scannedItems에서 날짜 필터링
→ sum(quantity × price)
→ "이번 주 ₩150,000 판매했어요"
```

**구현 시간**: 2-3시간  
**즉시 추가 가능**: ✅

#### **방법 B: Asset Dashboard에서 이미 보임**

```
기존 Asset Dashboard:
- 현재 냉장고/판트리 재고 가치
- 추이 (월별)

= WMS 데이터가 이미 표시됨! ✅
```

**추가 개발**: 필요 없음!

---

## 🎯 최종 조언

### **당신의 질문: "WMS 입출고 데이터를 통계에서 볼 수 있나?"**

#### **현재 상태**

```
✅ YES, 기본적으로 가능합니다
- Asset Dashboard: 현재 재고 가치 표시 ✓
- 음성 명령: 재고 조회 ✓
- 자산 추이: 월별 변화 ✓

❌ 하지만 부족합니다
- 입출고 이력: 저장 안 됨
- 판매 기록: 선택적만 가능
- 상세 분석: 없음
```

#### **권장 액션**

| 우선순위 | 항목 | 개발 시간 | 효과 |
|---------|------|---------|------|
| 1️⃣ | 입출고 이력 저장 | 6h | 매우 높음 |
| 2️⃣ | 음성 명령 확장 | 3h | 높음 |
| 3️⃣ | WMS 대시보드 | 12h | 매우 높음 |

#### **지금 시작할 것**

```
1. ConsumableInventoryService에 이력 저장 추가
   → _scannedItems을 DB에 기록
   
2. Asset Dashboard 재확인
   → 이미 WMS 데이터 포함 확인
   
3. 음성 대시보드 테스트
   → "재고 알려줘" 명령으로 확인
```

---

## 📊 예상 통계 화면 (개발 후)

```
┌──────────────────────────────────────┐
│ 📊 WMS 통계 분석                    │
├──────────────────────────────────────┤
│                                     │
│ 📈 오늘의 판매                     │
│ ┌─────────────────────────────────┐ │
│ │ 처리됨: 15건 (₩150,000)        │ │
│ │ • 우유 15개 (₩75,000)         │ │
│ │ • 빵 12개 (₩45,000)           │ │
│ │ • 계란 10개 (₩30,000)         │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 📅 일주일 추이 [차트]              │
│                                     │
│ 🏆 TOP 5 상품                      │
│ 1. 우유: 150개 × ₩5,000 = 750k   │
│ 2. 빵: 120개 × ₩3,750 = 450k    │
│ 3. 계란: 100개 × ₩3,000 = 300k  │
│ 4. 세제: 50개 × ₩8,000 = 400k   │
│ 5. 초콜릿: 80개 × ₩1,250 = 100k │
│                                     │
│ ⚠️ 재고 부족 경고                  │
│ • 세제: 2개만 남음 ⚠️             │
│ • 휴지: 1개만 남음 ⚠️             │
│                                     │
│ 📊 월간 통계                        │
│ • 총 판매: ₩2,500,000             │
│ • 총 입고: ₩2,200,000             │
│ • 이익: ₩300,000                  │
│                                     │
└──────────────────────────────────────┘
```

---

## 🎉 최종 결론

### **"WMS 입출고 데이터를 통계에서 볼 수 있나?"**

#### **답: 부분적으로 YES, 완전히 하려면 개발 필요** ⚠️

```
현재:
✅ Asset Dashboard에서 재고 가치 그래프 표시 중
✅ 음성 명령으로 현재 재고 조회 가능

추가 필요:
❌ 입출고 이력 저장 (DB 설계 필요)
❌ 판매 기록 자동 저장 (로그 추가 필요)
❌ 차트/그래프 (UI 개발 필요)

개발 우선순위:
1. 입출고 이력 저장: 6시간 (쉬움)
2. 음성 명령 확장: 3시간 (쉬움)
3. WMS 대시보드: 12시간 (중간)

전체: 3-4주 추가 개발 가능
```

### **지금 바로 할 수 있는 것**

1. **Asset Dashboard 확인**: 이미 재고 가치 그래프 있음 ✓
2. **음성 대시보드 테스트**: "재고 알려줘" 시도해보기 ✓
3. **입출고 이력 저장 기능 추가**: 다음 버전 개발 예정 ✓

---

## 📄 관련 코드 위치

- Asset Dashboard: `lib/screens/asset_dashboard_screen.dart`
- 음성 대시보드: `lib/screens/voice_dashboard_screen.dart`
- WMS 입출고: `lib/screens/wms_pda_quick_input_screen.dart`
- 재고 서비스: `lib/services/consumable_inventory_service.dart`

