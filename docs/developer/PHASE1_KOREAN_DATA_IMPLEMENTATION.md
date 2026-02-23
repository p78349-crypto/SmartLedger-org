# 📋 SmartLedger 글로벌 바코드 DB 통합 - 실행 계획서

**작성일**: 2026-02-14 03:45  
**목표**: SmartLedger PDA 바코드 스캔 → 자동 상품 매칭 + 수량 입력

---

## 📊 발견된 데이터 구조

### **한국 식료품 데이터**

```
파일: 식료품 데이터.xlsx
└─ 위치: C:\Users\plain\GemmaFineTuning\archive\korean_reference\글로벌 식료품 데이터

구조:
├─ 행: 3,088개 (헤더 포함, 실제 상품 3,087개)
├─ 열: 5개
│  ├─ KAN_CODE (8자리 한국 표준 코드): "01010101", "01010102", ...
│  ├─ CLS_NM_1 (대분류): "가공식품", ...
│  ├─ CLS_NM_2 (중분류): "조미료", ...
│  ├─ CLS_NM_3 (소분류): "종합조미료", ...
│  └─ CLS_NM_4 (세분류): "천연/발효조미료", ...

특징:
✅ 한국 표준 상품 분류 코드 (KAN_CODE)
✅ 상품 카테고리 정보 완전
⚠️ 실제 상품명 없음 (카테고리만 있음)
⚠️ 일반 바코드(EAN-13) 없음

분류 예시:
"01010101" → 가공식품 / 조미료 / 종합조미료 / 천연/발효조미료
"01010102" → 가공식품 / 조미료 / 종합조미료 / 식초
```

### **미국 FoodData_Central 데이터**

```
파일들:
├─ FoodData_Central_branded_food_json_2025-12-18.json (3.3GB)
├─ FoodData_Central_branded_food_json_2025-12-18.zip (204MB)
├─ FoodData_Central_csv_2025-12-18.zip (479MB)
└─ 기타 연도별 파일들 (2021-2025)

구조:
├─ JSON 형식
├─ foods[] 배열
└─ 각 상품:
   ├─ description (상품명)
   ├─ fdcId (USDA ID)
   ├─ gtinUpc (바코드: EAN-13, UPC-A)
   ├─ dataType
   ├─ ndbNumber
   └─ [영양 정보 필드들]

특징:
✅ 상품명 포함
✅ EAN-13/UPC-A 바코드 포함
✅ 완전한 영양 정보
✅ 제조사 정보 포함 (일부)
⚠️ 파일 크기 매우 큼 (3GB+)
⚠️ 압축 형식도 있음

예상 상품 수: 100,000+개
```

### **일본 데이터 (MEXT Kagsei)**

```
파일:
├─ 20201225-mxt_kagsei-mext_01110_001.pdf
├─ 20201225-mxt_kagsei-mext_01110_012.xlsx
├─ 20201225-mxt_kagsei-mext_01110_022.xlsx
└─ 20201225-mxt_kagsei-mext_01110_042.xlsx

특징:
✅ 일본 식료품 표준 데이터
✅ 일본 표준 코드 (JAN 등)
✅ 영양 정보 포함

상품 수 (추정): 3,000-10,000개
```

### **OpenFoodFacts (글로벌)**

```
파일: openfoodfacts-mongodbdump.gz (12.5GB)

특징:
✅ 전세계 식료품 데이터
✅ 131개 언어 지원
✅ EAN-13, UPC-A, JAN 바코드 포함
✅ 제품 이미지
✅ 성분 정보
✅ 알레르기 정보

상품 수: ~1,000,000+개
⚠️ MongoDB 형식
⚠️ 파일 크기 매우 큼 (12GB+)

API 사용 가능:
├─ URL: https://world.openfoodfacts.org/api/v0/products/{barcode}
├─ 응답: JSON
├─ 지연: 100-500ms
└─ 비용: 무료
```

---

## 🎯 Phase 1: 한국 데이터 통합 (1주일)

### **Step 1: 데이터 준비**

