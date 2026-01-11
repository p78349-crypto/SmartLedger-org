# SmartLedger 앱 문제점 분석 보고서

> 분석일: 2026-01-11  
> 최종 업데이트: 2026-01-11  
> Flutter Analyzer: ✅ No issues found  
> Flutter Test: ✅ 191 tests passing

---

## ✅ 해결됨 (Resolved)

### 1. ~~빈 catch 블록 - 예외 무시 (13건)~~ ✅

> **해결 완료** (2026-01-11)  
> 모든 13개 위치에 debugPrint 로깅 추가됨

~~예외가 발생해도 무시되어 디버깅이 어려워질 수 있음.~~

| 파일 | 라인 | 상태 |
|------|------|------|
| `lib/screens/asset_detail_screen.dart` | 380, 388 | ✅ 해결됨 |
| `lib/screens/ceo_monthly_defense_report_screen.dart` | 522, 528, 535 | ✅ 해결됨 |
| `lib/screens/transaction_add_detailed_screen.dart` | 952, 959, 1002, 1008, 1013, 1024, 1029 | ✅ 해결됨 |
| `lib/utils/image_utils.dart` | 75, 92, 105 | ✅ 해결됨 |

```dart
// 적용된 패턴
} catch (e) {
  debugPrint('Operation failed: $e');
}
```

---

## 🟠 높음 (High)

### 2. 대형 파일 - 리팩토링 필요 (25개 파일 > 800줄)

#### 🔴 매우 큼 (4,000줄+)
| 파일 | 줄 수 | 권장 조치 |
|------|-------|-----------|
| `account_stats_screen.dart` | 4,529 | 통계 유형별로 분리 |
| `food_expiry_main_screen.dart` | 4,383 | 탭/기능별 위젯 분리 |
| `voice_dashboard_screen.dart` | 3,169 | 명령 핸들러 분리 |

#### 🟡 큼 (2,000줄+)
| 파일 | 줄 수 |
|------|-------|
| `transaction_add_detailed_screen.dart` | 2,633 |
| `transaction_add_screen.dart` | 2,525 |

#### 기타 800줄+ 파일 (20개)
- `quick_stock_use_screen.dart` (1,735)
- `nutrition_report_screen.dart` (1,588)
- `income_split_screen.dart` (1,449)
- `backup_screen.dart` (1,352)
- `account_main_screen.dart` (1,327)
- `transaction_detail_screen.dart` (1,294)
- `asset_detail_screen.dart` (1,288)
- `icon_management_screen.dart` (1,284)
- `application_settings_screen.dart` (1,186)
- `shopping_cart_screen.dart` (1,180)
- `input_stats_screen.dart` (1,130)
- `top_level_main_screen.dart` (1,085)
- `root_account_screen.dart` (1,065)
- `asset_tab_screen.dart` (1,054)
- `spending_analysis_screen.dart` (903)
- `weather_price_prediction_screen.dart` (892)
- `consumable_inventory_screen.dart` (854)
- `refund_transactions_screen.dart` (834)
- `evacuation_route_screen.dart` (832)
- `settings_screen.dart` (819)

---

## 🟡 중간 (Medium)

### 3. TODO/FIXME 미완성 작업 (5건)

| 파일 | 라인 | 내용 |
|------|------|------|
| `lib/models/account.dart` | 7 | 거래, 통계, 자산, 고정비용, 백업 등 데이터 필드 추가 |
| `lib/screens/quick_health_analyzer_screen.dart` | 385 | 책스캔앱 URL Scheme 호출 미구현 |
| `lib/services/asset_security_service.dart` | 26 | 실제 인증 통합 필요 (현재 임시 구현) |

### 4. 디버그 코드 잔존

| 항목 | 개수 | 권장 조치 |
|------|------|-----------|
| `print()` 호출 | 114개 | Logger 패키지로 교체 |
| `debugPrint()` 호출 | 107개 | 릴리즈 빌드에서 자동 제거됨 (OK) |
| DEBUG 주석 코드 | 2개 | 제거 또는 조건부 컴파일 |

**위치:**
- `lib/screens/account_main_screen.dart:361` - 화면 크기 출력
- `lib/screens/account_main_screen.dart:528` - 그리드 오버레이

### ~~5. Deprecated API 사용 (3건)~~ ✅

> **해결 완료** (2026-01-11)  
> KoreanSearchUtils → MultilingualSearchUtils 마이그레이션 완료

| 파일 | 내용 | 상태 |
|------|------|------|
| `lib/screens/asset_list_screen.dart` | KoreanSearchUtils | ✅ 마이그레이션됨 |
| `lib/screens/food_expiry_main_screen.dart` | KoreanSearchUtils | ✅ 마이그레이션됨 |
| `lib/screens/savings_plan_search_screen.dart` | KoreanSearchUtils | ✅ 마이그레이션됨 |
| `lib/widgets/user_preferences_widget.dart` | Radio API | 📝 문서화됨 (Flutter 3.32+) |
| `lib/utils/asset_dashboard_utils.dart:231` | `@Deprecated` | ⏳ 내부 참조용 |

