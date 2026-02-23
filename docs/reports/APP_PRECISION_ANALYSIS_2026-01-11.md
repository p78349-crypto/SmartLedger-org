# SmartLedger 앱 정밀 분석 보고서

> 생성일: 2026-01-11  
> 분석 대상: lib/ 폴더 전체 (375개 Dart 파일)

---

## 📊 전체 구조 요약

| 폴더 | 파일 수 | 설명 |
|------|---------|------|
| **utils** | 114 | 유틸리티/헬퍼 함수 |
| **screens** | 113 | UI 화면 |
| **services** | 66 | 비즈니스 로직/백엔드 서비스 |
| **widgets** | 33 | 재사용 가능 UI 컴포넌트 |
| **models** | 21 | 데이터 모델 |
| **theme** | 9 | 테마/스타일 설정 |
| **navigation** | 6 | 라우팅/딥링크 |
| **firebase** | 5 | Firebase 연동 |
| **database** | 3 | 로컬 DB 관리 |
| **repositories** | 3 | 데이터 저장소 |
| **mixins** | 1 | 믹스인 |

---

## 🏠 핵심 기능 카테고리

### 1. 💰 가계부/거래 관리
| 화면 | 파일 | 기능 |
|------|------|------|
| 계정 메인 | `account_main_screen.dart` | 메인 대시보드, 아이콘 그리드 |
| 계정 홈 | `account_home_screen.dart` | 계정별 홈 화면 |
| 거래 추가 | `transaction_add_screen.dart` | 수입/지출 입력 |
| 상세 지출입력 | `transaction_add_detailed_screen.dart` | 상세 지출입력 |
| 거래 상세 | `transaction_detail_screen.dart` | 거래 내역 상세 보기 |
| 일별 거래 | `daily_transactions_screen.dart` | 일별 거래 목록 |
| 환불 거래 | `refund_transactions_screen.dart` | 환불 내역 관리 |
| 간편 지출 | `quick_simple_expense_input_screen.dart` | 빠른 지출 입력 |

**관련 서비스:**
- `transaction_service.dart` - 거래 CRUD
- `transaction_db_store.dart` - 거래 DB 저장
- `transaction_fts_index_service.dart` - 전문 검색 인덱싱
- `recent_input_service.dart` - 최근 입력 기록

**관련 유틸:**
- `transaction_utils.dart` - 거래 헬퍼
- `refund_utils.dart` - 환불 처리
- `currency_formatter.dart` - 통화 포맷팅

---

### 2. 📈 자산 관리
| 화면 | 파일 | 기능 |
|------|------|------|
| 자산 대시보드 | `asset_dashboard_screen.dart` | 자산 현황 대시보드 |
| 자산 목록 | `asset_list_screen.dart` | 전체 자산 목록 |
| 자산 상세 | `asset_detail_screen.dart` | 개별 자산 상세 |
| 자산 입력 | `asset_input_screen.dart` | 자산 등록 |
| 자산 배분 | `asset_allocation_screen.dart` | 자산 배분 분석 |
| 자산 관리 | `asset_management_screen.dart` | 자산 편집/삭제 |

**관련 서비스:**
- `asset_service.dart` - 자산 CRUD
- `asset_move_service.dart` - 자산 이동
- `asset_security_service.dart` - 자산 보안 (잠금/해제)

**관련 유틸:**
- `asset_dashboard_utils.dart` - 대시보드 계산
- `asset_flow_stats.dart` - 자산 흐름 통계
- `asset_icon_utils.dart` - 자산 아이콘 처리
- `profit_loss_calculator.dart` - 손익 계산

---

### 3. 📊 통계/분석
| 화면 | 파일 | 기능 |
|------|------|------|
| 계정 통계 | `account_stats_screen.dart` | 계정별 통계 |
| 월별 통계 | `monthly_stats_screen.dart` | 월간 통계 |
| 기간 통계 | `period_stats_screen.dart` | 기간별 통계 |
| 기간 상세 | `period_detail_stats_screen.dart` | 기간 상세 분석 |
| 카테고리 통계 | `category_stats_screen.dart` | 카테고리별 분석 |
| 지출 분석 | `spending_analysis_screen.dart` | 지출 패턴 분석 |
| 차트 상세 | `chart_detail_screen.dart` | 차트 드릴다운 |
| 메모 통계 | `memo_stats_screen.dart` | 메모 기반 분석 |
| 포인트 동기부여 | `points_motivation_stats_screen.dart` | 포인트 통계 |