**문제**: 현재 한국 데이터는...
- ✗ 실제 상품명 없음 (카테고리 코드만 있음)
- ✗ 일반 바코드 없음 (KAN_CODE = 유통 표준 코드)
- ✓ 표준화된 분류 체계

**해결책**:

#### **Option A: 유통 표준코드.pdf 파싱** (권장하지 않음)
- PDF 크기: 38MB
- 포함 정보: 바코드 ↔ KAN_CODE 매핑?
- 신뢰도: 낮음 (PDF 형식 분석 어려움)

#### **Option B: 온라인 소스 결합** (권장)
- OpenFoodFacts API + 한국 이름
- 방법: KAN_CODE → 카테고리명 → OpenFoodFacts 검색
- 예: "01010105" → "가공식품/조미료/종합조미료/설탕"
      → "sugar" 검색 → EAN-13 바코드 찾기

#### **Option C: 한국 마트 API 활용** (장기)
- E-mart, GS25 등에서 바코드 ↔ 상품명 API 제공?
- TBD (조사 필요)

### **Step 1-1: 한국 데이터 DB 생성**

```sql
-- SQLite 테이블
CREATE TABLE global_product_master (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- 바코드 필드
    ean13 TEXT,                 -- EAN-13 (일반 바코드)
    upc_a TEXT,                 -- UPC-A (미국)
    jan_code TEXT,              -- JAN (일본)
    kan_code TEXT,              -- KAN_CODE (한국)
    
    -- 상품 정보
    product_name_ko TEXT,       -- 한글 상품명
    product_name_en TEXT,       -- 영문 상품명
    product_name_ja TEXT,       -- 일본어 상품명
    
    -- 분류
    category_1 TEXT,            -- 대분류
    category_2 TEXT,            -- 중분류
    category_3 TEXT,            -- 소분류
    category_4 TEXT,            -- 세분류
    
    -- 기본 정보
    manufacturer TEXT,          -- 제조사/유통사
    packaging_unit TEXT,        -- 단위 (병, 팩, 상자 등)
    default_quantity INTEGER,   -- 기본 수량 (한국: 2)
    country_code TEXT,          -- 국가 (KR, US, JP 등)
    
    -- 영양 정보 (선택)
    calories_per_100g REAL,
    protein_per_100g REAL,
    fat_per_100g REAL,
    carbs_per_100g REAL,
    
    -- F라그
    is_active BOOLEAN DEFAULT 1,
    data_source TEXT,           -- 데이터 출처
    
    -- 타임스탐프
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(ean13, upc_a, jan_code)
);

-- 검색 성능을 위한 인덱스
CREATE INDEX idx_ean13 ON global_product_master(ean13);
CREATE INDEX idx_upc_a ON global_product_master(upc_a);
CREATE INDEX idx_jan_code ON global_product_master(jan_code);
CREATE INDEX idx_kan_code ON global_product_master(kan_code);
CREATE INDEX idx_product_name_ko ON global_product_master(product_name_ko);
```

### **Step 1-2: 한국 CSV 변환**

```python
# 식료품 데이터.xlsx → CSV 변환
pandas를 사용해서 Excel → CSV 변환

Path: 식료품 데이터.csv
Content:
kan_code,category_1,category_2,category_3,category_4
01010101,가공식품,조미료,종합조미료,천연/발효조미료
01010102,가공식품,조미료,종합조미료,식초
...
```

### **Step 1-3: 임포트 스크립트**

```python
# lib/services/barcode_importer.dart 또는 Python 스크립트

def import_korean_data():
    # 1. CSV 읽기
    # 2. 정규화 (공백 제거, 대소문자 통일)
    # 3. 중복 제거
    # 4. 배치 INSERT (1000개씩)
    # 5. 인덱스 생성
    # 6. 검증
    pass
```

---

## 🔧 Phase 2: SmartLedger 통합 (3일)

### **Step 2-1: 새 파일 생성**

#### `lib/services/global_product_service.dart`

