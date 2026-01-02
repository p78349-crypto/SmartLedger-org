# 🎨 Material Design Icons 매핑 가이드

**작성일**: 2025년 12월 24일  
**목적**: 앱에서 사용되는 Material Design Icons 전체 목록 및 매핑

---

## 📋 목차

1. [거래 아이콘](#거래-아이콘)
2. [네비게이션 아이콘](#네비게이션-아이콘)
3. [편집/작업 아이콘](#편집작업-아이콘)
4. [보안 아이콘](#보안-아이콘)
5. [통계/차트 아이콘](#통계차트-아이콘)
6. [카테고리 아이콘](#카테고리-아이콘)
7. [상태/알림 아이콘](#상태알림-아이콘)
8. [파일/폴더 아이콘](#파일폴더-아이콘)
9. [설정 아이콘](#설정-아이콘)

---

## 거래 아이콘

**파일**: `lib/screens/transaction_add_screen.dart`, `lib/widgets/root_transaction_list.dart`

| 코드 | 표시 | 설명 | 용도 |
|------|------|------|------|
| `Icons.trending_up` | ⬆️ | 상승 추세 | 입금 거래 |
| `Icons.savings` | 💰 | 저축 통장 | 저축/이체 거래 |
| `Icons.trending_down` | ⬇️ | 하강 추세 | 출금 거래 |

---

## 네비게이션 아이콘

**파일**: `lib/screens/home_tab_screen.dart`, `lib/screens/root_search_screen.dart`

| 코드 | 표시 | 설명 | 용도 |
|------|------|------|------|
| `Icons.home` | 🏠 | 집 모양 | 홈 화면 |
| `Icons.search` | 🔍 | 돋보기 | 검색 기능 |
| `Icons.menu` | ☰ | 메뉴 | 메뉴 열기 |
| `Icons.arrow_back` | ◀ | 뒤로가기 | 뒤로 이동 |
| `Icons.arrow_forward` | ▶ | 앞으로가기 | 앞으로 이동 |
| `Icons.navigate_next` | ➤ | 다음 | 다음 화면 |
| `Icons.chevron_left` | ◀ | 꺾인 화살표 좌 | 이전 항목 |
| `Icons.chevron_right` | ▶ | 꺾인 화살표 우 | 다음 항목 |
| `Icons.expand_more` | ▼ | 펼치기 | 아코디언 열기 |
| `Icons.expand_less` | ▲ | 접기 | 아코디언 닫기 |
| `Icons.date_range` | 📅 | 날짜 범위 | 기간 선택 |
| `Icons.calendar_today` | 📅 | 오늘 달력 | 날짜 선택 |
| `Icons.admin_panel_settings` | ⚙️ | 관리자 설정 | 설정 화면 |

---

## 편집/작업 아이콘

**파일**: `lib/screens/transaction_detail_screen.dart`, `lib/screens/account_stats_screen.dart`

| 코드 | 표시 | 설명 | 용도 |
|------|------|------|------|
| `Icons.edit` | ✏️ | 편집 | 수정하기 |
| `Icons.delete` | 🗑️ | 삭제 | 삭제하기 |
| `Icons.delete_outline` | 🗑️ | 삭제 아웃라인 | 삭제하기 (아웃라인) |
| `Icons.add` | ➕ | 추가 | 새로 추가 |
| `Icons.remove` | ➖ | 제거 | 항목 제거 |
| `Icons.close` | ✕ | 닫기 | 창 닫기 |
| `Icons.check` | ✓ | 확인 | 완료 표시 |
| `Icons.check_circle` | ✓⭕ | 체크 원형 | 완료됨 |
| `Icons.check_circle_outline` | ⭕ | 빈 체크 원형 | 체크박스 |
| `Icons.radio_button_checked` | ⭕ | 선택됨 | 라디오 선택 |
| `Icons.radio_button_unchecked` | ⭕ | 선택안됨 | 라디오 미선택 |
| `Icons.replay` | ↻ | 반복 | 거래 복제 |
| `Icons.event_repeat` | 🔄 | 반복 이벤트 | 반복 설정 |
| `Icons.clear` | ✕ | 지우기 | 필드 초기화 |
| `Icons.restart_alt` | ↻ | 다시 시작 | 초기화 |
| `Icons.refresh` | 🔄 | 새로고침 | 데이터 갱신 |
| `Icons.copy` | 📋 | 복사 | 복사하기 |
| `Icons.move_down` | ⬇️ | 아래로 이동 | 항목 이동 |

---

## 보안 아이콘

**파일**: `lib/screens/asset_tab_screen.dart`, `lib/widgets/user_account_auth_gate.dart`

| 코드 | 표시 | 설명 | 용도 |
|------|------|------|------|
| `Icons.fingerprint` | 👆 | 지문 | 지문 인식 |
| `Icons.lock_outline` | 🔒 | 잠금 아웃라인 | 잠금 상태 |
| `Icons.lock` | 🔒 | 잠금 | 잠금됨 |
| `Icons.lock_open` | 🔓 | 열린 잠금 | 잠금 해제됨 |
| `Icons.password_outlined` | 🔐 | 비밀번호 아웃라인 | 비밀번호 입력 |
| `Icons.verified_user` | ✓👤 | 검증된 사용자 | 인증됨 |
| `Icons.verified_user_outlined` | 👤 | 검증 사용자 아웃라인 | 인증 확인 |
| `Icons.shield_outlined` | 🛡️ | 방패 아웃라인 | 보안 보호 |
| `Icons.manage_accounts` | 👥 | 계정 관리 | 계정 관리 |

---

## 통계/차트 아이콘

**파일**: `lib/screens/account_stats_screen.dart`, `lib/screens/home_tab_screen.dart`

| 코드 | 표시 | 설명 | 용도 |
|------|------|------|------|
| `Icons.bar_chart` | 📊 | 막대 차트 | 막대 그래프 |
| `Icons.pie_chart` | 🥧 | 원형 차트 | 원형 그래프 |
| `Icons.pie_chart_outline` | 🥧 | 원형 차트 아웃라인 | 원형 차트 아웃라인 |
| `Icons.auto_graph` | 📈 | 자동 그래프 | 자동 분석 |
| `Icons.auto_graph_outlined` | 📈 | 자동 그래프 아웃라인 | 자동 분석 아웃라인 |
| `Icons.trending_up` | 📈 | 상승 추세 | 증가 추세 |
| `Icons.trending_down` | 📉 | 하강 추세 | 감소 추세 |
| `Icons.swap_vert` | ⬍ | 수직 교환 | 정렬 변경 |
| `Icons.analytics` | 📊 | 분석 | 분석 데이터 |
| `Icons.insert_chart` | 📊 | 차트 삽입 | 차트 보기 |
| `Icons.article_outlined` | 📄 | 문서 아웃라인 | 보고서 |

---

## 카테고리 아이콘

**파일**: `lib/screens/transaction_add_screen.dart`, `lib/screens/icon_management_screen.dart`

| 코드 | 표시 | 설명 | 용도 |
|------|------|------|------|
| `Icons.category` | 🏷️ | 카테고리 | 카테고리 선택 |
| `Icons.category_outlined` | 🏷️ | 카테고리 아웃라인 | 카테고리 표시 |
| `Icons.shopping_cart` | 🛒 | 쇼핑 카트 | 쇼핑 기능 |
| `Icons.shopping_bag` | 🛍️ | 쇼핑 백 | 쇼핑 백 |
| `Icons.receipt_long` | 🧾 | 긴 영수증 | 거래 영수증 |
| `Icons.receipt_long_outlined` | 🧾 | 긴 영수증 아웃라인 | 영수증 아웃라인 |
| `Icons.payment` | 💳 | 결제 | 결제 수단 |
| `Icons.payments` | 💸 | 지불 | 지불 관련 |
| `Icons.payments_outlined` | 💸 | 지불 아웃라인 | 지불 아웃라인 |
| `Icons.account_balance_wallet` | 💰 | 지갑 | 계정 잔액 |
| `Icons.account_balance_wallet_outlined` | 💰 | 지갑 아웃라인 | 지갑 아웃라인 |
| `Icons.savings` | 💰 | 저축 통장 | 저축 계좌 |
| `Icons.savings_outlined` | 💰 | 저축 아웃라인 | 저축 아웃라인 |
| `Icons.attach_money` | 💵 | 돈 첨부 | 금액 입력 |
| `Icons.fact_check_outlined` | ☑️ | 팩트 체크 아웃라인 | 점검 목록 |

---

## 상태/알림 아이콘

**파일**: `lib/screens/home_tab_screen.dart`, `lib/utils/snackbar_utils.dart`

| 코드 | 표시 | 설명 | 용도 |
|------|------|------|------|
| `Icons.warning_amber` | ⚠️ | 경고 | 경고 메시지 |
| `Icons.warning_amber_rounded` | ⚠️ | 경고 둥근 | 경고 알림 |
| `Icons.error_outline` | ❌ | 오류 아웃라인 | 오류 메시지 |
| `Icons.info_outline` | ℹ️ | 정보 아웃라인 | 정보 표시 |
| `Icons.check_circle` | ✓⭕ | 체크 원형 | 성공 메시지 |
| `Icons.check_circle_outline` | ⭕ | 빈 체크 원형 | 성공 표시 |
| `Icons.notification_important` | 🔔 | 중요 알림 | 알림 중요 |
| `Icons.notifications_none` | 🔔 | 알림 없음 | 알림 없음 |

---

## 파일/폴더 아이콘

**파일**: `lib/screens/backup_screen.dart`, `lib/screens/file_viewer_screen.dart`

| 코드 | 표시 | 설명 | 용도 |
|------|------|------|------|
| `Icons.backup` | 💾 | 백업 | 백업 기능 |
| `Icons.download` | ⬇️ | 다운로드 | 다운로드 |
| `Icons.upload` | ⬆️ | 업로드 | 업로드 |
| `Icons.file_copy` | 📄 | 파일 복사 | 파일 복사 |
| `Icons.folder` | 📂 | 폴더 | 폴더 표시 |
| `Icons.folder_open` | 📂 | 열린 폴더 | 폴더 열기 |
| `Icons.inventory_2` | 📦 | 인벤토리 | 자산 목록 |
| `Icons.image` | 🖼️ | 이미지 | 사진 표시 |
| `Icons.photo_camera` | 📷 | 사진 카메라 | 카메라 |
| `Icons.camera_alt` | 📷 | 카메라 대체 | 사진 촬영 |

---

## 설정 아이콘

**파일**: `lib/screens/asset_tab_screen.dart`, `lib/screens/home_tab_screen.dart`

| 코드 | 표시 | 설명 | 용도 |
|------|------|------|------|
| `Icons.settings` | ⚙️ | 설정 | 설정 화면 |
| `Icons.settings_outlined` | ⚙️ | 설정 아웃라인 | 설정 아웃라인 |
| `Icons.tune` | 🎚️ | 튜닝 | 세부 설정 |
| `Icons.dashboard_customize_outlined` | 📊 | 대시보드 커스터마이즈 아웃라인 | 대시보드 설정 |
| `Icons.visibility_off_outlined` | 👁️ | 보이지 않음 아웃라인 | 숨김 |
| `Icons.visibility` | 👁️ | 보임 | 표시 |
| `Icons.more_vert` | ⋮ | 더보기 세로 | 더많은 옵션 |
| `Icons.more_horiz` | ⋯ | 더보기 가로 | 가로 메뉴 |
| `Icons.open_with` | ↔️ | 열기 | 열기 |
| `Icons.open_with_outlined` | ↔️ | 열기 아웃라인 | 열기 아웃라인 |

---

## 추가 아이콘 목록

### 시간/날짜 관련
| 코드 | 표시 | 설명 |
|------|------|------|
| `Icons.history` | 🕐 | 히스토리 |
| `Icons.schedule` | 📅 | 일정 |
| `Icons.today` | 📅 | 오늘 |
| `Icons.event` | 📅 | 이벤트 |

### 알파벳 관련
| 코드 | 표시 | 설명 |
|------|------|------|
| `Icons.sort` | ⬍ | 정렬 |
| `Icons.sort_by_alpha` | 🔤 | 알파벳 정렬 |
| `Icons.filter_list` | ☰ | 필터 목록 |

### 보기 관련
| 코드 | 표시 | 설명 |
|------|------|------|
| `Icons.list` | 📋 | 목록 |
| `Icons.list_alt` | 📝 | 목록 대체 |
| `Icons.view_list` | ☰ | 목록 보기 |
| `Icons.view_agenda` | ☰ | 안건 보기 |

---

## 🎨 색상 매핑 (일반적인 사용)

```dart
// 성공/긍정
color: Colors.green      // 입금, 추가, 완료

// 오류/부정
color: Colors.red        // 출금, 삭제, 오류

// 경고
color: Colors.orange     // 경고, 주의, 백업

// 정보/중립
color: Colors.blue       // 정보, 이동, 수정

// 강조
color: Colors.purple     // 통계, 분석, 목표

// 기본
color: Colors.grey       // 비활성, 기타
```

---

## 📱 Material Design Icons 사용 예시

### 기본 사용법
```dart
Icon(Icons.trending_up)

Icon(Icons.trending_up, size: 24),

Icon(Icons.trending_up, color: Colors.green),

Icon(Icons.trending_up, 
  size: 32, 
  color: Colors.green),
```

### Semantics 포함
```dart
Semantics(
  label: '입금 거래',
  child: Icon(Icons.trending_up),
)
```

---

## 🔗 참고 자료

- **공식 문서**: https://material.io/resources/icons
- **Flutter 문서**: https://api.flutter.dev/flutter/material/Icons-class.html
- **검색 도구**: https://www.codepoint.subnets.au/

---

**마지막 업데이트**: 2025-12-24