**관련 유틸:**
- `stats_calculator.dart` - 통계 계산 엔진
- `stats_view_utils.dart` - 통계 뷰 헬퍼
- `chart_utils.dart` - 차트 생성
- `chart_colors.dart` - 차트 색상
- `category_analysis.dart` - 카테고리 분석

---

### 4. 🎯 CEO 리포트 (신규 기능)
| 화면 | 파일 | 기능 |
|------|------|------|
| CEO 대시보드 | `ceo_assistant_dashboard.dart` | CEO급 분석 허브 |
| 월간 방어 보고서 | `ceo_monthly_defense_report_screen.dart` | 월간 자산 방어 전투 보고서 |
| 예외 상세 | `ceo_exception_details_screen.dart` | 이상 지출 상세 |
| 회복 계획 | `ceo_recovery_plan_screen.dart` | 자산 회복 계획 |
| ROI 상세 | `ceo_roi_detail_screen.dart` | 투자 수익률 분석 |
| 월간 손익 | `monthly_profit_report_screen.dart` | 월간 손익 보고서 |

**관련 서비스:**
- `policy_service.dart` - 정책 관리
- `privacy_service.dart` - 개인정보 보호
- `smart_consuming_service.dart` - 스마트 소비 분석

**관련 유틸:**
- `roi_utils.dart` - ROI 계산
- `misc_spending_utils.dart` - 기타 지출 분석
- `category_icon_map.dart` - 카테고리 아이콘 매핑

---

### 5. 💵 예산/고정비용
| 화면 | 파일 | 기능 |
|------|------|------|
| 예산 현황 | `budget_status_screen.dart` | 예산 대비 실적 |
| 고정비 탭 | `fixed_cost_tab_screen.dart` | 고정비용 관리 |
| 고정비 입력 | `fixed_cost_input_screen.dart` | 고정비 등록 |
| 고정비 통계 | `fixed_cost_stats_screen.dart` | 고정비 분석 |
| 월말 이월 | `month_end_carryover_screen.dart` | 월말 잔액 이월 |

**관련 서비스:**
- `budget_service.dart` - 예산 관리
- `fixed_cost_service.dart` - 고정비 CRUD
- `fixed_cost_auto_record_service.dart` - 고정비 자동 기록

---

### 6. 💹 저축/투자
| 화면 | 파일 | 기능 |
|------|------|------|
| 저축 계획 목록 | `savings_plan_list_screen.dart` | 저축 계획 관리 |
| 저축 계획 폼 | `savings_plan_form_screen.dart` | 저축 계획 등록 |
| 저축 검색 | `savings_plan_search_screen.dart` | 저축 계획 검색 |
| 저축 통계 | `savings_statistics_screen.dart` | 저축 현황 분석 |
| 비상금 | `emergency_fund_screen.dart` | 비상금 관리 |
| 비상금 목록 | `emergency_fund_list_screen.dart` | 비상금 내역 |
| 1억 프로젝트 | `one_hundred_million_project_screen.dart` | 1억 모으기 프로젝트 |
| 소액 저축 넛지 | `micro_savings_nudge_screen.dart` | 소액 저축 동기부여 |

**관련 서비스:**
- `savings_plan_service.dart` - 저축 계획 관리
- `savings_statistics_service.dart` - 저축 통계
- `emergency_fund_service.dart` - 비상금 관리

**관련 유틸:**
- `savings_statistics_utils.dart` - 저축 통계 계산
- `saving_tips_utils.dart` - 저축 팁 제공

---

