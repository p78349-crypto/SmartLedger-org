# 백업 완료 후 작업 계획 (Post-Backup Tasks)

**생성일**: 2025-12-06  
**상태**: 백업 진행 중

---

## 📋 백업 완료 확인 체크리스트

### 백업 검증
- [ ] 백업 폴더 생성 확인: `C:\Users\plain\vccode1_backups\vccode1_backup_*`
- [ ] 백업 크기 확인: 20-50 MB (정상 범위)
- [ ] BACKUP_INFO.txt 파일 존재 확인
- [ ] lib/ 폴더 포함 확인
- [ ] pubspec.yaml 파일 포함 확인
- [ ] 모든 .md 문서 포함 확인

### 백업 안전성
- [ ] 외부 저장소에 복사 (USB 드라이브 또는 클라우드)
- [ ] 백업 파일 압축 (선택사항)
- [ ] 백업 복원 테스트 (선택사항)

---

## 🎯 우선순위 1: 리팩토링 작업

### 1단계: account_stats_screen.dart 리팩토링
**예상 시간**: 30-45분  
**우선순위**: 높음

#### 현재 상태 분석
```dart
// 현재 사용 중인 포맷터들 (32-38번 줄)
final NumberFormat _currencyFormat = NumberFormat('#,##0');
final NumberFormat _compactNumberFormat = NumberFormat.compact(locale: 'ko');
final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
final DateFormat _monthLabelFormat = DateFormat('yyyy년 M월');
final DateFormat _rangeMonthFormat = DateFormat('yyyy.MM');
final DateFormat _shortMonthFormat = DateFormat('M월');
final DateFormat _dayLabelFormat = DateFormat('M월 d일');
```

#### 리팩토링 계획
1. **import 문 수정**
   - `import 'package:intl/intl.dart';` 제거
   - `import '../utils/utils.dart';` 추가

2. **포맷터 변수 제거**
   - 7개의 NumberFormat/DateFormat 변수 제거
   - 사용처를 Utils 함수로 교체

3. **교체 패턴**
   ```dart
   // Before
   _currencyFormat.format(amount)
   
   // After
   CurrencyFormatter.format(amount)
   ```
   
   ```dart
   // Before
   _compactNumberFormat.format(amount)
   
   // After
   CurrencyFormatter.formatCompact(amount)
   ```
   
   ```dart
   // Before
   _dateFormat.format(date)
   
   // After
   DateFormatter.formatDate(date)
   ```

4. **예상 변경 위치**
   - 파일 크기: 2173 줄
   - 포맷터 사용 횟수: 약 28회
   - 변경 비율: ~2% (소규모 변경)

#### 작업 단계
1. [ ] Git 커밋 또는 백업 확인
2. [ ] account_stats_screen.dart 전체 읽기
3. [ ] import 문 수정
4. [ ] 포맷터 변수 제거
5. [ ] 모든 사용처 교체 (검색/치환 사용)
6. [ ] 빌드 테스트
7. [ ] 화면 동작 확인
8. [ ] Git 커밋

---

### 2단계: top_level_main_screen.dart 리팩토링
**예상 시간**: 20-30분  
**우선순위**: 높음

#### 작업 내용
- [ ] NumberFormat 사용처 파악
- [ ] DateFormat 사용처 파악
- [ ] Utils로 교체
- [ ] 테스트

---

### 3단계: root_account_screen.dart 리팩토링
**예상 시간**: 25-35분  
**우선순위**: 높음

#### 작업 내용
- [ ] NumberFormat 사용처 파악
- [ ] DateFormat 사용처 파악
- [ ] Utils로 교체
- [ ] 테스트

---

### 4단계: transaction_add_screen.dart 리팩토링
**예상 시간**: 15-20분  
**우선순위**: 높음

#### 작업 내용
- [ ] DateFormat 사용처 파악
- [ ] Utils로 교체
- [ ] 날짜 선택 기능 테스트

---

### 5단계: savings_plan_form_screen.dart 리팩토링
**예상 시간**: 15-20분  
**우선순위**: 높음

#### 작업 내용
- [ ] DateFormat 사용처 파악
- [ ] Utils로 교체
- [ ] 폼 기능 테스트

---

## 🎯 우선순위 2: 코드 품질 개선

### 에러 로깅 추가
**예상 시간**: 1-2시간

#### 대상 파일
- [ ] lib/services/account_service.dart
- [ ] lib/services/transaction_service.dart
- [ ] lib/services/asset_service.dart
- [ ] lib/services/fixed_cost_service.dart
- [ ] lib/services/backup_service.dart

#### 작업 내용
```dart
// Before
Account? getAccountByName(String name) {
  try {
    return _accounts.firstWhere((a) => a.name == name);
  } catch (_) {
    return null;
  }
}

// After
Account? getAccountByName(String name) {
  try {
    return _accounts.firstWhere((a) => a.name == name);
  } catch (e, stackTrace) {
    debugPrint('Error finding account "$name": $e');
    debugPrint('Stack trace: $stackTrace');
    return null;
  }
}
```