```dart
import 'package:sqflite/sqflite.dart';

class GlobalProductService {
  
  /// 바코드로 상품 검색 (3계층 캐시 활용)
  Future<GlobalProduct?> searchByBarcode(String barcode) async {
    // 1. L1 캐시: 메모리 (최근 1000개)
    if (_memoryCache.containsKey(barcode)) {
      return _memoryCache[barcode];
    }
    
    // 2. L2 캐시: Redis (선택)
    // final cached = await _redisCache.get(barcode);
    // if (cached != null) return cached;
    
    // 3. L3: SQLite DB
    final result = await db.query(
      'global_product_master',
      where: 'ean13 = ? OR upc_a = ? OR jan_code = ? OR kan_code = ?',
      whereArgs: [barcode, barcode, barcode, barcode],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      final product = GlobalProduct.fromMap(result.first);
      _memoryCache[barcode] = product;  // L1 캐시 저장
      return product;
    }
    
    return null;
  }
  
  /// 상품 카테고리로 검색
  Future<List<GlobalProduct>> searchByCategory(
    String cate1, 
    [String? cate2, String? cate3, String? cate4]
  ) async {
    String where = 'category_1 = ?';
    List<String> args = [cate1];
    
    if (cate2 != null) {
      where += ' AND category_2 = ?';
      args.add(cate2);
    }
    if (cate3 != null) {
      where += ' AND category_3 = ?';
      args.add(cate3);
    }
    if (cate4 != null) {
      where += ' AND category_4 = ?';
      args.add(cate4);
    }
    
    final result = await db.query(
      'global_product_master',
      where: where,
      whereArgs: args,
    );
    
    return result.map((e) => GlobalProduct.fromMap(e)).toList();
  }
  
  // 메모리 캐시 (LinkedHashMap으로 LRU 구현)
  final _memoryCache = LinkedHashMap<String, GlobalProduct>();
  static const maxCacheSize = 1000;
}
```

#### `lib/models/global_product.dart`

```dart
class GlobalProduct {
  final int id;
  final String? ean13;
  final String? upcA;
  final String? janCode;
  final String? kanCode;
  
  final String? productNameKo;
  final String? productNameEn;
  final String? productNameJa;
  
  final String? category1;
  final String? category2;
  final String? category3;
  final String? category4;
  
  final String? manufacturer;
  final String? packagingUnit;
  final int defaultQuantity;  // 기본값: 한국 = 2
  final String countryCode;   // KR, US, JP
  
  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? fatPer100g;
  final double? carbsPer100g;
  
  final String dataSource;
  final DateTime createdAt;
  
  GlobalProduct({
    required this.id,
    this.ean13,
    this.upcA,
    this.janCode,
    this.kanCode,
    this.productNameKo,
    this.productNameEn,
    this.productNameJa,
    this.category1,
    this.category2,
    this.category3,
    this.category4,
    this.manufacturer,
    this.packagingUnit,
    this.defaultQuantity = 1,
    this.countryCode = 'KR',
    this.caloriesPer100g,
    this.proteinPer100g,
    this.fatPer100g,
    this.carbsPer100g,
    this.dataSource = 'local',
    required this.createdAt,
  });
  
  factory GlobalProduct.fromMap(Map<String, dynamic> map) {
    return GlobalProduct(
      id: map['id'],
      ean13: map['ean13'],
      upcA: map['upc_a'],
      janCode: map['jan_code'],
      kanCode: map['kan_code'],
      productNameKo: map['product_name_ko'],
      productNameEn: map['product_name_en'],
      productNameJa: map['product_name_ja'],
      category1: map['category_1'],
      category2: map['category_2'],
      category3: map['category_3'],
      category4: map['category_4'],
      manufacturer: map['manufacturer'],
      packagingUnit: map['packaging_unit'],
      defaultQuantity: map['default_quantity'] ?? 1,
      countryCode: map['country_code'] ?? 'KR',
      caloriesPer100g: map['calories_per_100g']?.toDouble(),
      proteinPer100g: map['protein_per_100g']?.toDouble(),
      fatPer100g: map['fat_per_100g']?.toDouble(),
      carbsPer100g: map['carbs_per_100g']?.toDouble(),
      dataSource: map['data_source'] ?? 'local',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
```