### 7. 🛒 쇼핑/장보기
| 화면 | 파일 | 기능 |
|------|------|------|
| 쇼핑 목록 | `shopping_list_screen.dart` | 장보기 목록 |
| 쇼핑 카트 | `shopping_cart_screen.dart` | 장바구니 |
| 쇼핑 가이드 | `shopping_guide_screen.dart` | 쇼핑 가이드 |
| 최저가 월 | `shopping_cheapest_month_screen.dart` | 월별 최저가 분석 |
| 포인트 입력 | `shopping_points_input_screen.dart` | 포인트 사용 기록 |
| 매장 상품 통계 | `store_product_stats_screen.dart` | 매장별 상품 분석 |
| 매장 병합 | `store_merge_screen.dart` | 매장 데이터 병합 |

**관련 서비스:**
- `store_layout_service.dart` - 매장 레이아웃
- `store_alias_service.dart` - 매장 별칭 관리
- `product_location_service.dart` - 상품 위치

**관련 유틸:**
- `shopping_list_generator.dart` - 장보기 목록 생성
- `shopping_cart_bulk_ledger_utils.dart` - 일괄 가계부 연동
- `shopping_prep_utils.dart` - 쇼핑 준비
- `shopping_price_seasonality_utils.dart` - 계절별 가격 분석
- `shopping_repurchase_utils.dart` - 재구매 분석

---

### 8. 🍳 식품/요리/유통기한
| 화면 | 파일 | 기능 |
|------|------|------|
| 식품 유통기한 | `food_expiry_main_screen.dart` | 유통기한 관리 메인 |
| 요리 시작 | `food_cooking_start_screen.dart` | 요리 시작 |
| 요리 사용 기록 | `cooking_usage_history_screen.dart` | 요리 이력 |
| 재료 검색 | `ingredient_search_list_screen.dart` | 재료 검색 |
| 재고 빠른 사용 | `quick_stock_use_screen.dart` | 빠른 재고 소진 |
| 영양 보고서 | `nutrition_report_screen.dart` | 영양 분석 |
| 식사 비용 실험 | `meal_cost_experiment_screen.dart` | 식사 비용 분석 |
| 건강 분석기 | `quick_health_analyzer_screen.dart` | 건강 점수 분석 |

**관련 서비스:**
- `food_expiry_service.dart` - 유통기한 관리
- `food_expiry_notification_service.dart` - 유통기한 알림
- `food_expiry_prediction_engine.dart` - 소비 예측
- `recipe_service.dart` - 레시피 관리
- `recipe_learning_service.dart` - 레시피 학습
- `recipe_knowledge_service.dart` - 레시피 지식베이스
- `health_guardrail_service.dart` - 건강 가드레일

**관련 유틸:**
- `expiring_ingredients_utils.dart` - 임박 재료 분석
- `ingredient_parsing_utils.dart` - 재료 파싱
- `ingredient_health_score_utils.dart` - 건강 점수
- `nutrition_food_knowledge.dart` - 영양 지식
- `nutrition_report_utils.dart` - 영양 보고서
- `daily_recipe_recommendation_utils.dart` - 일일 레시피 추천
- `recipe_recommendation_utils.dart` - 레시피 추천
- `meal_plan_generator_utils.dart` - 식단 생성

---

### 9. 🏠 가정용품/소모품
| 화면 | 파일 | 기능 |
|------|------|------|
| 가정용품 | `household_consumables_screen.dart` | 가정용품 관리 |
| 소모품 재고 | `consumable_inventory_screen.dart` | 소모품 재고 |

**관련 서비스:**
- `consumable_inventory_service.dart` - 재고 관리
- `replacement_cycle_notification_service.dart` - 교체 주기 알림
- `stock_depletion_notification_service.dart` - 재고 소진 알림
- `activity_household_estimator_service.dart` - 사용량 추정

**관련 유틸:**
- `household_consumables_utils.dart` - 가정용품 헬퍼

---

### 10. 🎤 음성 어시스턴트
| 화면 | 파일 | 기능 |
|------|------|------|
| 음성 대시보드 | `voice_dashboard_screen.dart` | 음성 명령 허브 |
| 음성 설정 | `voice_assistant_settings_screen.dart` | 음성 설정 |
| 음성 단축키 | `voice_shortcuts_screen.dart` | 음성 단축 명령 |