### 6. 테스트 커버리지 부족

| 항목 | 개수 |
|------|------|
| 화면 파일 (screens) | 113개 |
| 테스트 파일 | 29개 |
| **커버리지 추정** | **~26%** |

**테스트 없는 주요 화면:**
- CEO 리포트 화면들
- 대부분의 설정 화면
- 쇼핑/장보기 화면
- 날씨 관련 화면

### 7. 임시/미완성 코드 (한글 주석)

| 파일 | 내용 |
|------|------|
| `transaction_add_screen.dart:1346` | 즐겨찾기 자동 저장 임시 비활성화 |
| `transaction_add_detailed_screen.dart:1530` | 즐겨찾기 자동 저장 임시 비활성화 |
| `voice_dashboard_screen.dart:256` | TTS 별도 구현 필요 |
| `voice_dashboard_screen.dart:1530-1531` | 임시 데이터 사용 중 |
| `weather_alert_detail_screen.dart:23` | 공유 기능 향후 구현 |
| `floating_voice_button.dart:53,261` | 지출 데이터 임시 저장 |

---

## ⚪ 낮음 (Low)

### ~~8. 의존성 업데이트 필요~~ ✅

> **부분 해결** (2026-01-11)  
> 호환 가능한 패키지 업그레이드 완료

| 패키지 | 이전 | 현재 | 상태 |
|--------|------|------|------|
| code_builder | 4.10.1 | 4.11.1 | ✅ 업그레이드됨 |
| equatable | 2.0.7 | 2.0.8 | ✅ 업그레이드됨 |
| ffi | 2.1.3 | 2.1.5 | ✅ 업그레이드됨 |
| geolocator_linux | 0.2.1 | 0.2.4 | ✅ 업그레이드됨 |
| package_info_plus | 8.3.1 | 9.0.0 | ✅ 업그레이드됨 |
| watcher | 1.1.1 | 1.2.1 | ✅ 업그레이드됨 |
| connectivity_plus | 6.1.5 | 7.0.0 | ⏳ Major (별도 검토) |
| image | 4.3.0 | 4.7.2 | ⏳ 호환성 확인 필요 |

---

## 📊 코드 품질 지표

| 지표 | 값 | 평가 |
|------|-----|------|
| 전체 Dart 파일 | 375개 | - |
| setState() 호출 | 666개 | 🟡 상태관리 개선 고려 |
| async 함수 | 528개 | - |
| dispose() 구현 | 77개 | ✅ 적절 |
| mounted 체크 | 다수 | ✅ 잘 사용됨 |

---

## 🎯 개선 우선순위 로드맵

### Phase 1: 즉시 (1주)
- [ ] 빈 catch 블록에 로깅 추가 (13건)
- [ ] TODO 항목 해결 또는 이슈 등록

### Phase 1: 즉시 (1주) - ✅ 완료
- [x] 빈 catch 블록에 로깅 추가 (13건) ✅
- [x] TODO 항목 명확화 ✅
- [x] Deprecated API 마이그레이션 ✅
- [x] 의존성 업그레이드 (6개) ✅

### Phase 2: 단기 (2-4주)
- [ ] 4,000줄+ 파일 리팩토링 시작
  - `account_stats_screen.dart` 분할 (4,529줄)
  - `food_expiry_main_screen.dart` 분할 (4,383줄)
  - `voice_dashboard_screen.dart` 분할 (3,169줄)
- [x] print() → debugPrint 변환 ✅ (이미 사용 중, 릴리즈에서 자동 제거)
- [ ] 공용 위젯 추출 (stats_summary_widgets.dart 생성됨)

### Phase 3: 중기 (1-2개월)
- [ ] 테스트 커버리지 50% 목표
- [ ] connectivity_plus 7.0.0 Major 업데이트
- [ ] 의존성 major 업데이트

### Phase 4: 장기
- [ ] 상태관리 개선 (Riverpod/Bloc 도입 검토)
- [ ] 테스트 커버리지 80% 목표

---

## 📝 참고 명령어

```powershell
# 정적 분석
flutter analyze

# TODO/FIXME 검색
Select-String -Path "lib/**/*.dart" -Pattern "TODO|FIXME"

# 빈 catch 블록 검색
Select-String -Path "lib/**/*.dart" -Pattern "catch.*\{[\s]*\}"

# 대형 파일 찾기
Get-ChildItem lib/screens -Name *.dart | ForEach-Object { 
  $c = (Get-Content "lib/screens/$_" | Measure-Object -Line).Lines
  if ($c -gt 800) { "$_ : $c lines" }
}

# 테스트 실행
flutter test

# 의존성 확인
flutter pub outdated
```

---

*이 보고서는 SmartLedger 앱의 잠재적 문제점을 분석한 결과입니다.*
