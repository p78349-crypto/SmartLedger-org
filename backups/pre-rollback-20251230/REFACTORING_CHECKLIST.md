# 리팩토링 체크리스트 (Refactoring Checklist)

**생성일**: 2025-12-06  
**기준 문서**: lib/utils/REFACTORING_GUIDE.md

---

## 📊 진행 상황 요약

### 전체 진행률
- **완료**: 3개 파일 (30%)
- **진행 중**: 0개 파일
- **대기 중**: 7개 파일 (70%)

### 우선순위별 현황
- **높음**: 5개 파일 대기
- **중간**: 다이얼로그/스낵바 유틸 적용

---

## ✅ 완료된 리팩토링

### 1. root_summary_card.dart
- [x] `NumberFormat('#,##0')` → `CurrencyFormatter.format()`
- [x] `formatSigned()` → `CurrencyFormatter.formatSigned()`
- [x] `formatOutflow()` → `CurrencyFormatter.formatOutflow()`
- **완료일**: [날짜 미기록]
- **검증**: ✅

### 2. account_home_screen.dart
- [x] `NumberFormat('#,##0')` → `CurrencyFormatter.format()`
- [x] `DateFormat('yyyy-MM-dd')` → `DateFormatter.formatDate()`
- [x] 모든 금액 포맷팅 통일
- **완료일**: [날짜 미기록]
- **검증**: ✅

### 3. trash_screen.dart (부분 완료)
- [x] `DateFormat('yyyy-MM-dd HH:mm')` → `DateFormatter.formatDateTime()`
- [ ] ScaffoldMessenger → SnackbarUtils (일부만 완료)
- **완료일**: [날짜 미기록]
- **검증**: ⚠️ 부분 완료

---

## 🔄 우선순위 높음 (High Priority)

### 1. account_stats_screen.dart
**예상 작업 시간**: 30-45분

#### 작업 내용
- [ ] `import 'package:intl/intl.dart';` 제거
- [ ] `import '../utils/utils.dart';` 추가
- [x] `NumberFormat('#,##0')` → `CurrencyFormatter.format()` (예상 10-15곳)
- [x] `NumberFormat.compact(locale: 'ko')` → `CurrencyFormatter.formatCompact()` (예상 5-8곳)
- [ ] `DateFormat('yyyy-MM-dd')` → `DateFormatter.formatDate()` (예상 3-5곳)
- [ ] `DateFormat('yyyy년 M월')` → `DateFormatter.formatYearMonth()` (예상 2-3곳)

#### 검증 항목
- [ ] 빌드 에러 없음
- [ ] 통계 화면 정상 표시
- [ ] 금액 포맷 일관성
- [ ] 날짜 포맷 일관성

#### 예상 변경 라인
```dart
// Before (예상 위치)
final formatter = NumberFormat('#,##0');
Text('${formatter.format(totalExpense)}원')

final compactFormatter = NumberFormat.compact(locale: 'ko');
Text(compactFormatter.format(amount))

final dateFormat = DateFormat('yyyy-MM-dd');
Text(dateFormat.format(date))

// After
import '../utils/utils.dart';

Text(CurrencyFormatter.format(totalExpense))
Text(CurrencyFormatter.formatCompact(amount))
Text(DateFormatter.formatDate(date))
```

---

### 2. top_level_main_screen.dart
**예상 작업 시간**: 20-30분

#### 작업 내용
- [ ] `import 'package:intl/intl.dart';` 제거
- [ ] `import '../utils/utils.dart';` 추가
- [ ] `NumberFormat('#,##0')` → `CurrencyFormatter.format()` (예상 8-12곳)
- [ ] `DateFormat('yyyy-MM-dd')` → `DateFormatter.formatDate()` (예상 2-4곳)

#### 검증 항목
- [ ] 빌드 에러 없음
- [ ] 메인 화면 정상 표시
- [ ] 요약 카드 정상 작동

---

### 3. root_account_screen.dart
**예상 작업 시간**: 25-35분

#### 작업 내용
- [ ] `import 'package:intl/intl.dart';` 제거
- [ ] `import '../utils/utils.dart';` 추가
- [ ] `NumberFormat('#,##0')` → `CurrencyFormatter.format()` (예상 10-15곳)
- [ ] `DateFormat('yyyy-MM-dd')` → `DateFormatter.formatDate()` (예상 3-5곳)

#### 검증 항목
- [ ] 빌드 에러 없음
- [ ] 계정 화면 정상 표시
- [ ] 거래 목록 정상 표시

---

### 4. transaction_add_screen.dart
**예상 작업 시간**: 15-20분

#### 작업 내용
- [ ] `import 'package:intl/intl.dart';` 제거
- [ ] `import '../utils/utils.dart';` 추가
- [ ] `DateFormat('yyyy-MM-dd')` → `DateFormatter.formatDate()` (예상 2-3곳)
- [ ] 날짜 선택기 포맷 통일

#### 검증 항목
- [ ] 빌드 에러 없음
- [ ] 거래 추가 화면 정상 작동
- [ ] 날짜 선택 정상 작동