**관련 서비스:**
- `voice_assistant_settings.dart` - 음성 설정 관리
- `voice_assistant_analytics.dart` - 음성 사용 분석
- `voice_input_bridge.dart` - 음성 입력 브릿지
- `assistant_launcher.dart` - 어시스턴트 실행
- `bixby_deeplink_handler.dart` - Bixby 딥링크

**관련 위젯:**
- `floating_voice_button.dart` - 플로팅 음성 버튼

---

### 11. 🌦️ 날씨 연동
| 화면 | 파일 | 기능 |
|------|------|------|
| 날씨 알림 상세 | `weather_alert_detail_screen.dart` | 날씨 알림 상세 |
| 날씨 가격 예측 | `weather_price_prediction_screen.dart` | 날씨 기반 가격 예측 |
| 날씨 수동 입력 | `weather_manual_input_screen.dart` | 날씨 수동 기록 |

**관련 유틸:**
- `weather_utils.dart` - 날씨 헬퍼
- `weather_price_sensitivity.dart` - 날씨-가격 민감도
- `weather_price_prediction_utils.dart` - 가격 예측
- `weather_capture_utils.dart` - 날씨 캡처

**관련 위젯:**
- `weather_alert_widget.dart` - 날씨 알림 위젯

---

### 12. 🚨 비상/대피
| 화면 | 파일 | 기능 |
|------|------|------|
| 비상 화면 | `emergency_screen.dart` | 비상 상황 대응 |
| 대피 경로 | `evacuation_route_screen.dart` | 대피 경로 안내 |

**관련 서비스:**
- `device_location_service.dart` - 위치 서비스
- `evacuation_workflow_monitor.dart` - 대피 워크플로우

**관련 유틸:**
- `evacuation_route_utils.dart` - 대피 경로 계산

**관련 위젯:**
- `emergency_button.dart` - 비상 버튼

---

### 13. 🔗 딥링크/네비게이션
| 파일 | 기능 |
|------|------|
| `app_router.dart` | 앱 라우터 (GoRouter) |
| `app_routes.dart` | 라우트 정의 |
| `deep_link_handler.dart` | 딥링크 처리 |
| `route_param_validator.dart` | 라우트 파라미터 검증 |

**관련 서비스:**
- `deep_link_service.dart` - 딥링크 서비스
- `deep_link_diagnostics.dart` - 딥링크 진단

---

### 14. ⚙️ 설정/관리
| 화면 | 파일 | 기능 |
|------|------|------|
| 설정 메인 | `settings_screen.dart` | 앱 설정 |
| 앱 설정 | `application_settings_screen.dart` | 상세 앱 설정 |
| 테마 설정 | `theme_settings_screen.dart` | 테마 변경 |
| 디스플레이 설정 | `display_settings_screen.dart` | 화면 설정 |
| 배경 설정 | `background_settings_screen.dart` | 배경화면 설정 |
| 언어 설정 | `language_settings_screen.dart` | 언어 변경 |
| 통화 설정 | `currency_settings_screen.dart` | 통화 설정 |
| 백업 | `backup_screen.dart` | 백업/복원 |
| 개인정보 정책 | `privacy_policy_screen.dart` | 개인정보 처리방침 |
| 권한 게이트 | `permission_gate_screen.dart` | 권한 요청 |
| 아이콘 관리 | `icon_management_screen.dart` | 아이콘 커스터마이징 |
| 휴지통 | `trash_screen.dart` | 삭제된 항목 관리 |

**관련 서비스:**
- `theme_service.dart` - 테마 관리
- `backup_service.dart` - 백업 서비스
- `user_pref_service.dart` - 사용자 설정
- `secure_storage_service.dart` - 보안 저장소
- `auth_service.dart` - 인증
- `notification_service.dart` - 알림 관리
- `trash_service.dart` - 휴지통

---

### 15. 🔐 보안/인증
| 화면 | 파일 | 기능 |
|------|------|------|
| 비밀번호 확인 | `_verify_current_user_password_dialog.dart` | 비밀번호 검증 |
| PIN 확인 | `_verify_current_user_pin_dialog.dart` | PIN 검증 |

**관련 서비스:**
- `user_password_service.dart` - 비밀번호 관리
- `user_pin_service.dart` - PIN 관리
- `root_pin_service.dart` - 루트 PIN