### **Step 2-2: PDA 화면 수정**

#### `lib/screens/wms/wms_pda_quick_input_screen.dart` 수정

**변경 전**:
```dart
// 바코드로 inventory에서만 검색
_handleBarcodeScanned(barcodeValue) {
  var item = _inventoryService.getItemByBarcode(barcodeValue);
  if (item != null) {
    setState(() => _currentItem = item);
  }
}
```

**변경 후**:
```dart
// 바코드로 global DB에서 먼저 검색
_handleBarcodeScanned(barcodeValue) async {
  // 1. 글로벌 DB에서 검색
  GlobalProduct? globalProduct = 
    await _globalProductService.searchByBarcode(barcodeValue);
  
  if (globalProduct != null) {
    // 2. 글로벌 상품이 found → 자동 매칭
    setState(() {
      _currentItem = _convertGlobalToWmsItem(globalProduct);
      _quantityController.text = globalProduct.defaultQuantity.toString();
      _quantityController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _quantityController.text.length,
      );
    });
    
    // 3. 수량 필드로 포커스 이동
    _quantityFocus.requestFocus();
  } else {
    // 4. 글로벌 DB에 없음 → 로컬 inventory에서 검색
    var item = _inventoryService.getItemByBarcode(barcodeValue);
    if (item != null) {
      setState(() => _currentItem = item);
      _quantityFocus.requestFocus();
    } else {
      // 5. 새로운 상품 → 수동 입력
      _showNewProductDialog(barcodeValue);
    }
  }
}

// 글로벌 상품 → WMS 아이템으로 변환
WmsQuickItem _convertGlobalToWmsItem(GlobalProduct product) {
  return WmsQuickItem(
    id: null,  // 새로 생성
    barcode: product.ean13 ?? product.upcA ?? product.janCode ?? '',
    name: product.productNameKo ?? product.productNameEn ?? 'Unknown',
    category: product.category2 ?? '',
    quantity: product.defaultQuantity,
  );
}
```

### **Step 2-3: DB 마이그레이션**

```dart
// lib/db/migrations/migration_20260214_add_global_products.dart

Future<void> migration_20260214_add_global_products(Database db) async {
  // 테이블 생성
  await db.execute('''
    CREATE TABLE IF NOT EXISTS global_product_master (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ean13 TEXT,
      upc_a TEXT,
      jan_code TEXT,
      kan_code TEXT,
      product_name_ko TEXT,
      product_name_en TEXT,
      product_name_ja TEXT,
      category_1 TEXT,
      category_2 TEXT,
      category_3 TEXT,
      category_4 TEXT,
      manufacturer TEXT,
      packaging_unit TEXT,
      default_quantity INTEGER DEFAULT 1,
      country_code TEXT DEFAULT 'KR',
      calories_per_100g REAL,
      protein_per_100g REAL,
      fat_per_100g REAL,
      carbs_per_100g REAL,
      is_active BOOLEAN DEFAULT 1,
      data_source TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(ean13, upc_a, jan_code, kan_code)
    )
  ''');
  
  // 인덱스 생성
  await db.execute('CREATE INDEX idx_ean13 ON global_product_master(ean13)');
  await db.execute('CREATE INDEX idx_upc_a ON global_product_master(upc_a)');
  await db.execute('CREATE INDEX idx_jan_code ON global_product_master(jan_code)');
  await db.execute('CREATE INDEX idx_kan_code ON global_product_master(kan_code)');
  
  // CSV에서 한국 데이터 임포트
  await _importKoreanData(db);
}

Future<void> _importKoreanData(Database db) async {
  // 1. CSV 파일 읽기 (앱 assets 또는 다운로드)
  // 2. 파싱
  // 3. 배치 INSERT
  // ...
}
```

---