---

### 5. savings_plan_form_screen.dart
**예상 작업 시간**: 15-20분

#### 작업 내용
- [ ] `import 'package:intl/intl.dart';` 제거
- [ ] `import '../utils/utils.dart';` 추가
- [ ] `DateFormat('yyyy-MM-dd')` → `DateFormatter.formatDate()` (예상 2-3곳)

#### 검증 항목
- [ ] 빌드 에러 없음
- [ ] 예금 계획 폼 정상 작동
- [ ] 날짜 선택 정상 작동

---

## 🔄 우선순위 중간 (Medium Priority)

### DialogUtils 활용

#### 대상 파일 (예상)
- [ ] account_home_screen.dart
- [ ] transaction_add_screen.dart
- [ ] asset_management_screen.dart
- [ ] fixed_cost_tab_screen.dart
- [ ] trash_screen.dart

#### 작업 내용
```dart
// Before
final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('삭제 확인'),
    content: Text('정말 삭제하시겠습니까?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text('취소'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text('삭제'),
      ),
    ],
  ),
);

// After
final confirmed = await DialogUtils.showDeleteConfirmDialog(
  context,
  itemName: '거래 내역',
);
```

---

### SnackbarUtils 활용

#### 대상 파일 (예상)
- [ ] account_home_screen.dart
- [ ] transaction_add_screen.dart
- [ ] asset_management_screen.dart
- [ ] fixed_cost_tab_screen.dart
- [x] trash_screen.dart (부분 완료)

#### 작업 내용
```dart
// Before
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('저장되었습니다')),
);

// After
SnackbarUtils.showSuccess(context, '저장되었습니다');
```

---

### Validators 활용

#### 대상 파일 (예상)
- [ ] transaction_add_screen.dart
- [ ] account_create_screen.dart
- [ ] savings_plan_form_screen.dart

#### 작업 내용
```dart
// Before
String? _validateAmount(String? value) {
  if (value == null || value.isEmpty) {
    return '금액을 입력하세요';
  }
  if (double.tryParse(value) == null) {
    return '올바른 금액을 입력하세요';
  }
  return null;
}

// After
validator: Validators.amount,
```

---

## 📝 리팩토링 프로세스

### 단계별 가이드

#### 1단계: 준비
- [ ] Git 커밋 또는 백업 생성
- [ ] 대상 파일 읽기
- [ ] 변경 범위 파악

#### 2단계: 리팩토링
- [ ] import 문 수정
- [ ] NumberFormat 교체
- [ ] DateFormat 교체
- [ ] Dialog/Snackbar 교체 (선택)

#### 3단계: 검증
- [ ] 빌드 에러 확인
- [ ] 화면 정상 작동 확인
- [ ] 포맷 일관성 확인

#### 4단계: 완료
- [ ] Git 커밋
- [ ] 체크리스트 업데이트
- [ ] 다음 파일로 이동

---

## 🎯 리팩토링 목표

### 단기 목표 (1주일)
- [ ] 우선순위 높음 5개 파일 완료
- [ ] 빌드 에러 0개
- [ ] 모든 화면 정상 작동

### 중기 목표 (2주일)
- [ ] DialogUtils 적용 완료
- [ ] SnackbarUtils 적용 완료
- [ ] Validators 적용 완료

### 장기 목표 (1개월)
- [ ] 모든 파일 리팩토링 완료
- [ ] 코드 리뷰 완료
- [ ] 문서 업데이트 완료

---

## 📊 예상 효과

### 코드 품질
- **중복 제거**: 9개 파일에서 NumberFormat 중복 제거
- **일관성 향상**: 모든 화면에서 동일한 포맷 사용
- **유지보수성**: 포맷 변경 시 한 곳만 수정

### 개발 생산성
- **개발 속도**: 새 기능 개발 시 Utils 바로 사용
- **버그 감소**: 일관된 포맷으로 버그 감소
- **가독성**: 의도가 명확한 함수명

---

## 🚨 주의사항

### 리팩토링 시 주의할 점
1. **한 번에 하나씩**: 파일 단위로 리팩토링
2. **테스트 필수**: 각 파일 리팩토링 후 테스트
3. **백업 필수**: 리팩토링 전 백업 또는 커밋
4. **점진적 적용**: 전체를 한 번에 수정하지 말 것

### 롤백 계획
```bash
# Git 사용 시
git checkout -- <파일명>

# 백업 사용 시
# 백업 파일에서 복원
```

---

## 📈 진행 상황 추적

### 주간 리포트 양식
```
주차: 2025-W49
완료: 2개 파일
진행 중: 1개 파일
대기: 4개 파일
이슈: 없음
다음 주 계획: account_stats_screen.dart 완료
```

---

## 📞 문의 및 지원

### 리팩토링 관련 질문
- Utils 사용법: lib/utils/utils_example.dart 참조
- 가이드라인: lib/utils/REFACTORING_GUIDE.md 참조

---

**마지막 업데이트**: 2025-12-06  
**다음 업데이트 예정**: 리팩토링 진행 시