**관련 위젯:**
- `root_auth_gate.dart` - 루트 인증 게이트
- `user_account_auth_gate.dart` - 사용자 계정 인증
- `user_pin_gate.dart` - PIN 게이트
- `asset_route_auth_gate.dart` - 자산 라우트 인증

**관련 유틸:**
- `backup_crypto.dart` - 백업 암호화

---

### 16. 🔍 검색
**관련 서비스:**
- `search_service.dart` - 통합 검색

**관련 유틸:**
- `korean_search_utils.dart` - 한국어 검색 (초성 검색 포함)
- `memo_search_utils.dart` - 메모 검색

**관련 위젯:**
- `search_bar_widget.dart` - 검색 바

---

### 17. 📱 루트 계정 (멀티 계정)
| 화면 | 파일 | 기능 |
|------|------|------|
| 루트 화면 | `root_account_screen.dart` | 루트 계정 메인 |
| 루트 관리 | `root_account_manage_screen.dart` | 루트 계정 관리 |
| 루트 검색 | `root_search_screen.dart` | 루트 레벨 검색 |
| 루트 거래 관리 | `root_transaction_manager_screen.dart` | 루트 거래 관리 |
| 루트 월말 | `root_month_end_screen.dart` | 루트 월말 정산 |

**관련 서비스:**
- `root_overview_service.dart` - 루트 개요
- `account_service.dart` - 계정 관리
- `account_option_service.dart` - 계정 옵션

---

## 🧩 데이터 모델 (21개)

| 모델 | 파일 | 용도 |
|------|------|------|
| Account | `account.dart` | 사용자 계정 |
| Asset | `asset.dart` | 자산 |
| AssetMove | `asset_move.dart` | 자산 이동 기록 |
| Transaction | `transaction.dart` | 거래 |
| FixedCost | `fixed_cost.dart` | 고정비용 |
| SavingsPlan | `savings_plan.dart` | 저축 계획 |
| EmergencyTransaction | `emergency_transaction.dart` | 비상금 거래 |
| FoodExpiryItem | `food_expiry_item.dart` | 식품 유통기한 |
| Recipe | `recipe.dart` | 레시피 |
| CookingUsageLog | `cooking_usage_log.dart` | 요리 사용 기록 |
| ConsumableInventoryItem | `consumable_inventory_item.dart` | 소모품 재고 |
| ShoppingCartItem | `shopping_cart_item.dart` | 장바구니 항목 |
| ShoppingCartHistoryEntry | `shopping_cart_history_entry.dart` | 장바구니 이력 |
| ShoppingTemplateItem | `shopping_template_item.dart` | 쇼핑 템플릿 |
| ShoppingPointsDraftEntry | `shopping_points_draft_entry.dart` | 포인트 임시 저장 |
| VisitPriceEntry | `visit_price_entry.dart` | 방문 가격 기록 |
| WeatherSnapshot | `weather_snapshot.dart` | 날씨 스냅샷 |
| CategoryHint | `category_hint.dart` | 카테고리 힌트 |
| SearchFilter | `search_filter.dart` | 검색 필터 |
| TrashEntry | `trash_entry.dart` | 휴지통 항목 |
| MainPageConfig | `main_page_config.dart` | 메인 페이지 설정 |

---

## 🎨 위젯 컴포넌트 (33개)