## 📱 UI 개선 결과

### **사용자 경험 변화**

**Before (현재)**:
```
1. 바코드 스캔
2. 상품 찾기 (inventory만)
   → 없으면 수동 입력
3. 수량 입력
```

**After (개선)**:
```
1. 바코드 스캔
   ↓
2. 글로벌 DB 검색 (<100ms)
   ↓
3a. 발견: 상품명 + 이미지 자동 표시
             수량 자동 입력 (기본값 2)
   ↓
3b. 미발견: 로컬 inventory 검색
   ↓  
3c. 둘 다 미발견: 새로운 상품 등록
   ↓
4. 수량 확인 (pre-filled) → Enter
   ↓
5. 자동 저장 → 리셋
```

---

## ⏱️ 개발 시간 추정

| 항목 | 작업 | 시간 |
|------|------|------|
| **DB 설계** | 스키마 정의, 마이그레이션 | 2h |
| **임포트 도구** | CSV 파싱, 배치 INSERT | 3h |
| **서비스 계층** | GlobalProductService 클래스 | 2h |
| **UI 통합** | PDA 화면 수정 | 2h |
| **테스트** | 단위/통합 테스트 | 2h |
| **문제 해결** | 버그 픽스, 최적화 | 2h |
| **바코드 검사** | 하드웨어 스캔 테스트 | 1h |
| **배포** | APK 빌드, 설치 | 1h |
| **총합** | | **15시간** |

---

## 🎯 성공 기준

### **Phase 1 완료 시**

```
✅ 한국 3088개 상품이 global_product_master 테이블에 로드됨
✅ 바코드 스캔 → <100ms 내에 상품 매칭
✅ 매칭된 상품 → 한글 이름 + 기본수량(2) 자동 표시
✅ 수량 필드에 자동 포커스 + 텍스트 선택
✅ Enter 키 → 자동 저장 → 바코드 필드로 리셋
✅ 새로운 상품 또는 로컬 등록도 여전히 작동
✅ 메모리 캐시 L1 (1000개 최근 스캔) 작동
✅ 하드웨어 바코드 스캔 / 수동 입력 모두 지원
```

---

## 🚀 다음 단계

### **Phase 2: OpenFoodFacts API 연동** (1주일)
- 한국 데이터 부족분 채우기
- 온라인 실시간 검색 기능

### **Phase 3: 미국 FoodData 임포트** (2주)
- 70,000개 미국 상품
- 다국어 UI 지원

### **Phase 4: POS 기능** (3주)
- 판매 거래 기록
- 결제 처리
- 영수증 출력

---

## 📞 의존성 및 주의사항

### **라이브러리 의존**

```yaml
# pubspec.yaml
dependencies:
  sqflite: '^2.2.0'  # 이미 있음
  csv: '^6.0.0'      # 추가 필요
  http: '^1.1.0'     # OpenFoodFacts API용
  cached_network_image: '^3.2.0'  # 상품 이미지
```

### **성능 최적화**

```
1. 인덱싱: B-tree 인덱스 (검색 O(log n) = 17 비교/100k)
2. 배치 처리: 1000개씩 INSERT
3. 캐싱: L1 메모리 1000개 (LRU)
4. 연결풀: SQLite 최대 5개 동시 연결
```

### **보안**

```
1. 바코드 정규화: 공백/특수문자 제거
2. SQL 인젝션: Parameterized queries 사용
3. 데이터 유효성: 길이 및 타입 검증
```

---

## ✅ 체크리스트

```
□ Excel 파일을 CSV로 변환
□ 한국 상품 정규화 (중복 제거, 카테고리 정리)
□ SQL 테이블 생성
□ 임포트 스크립트 작성 및 테스트
□ GlobalProductService 구현
□ GlobalProduct 모델 정의
□ wms_pda_quick_input_screen 수정
□ DB 마이그레이션 코드 작성
□ 단위 테스트
□ 통합 테스트 (PDA 스캔)
□ 성능 테스트
□ UI/UX 리뷰
□ 배포
```