---

### 주석 추가
**예상 시간**: 2-3시간

#### 대상
- [ ] 복잡한 비즈니스 로직
- [ ] 공개 API 메서드
- [ ] 중요한 알고리즘

#### 예시
```dart
/// 계정별 거래 내역을 조회합니다.
/// 
/// [accountName]에 해당하는 모든 거래 내역을 반환합니다.
/// 계정이 존재하지 않으면 빈 리스트를 반환합니다.
/// 
/// Returns: 거래 내역 리스트 (읽기 전용)
List<Transaction> getTransactions(String accountName) {
  final list = _accountTransactions[accountName];
  if (list == null) {
    return const <Transaction>[];
  }
  return List.unmodifiable(list);
}
```

---

## 🎯 우선순위 3: 문서화

### API 문서 작성
**예상 시간**: 3-4시간

#### 작성할 문서
1. [ ] **SERVICE_API.md** - 서비스 레이어 API 문서
2. [ ] **MODEL_SCHEMA.md** - 데이터 모델 스키마
3. [ ] **WIDGET_GUIDE.md** - 재사용 위젯 가이드

---

## 🎯 우선순위 4: 테스트 코드

### 단위 테스트 작성
**예상 시간**: 8-10시간

#### 테스트 대상
1. [ ] AccountService
   - addAccount()
   - getAccountByName()
   - deleteAccount()

2. [ ] TransactionService
   - addTransaction()
   - updateTransaction()
   - deleteTransaction()

3. [ ] BackupService
   - exportAccountData()
   - importAccountData()

#### 테스트 파일 구조
```
test/
├── services/
│   ├── account_service_test.dart
│   ├── transaction_service_test.dart
│   └── backup_service_test.dart
├── models/
│   ├── account_test.dart
│   └── transaction_test.dart
└── widgets/
    └── root_summary_card_test.dart
```

---

## 📅 작업 일정

### 오늘 (2025-12-06)
- [x] 코드 점검 보고서 작성
- [x] 백업 스크립트 작성
- [x] 리팩토링 체크리스트 작성
- [ ] 백업 실행 및 검증
- [ ] account_stats_screen.dart 리팩토링 시작

### 이번 주 (2025-12-06 ~ 2025-12-13)
- [ ] 5개 파일 리팩토링 완료
- [ ] 에러 로깅 추가
- [ ] 주석 추가 (일부)

### 다음 주 (2025-12-13 ~ 2025-12-20)
- [ ] DialogUtils/SnackbarUtils 적용
- [ ] API 문서 작성
- [ ] 단위 테스트 시작

---

## 🔧 작업 도구

### Git 사용 (권장)
```bash
# 초기 설정
git init
git add .
git commit -m "Initial commit after code inspection"

# 리팩토링 전
git checkout -b refactor/account-stats-screen
git add lib/screens/account_stats_screen.dart
git commit -m "Refactor: Replace NumberFormat/DateFormat with Utils"

# 리팩토링 후
git checkout main
git merge refactor/account-stats-screen
```

### 검색/치환 패턴
```
찾기: _currencyFormat\.format\(([^)]+)\)
바꾸기: CurrencyFormatter.format($1)

찾기: _compactNumberFormat\.format\(([^)]+)\)
바꾸기: CurrencyFormatter.formatCompact($1)

찾기: _dateFormat\.format\(([^)]+)\)
바꾸기: DateFormatter.formatDate($1)
```

---

## 📊 진행 상황 추적

### 리팩토링 진행률
- 완료: 3/10 파일 (30%)
- 진행 중: 0/10 파일
- 대기: 7/10 파일 (70%)

### 코드 품질 개선
- 에러 로깅: 0%
- 주석: ~5%
- 테스트: 0%

---

## 🎯 성공 기준

### 리팩토링 완료 기준
- [ ] 모든 NumberFormat/DateFormat 제거
- [ ] import 'package:intl/intl.dart' 제거 (필요한 곳만 유지)
- [ ] 빌드 에러 0개
- [ ] 모든 화면 정상 작동
- [ ] 포맷 일관성 유지

### 코드 품질 기준
- [ ] 모든 try-catch에 로깅 추가
- [ ] 공개 API에 문서 주석 추가
- [ ] 주요 서비스 테스트 커버리지 50% 이상

---

## 📝 작업 로그

### 2025-12-06
- [x] 코드 점검 완료
- [x] 백업 스크립트 생성
- [x] 작업 계획 수립
- [ ] 백업 실행 대기 중

### 다음 작업
1. 백업 완료 확인
2. account_stats_screen.dart 리팩토링 시작
3. 진행 상황 업데이트

---

**작성일**: 2025-12-06  
**다음 업데이트**: 백업 완료 후