| 위젯 | 용도 |
|------|------|
| `floating_voice_button.dart` | 플로팅 음성 버튼 |
| `emergency_button.dart` | 비상 버튼 |
| `weather_alert_widget.dart` | 날씨 알림 |
| `daily_recipe_recommendation_widget.dart` | 일일 레시피 추천 |
| `recipe_health_score_widget.dart` | 레시피 건강 점수 |
| `ingredient_health_analyzer_dialog.dart` | 재료 건강 분석 |
| `ingredients_recommendation_widget.dart` | 재료 추천 |
| `meal_plan_widget.dart` | 식단 계획 |
| `category_pie_chart.dart` | 카테고리 파이 차트 |
| `cost_analysis_widget.dart` | 비용 분석 |
| `root_summary_card.dart` | 루트 요약 카드 |
| `root_transaction_list.dart` | 루트 거래 목록 |
| `search_bar_widget.dart` | 검색 바 |
| `smart_input_field.dart` | 스마트 입력 필드 |
| `animated_list_item.dart` | 애니메이션 리스트 |
| `asset_move_dialog.dart` | 자산 이동 다이얼로그 |
| `emergency_fund_transfer_dialog.dart` | 비상금 이체 |
| `investment_recommendation_dialog.dart` | 투자 추천 |
| `month_end_carryover_dialog.dart` | 월말 이월 |
| `icon_actions_menu.dart` | 아이콘 액션 메뉴 |
| `background_widget.dart` | 배경 위젯 |
| `special_backgrounds.dart` | 특수 배경 |
| `in_app_screen_saver.dart` | 인앱 스크린세이버 |
| `theme_preview_widget.dart` | 테마 프리뷰 |
| `user_preferences_widget.dart` | 사용자 설정 |
| `samsung_quick_actions_view.dart` | 삼성 퀵 액션 |
| `zero_quick_buttons.dart` | 제로 퀵 버튼 |
| `state_placeholders.dart` | 상태 플레이스홀더 |
| 인증 게이트 (4개) | 다양한 인증 게이트 |

---

## 🔧 핵심 유틸리티 (주요 114개 중)

### 검색/언어
- `korean_search_utils.dart` - 한국어 초성 검색, 일본어/영어 지원
- `memo_search_utils.dart` - 메모 검색
- `localization_utils.dart` - 다국어 지원

### 금융 계산
- `profit_loss_calculator.dart` - 손익 계산
- `stats_calculator.dart` - 통계 계산
- `roi_utils.dart` - ROI 계산
- `currency_formatter.dart` - 통화 포맷

### 차트/시각화
- `chart_utils.dart` - 차트 생성
- `chart_colors.dart` - 차트 색상
- `chart_display_utils.dart` - 차트 표시

### 카테고리/분류
- `category_definitions.dart` - 카테고리 정의
- `detailed_category_definitions.dart` - 상세 카테고리
- `category_analysis.dart` - 카테고리 분석
- `shopping_category_utils.dart` - 쇼핑 카테고리

### 날짜/시간
- `date_formats.dart` - 날짜 포맷
- `date_formatter.dart` - 날짜 포맷터
- `date_parser.dart` - 날짜 파서
- `period_utils.dart` - 기간 계산

### 성능/캐시
- `cache_utils.dart` - 캐시 관리
- `debounce_utils.dart` - 디바운스

---

## 📦 외부 연동

### Firebase (5개 파일)
- 인증, Firestore, 클라우드 기능 연동

### Bixby Capsule
- `bixby-capsule/` 폴더에 삼성 Bixby 연동 코드

### 딥링크
- 앱 내/외부 딥링크 처리
- Bixby 딥링크 지원

---

## 📱 테스트 현황

| 폴더 | 파일 수 | 설명 |
|------|---------|------|
| test/screens | 다수 | 화면 위젯 테스트 |
| test/utils | 다수 | 유틸리티 단위 테스트 |
| test/services | 1+ | 서비스 테스트 |
| test/features | 1+ | 기능 통합 테스트 |
| test/integration | 1+ | 통합 테스트 |

**최근 테스트 결과:** ✅ 191개 테스트 통과

---

## 🚀 최근 추가된 기능 (2026-01-11)

1. **CEO 월간 방어 보고서** - PDF/CSV 내보내기, TTS, 공유
2. **스마트 소비 서비스** - 소비 패턴 분석
3. **환불 거래 화면 복원** - 환불 내역 관리
4. **딥링크 핸들러 개선** - 방문 가격 플로우
5. **한국어 PDF 폰트** - NotoSansKR 폰트 추가

---

## 📋 파일 총계

- **전체 Dart 파일:** 375개
- **화면:** 113개
- **서비스:** 66개
- **유틸리티:** 114개
- **위젯:** 33개
- **모델:** 21개
- **기타:** 28개

---

*이 문서는 SmartLedger 앱의 전체 기능을 분석한 보고서입니다.*
