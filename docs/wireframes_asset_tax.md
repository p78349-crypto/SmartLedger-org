# 자산/세무 와이어프레임 (텍스트 스케치)

## 1) 자산 현황 메인
```
[헤더]
총자산 ￦X, 전일대비 +Y%, 세후 수익률 Z%
필터: 기간(1M/3M/1Y/전체) · 지역 · 가구구성

[자산군 카드 2열 그리드]
┌ 부동산 ┐ ┌ 금융자산 ┐ ┌ 투자상품 ┐ ┌ 연금 ┐ ┌ 비상금 ┐ ┌ 기타 ┐
평가액 | 원금 | 손익 | 세후수익률 | LTV(부동산)

[CTA]
- 자산 추가  - 문서 업로드

[리스트]
자산군별 드릴다운 > (부동산 3건, 금융 8건 ...)
```

### 실 화면 설계 (모바일 포트레이트)
```
AppBar: 좌측 햄버거(설정/백업), 제목 "자산 현황", 우측 종/알림

Body (ScrollView):
	Padding 16
	- Row: 총자산 금액(large) / 전일대비 증감(Chip), 세후 수익률(Chip)
	- Filter Row: 기간 Segmented(1M/3M/1Y/전체), 지역 Dropdown, 가구구성 Dropdown
	- Spacer 8
	- Grid 2열 Card (Aspect 1.1): 부동산/금융/투자/연금/비상금/기타
			· 타이틀 + 아이콘
			· 평가액(굵게), 원금, 손익(색상), 세후수익률
			· 부동산이면 LTV 배지, 비상금이면 한도/가용액 배지
			· 탭 시 자산군 상세로 이동
	- Spacer 12
	- CTA Row: OutlinedButton("자산 추가"), FilledButton("문서 업로드")
	- Section Header: "자산군별 내역" + trailing TextButton("전체 보기")
	- ListTiles: 자산군 이름, 보유 개수, 평가액, 손익 색상; chevron
	- Bottom padding 24
```

### 컴포넌트 속성 (모바일)
- 카드 공통: Elevation 1~2, radius 12, padding 12~16, 컬러 surface
- 금액 텍스트: headlineSmall (semibold), 천단위, 통화 기호 축소(₩)
- 손익 텍스트: bodyMedium, 색상 `error`/`primary`, +/− 부호 표시
- Chip: filled tonal, 아이콘 포함, height 32, radius 16
- Grid 카드 아이콘: size 22~24, 색상 onSurfaceVariant

### 태블릿 레이아웃 (landscape 기준 1024px+)
- Grid 3열 또는 4열(여백 24), 카드 height 180
- 헤더/필터를 상단 2컬럼으로 좌우 배치: 좌측 금액/증감, 우측 필터들
- 리스트 대신 "자산군 테이블"(DataTable 스타일): 자산군 | 평가액 | 원금 | 손익 | 세후수익률 | 개수
- CTA 버튼을 헤더 우측 정렬, 아이콘+라벨 수평형
## 2) 자산 상세 (확장 상세)
```
[상단 카드 스크롤]
- 현재가치 / 원금 / 손익 / 세후수익률 / LTV(옵션) / 한도·가용액(비상금)

[행동 버튼]
매수/매도/입금/출금 | 자동이체/충전 | 문서 업로드 | 세금 계산

[필터 바]
기간(1M/3M/1Y/전체/커스텀) · 항목(입금/출금/배당/이자/매매) · 정렬(최신/금액)

[차트 2종]
(A) 잔액/평가액 추이 라인/에어리어
(B) 입출금·매수·매도 스택 바

[거래 리스트]
아이콘/타입태그 | 설명 | 날짜·계정·결제수단·메모 | 금액(±, 색상, 천단위) | 유형 라벨

[거래 터치 → BottomSheet]
세부 정보 + 수정/삭제/복제 버튼
```

### 실 화면 설계 (모바일 포트레이트)
```
AppBar: Back, 제목(자산명), 우측 ⋯ 메뉴(간단 보기, PDF, 공유)

Body (CustomScrollView):
	SliverToBoxAdapter Padding 16:
		- Horizontal Chips: 태그(자산군/지역/통화), 알림 토글
		- Horizontal Scroll Cards (height ~140):
				[현재가치], [원금], [손익], [세후수익률], [LTV], [한도/가용액(비상금만)]
		- Action Row: FilledButton("입금/충전"), TonalButton("출금/상환"),
									OutlinedButton("문서 업로드"), IconButton("계산기=세금")
		- Filter Bar (Chips): 기간(1M/3M/1Y/전체/커스텀), 항목(입금/출금/배당/이자/매매), 정렬(최신/금액)
		- Charts (Card with tabs): Tab1 "추이" → 라인/에어리어 잔액, Tab2 "입출금" → 스택바
		- Section Header: "거래" + pill count
	SliverList.separated:
		ListTile 높이 76, leading 아이콘(타입색), title=설명, subtitle=날짜·계정·결제수단·메모,
		trailing=금액(색상, 굵게) + 유형 라벨; onTap → BottomSheet

BottomSheet (거래 상세):
	제목=설명, 타입/금액/날짜/계정/결제수단/메모, 첨부(있으면), 버튼: 수정, 삭제(주의색), 복제
```

### 컴포넌트 속성 (모바일)
- 상단 카드: height 140, radius 16, gradient optional; 주요 값은 headlineMedium bold
- Action Row 버튼: minWidth 0, height 44, icon+label, spacing 8
- Filter Chips: AssistChip 스타일, 선택 시 filled tonal, 다중선택 허용
- 차트 카드: radius 16, padding 12, 탭 높이 40; Y축 라벨 compact, X축 월/일 포맷
- 거래 ListTile: height 76, leading Icon size 22, trailing 금액 textStyle bodyLarge bold, type label labelSmall
- BottomSheet: top radius 20, drag handle, padding 16; 버튼 3개 세로 스택(Full width)

### 태블릿 레이아웃
- 좌우 2분할: 좌측 차트/카드, 우측 거래 리스트; split 비율 6:4
- 상단 카드 2행 배치(3~4개씩), 차트 높이 260~300
- 거래 리스트는 Dense(64)로, 우측 패널 내 스크롤; BottomSheet 대신 우측 슬라이드 패널로 상세 표시

## 3) 자산 상세 (간단 보기)
```
[핵심 카드]
잔액 / 목표 대비 % / 최근 3건 요약
CTA: 확장 상세 열기
```

### 실 화면 설계 (모바일 포트레이트)
```
AppBar: Back, 제목(자산명), 우측 "확장 상세" TextButton
Body Padding 16:
	- Hero Card: 잔액(큰 숫자), 목표 대비 % Progress, 전일 대비 증감 Chip
	- 최근 3건 미니 리스트 (아이콘+설명+금액)
	- 두 개 버튼: Filled("확장 상세 열기"), Outlined("세금 계산 바로가기")
```

### 컴포넌트 속성 & 태블릿
- Hero Card: height 180(모바일), 200(태블릿); Progress는 linear radius 8, 보조 텍스트 labelMedium
- 미니 리스트: height 56, 아이콘 20, 금액 bodyMedium bold, 부호/색상 적용
- 태블릿: 좌측 Hero Card, 우측 미니 리스트 카드 + 버튼 세로 스택

## 4) 세금 계산·신고
```
[탭]
양도 | 상속·증여 | 종합소득

[입력 카드]
취득가, 취득일, 매도가, 매도일, 공제/특례, 비용

[결과 패널]
예상 세액 · 세후 수익률 · 신고서 PDF 미리보기

[체크리스트/업로드]
필수 서류 리스트 + 업로드 슬롯 + 스캔(OCR)
```

### 실 화면 설계 (모바일 포트레이트)
```
AppBar: Back, 제목 "세금 계산/신고"
Tabs: 양도 / 상속·증여 / 종소세
Body Padding 16 (Tab별 폼):
	- 입력 카드(두 열 대신 단일 열, 모바일): 금액 입력 TextField(천단위 포맷), 날짜 Picker Row, 공제/특례 Switch/Dropdown, 비용 입력
	- 결과 카드: 예상 세액(굵게, 색상), 세후 수익률, 간단 설명
	- Button Row: Filled("PDF 미리보기"), Outlined("신고 체크리스트")
	- 체크리스트 섹션: 필요 서류 항목 + 업로드 버튼 + 스캔(OCR) 아이콘 버튼
	- 하단 Primary CTA: "신고 진행" (비활성 → 필수값 미입력 시)
```

### 컴포넌트 속성 (모바일)
- 금액 TextField: prefixIcon 통화기호, ThousandsFormatter, keyboardType number
- 날짜 Row: TextButton + calendar icon, 선택값 labelMedium
- 결과 카드: Elevation 1, radius 12, 강조 값은 headlineSmall, 보조 설명 bodySmall
- 체크리스트: CheckboxListTile compact, 업로드 버튼은 tonal icon button, OCR은 filled icon
- CTA: FilledButton(height 48, full width), disable 조건 필수값 검증

### 태블릿 레이아웃
- 폼 2컬럼: 좌측 기본정보(금액/날짜), 우측 공제/특례/비용
- 결과 카드와 CTA를 우측 고정 패널로 배치해 입력과 결과 동시 가시화
- 체크리스트/업로드는 하단 전체폭 섹션, 파일 리스트는 두 열 카드 혹은 테이블형

## 5) 리포트/절세 전략
```
[히트맵]
자산별 예상 세부담 강도

[시나리오 비교]
매도 시점/금액 변화 → 세액/세후 수익률 비교 카드 2~3개

[절세 카드]
장기보유특례, 이월공제 등 적용 가능 여부
```

### 실 화면 설계 (모바일 포트레이트)
```
AppBar: Back, 제목 "리포트/절세"
Body Scroll Padding 16:
	- 헤더 카드: 총 예상 세부담, 세후 수익률, 리밸런싱 추천 여부 배지
	- 히트맵 카드: 자산군 x 세목(양도/증여/종소) 강도 색상; Tooltip로 금액 표시
	- 시나리오 비교 카드 슬라이더: 2~3개 카드(매도 시점/금액 변경) → 세액/세후수익률/손익
	- 절세 카드 리스트: 제목(특례명) + 적용 가능 여부 배지(가능/검토/불가) + 설명 2줄 + CTA("가이드 보기")
	- 알림 토글: "기한/요건 알림"
```

### 컴포넌트 속성
- 히트맵: 6~10칸 미니 셀, 색상 단계 5단; legend 우측 배치
- 시나리오 카드: width 280~320, radius 16, 그래프 미니스파크라인 포함
- 배지: filled, color-coded (가능=primary, 검토=tertiary, 불가=outline)

### 태블릿 레이아웃
- 2열 배치: 좌측 히트맵+절세 카드, 우측 시나리오 비교 스택
- 히트맵 크기 확대(4x3 셀), 시나리오 카드 그리드 2열
- 헤더 카드와 알림 토글을 상단 가로 정렬

## 6) 포트폴리오/배분
```
[도넛/바]
목표 비중 vs 실제 비중

[리밸런싱 제안]
매수/매도 권장 금액 리스트

[리스크+세금]
변동성/MaxDD + 세후 IRR/CAGR
```

### 실 화면 설계 (모바일 포트레이트)
```
AppBar: Back, 제목 "포트폴리오"
Body Scroll Padding 16:
	- 도넛 차트: 목표 vs 실제; 범례는 수평 스크롤 칩
	- 바 차트: 자산군별 실제 비중 (정렬 토글: 목표차이 순)
	- 리밸런싱 제안 카드 리스트: 자산군 / 매수·매도 권장 금액 / 목표까지 차이 / 버튼("제안 적용")
	- 리스크+세금 카드: 변동성, MaxDD, 세후 IRR, 세후 CAGR, 기간 선택(1Y/3Y/5Y)
	- 액션: FilledButton("제안 일괄 적용"), Outlined("엑셀 내보내기")
```

### 컴포넌트 속성
- 도넛: central label 총액, segment 최소 3px, hover/터치 시 tooltip
- 범례 칩: AssistChip, 색상 dot 포함, 다중 선택으로 필터
- 리밸런싱 카드: elevation 1, radius 12, 금액 두 줄(매수/매도), diff는 강조색
- 차트 컬러 팔레트: 색상 구분 8~10개, 색맹 안전 팔레트

### 태블릿 레이아웃
- 좌우 분할: 좌측 도넛+바, 우측 리밸런싱 리스트+리스크 카드
- 도넛/바 카드 높이 260, 리스트는 2열 그리드 카드 가능

## 7) 문서함
```
[폴더]
자산별/세목별

[리스트]
파일명 · 업로드일 · 만료일 배지 · 태그(OCR 추출: 금액/일자/종목)

[알림]
만료 예정 알림 토글
```

### 실 화면 설계 (모바일 포트레이트)
```
AppBar: Back, 제목 "문서함", 우측 검색/필터 아이콘
Body Padding 16:
	- 폴더 칩: 자산/세목 필터 (AssistChip)
	- 업로드 CTA: FilledButton("문서 업로드"), IconButton("스캔/OCR")
	- 파일 리스트 (Card or ListTile): 아이콘(파일타입), 파일명, 업로드일, 만료일 배지, 태그(OCR 추출 금액/일자/종목), 우측 ⋯ 메뉴(다운로드/공유/삭제)
	- 정렬/필터 바: 정렬(최근/만료 임박), 상태(만료임박/정상), 태그 검색
	- 만료 알림 스위치: "30일 이내 만료 알림"
```

### 컴포넌트 속성
- 파일 카드: elevation 1, radius 12, padding 12; 만료 배지 색상=error, 임박=warning
- 태그: small chip, outline, 최대 3~5개 표시 후 "+N" more
- 업로드/스캔: height 44 버튼, 스캔은 camera icon

### 태블릿 레이아웃
- 그리드 3열 카드(여백 24) 또는 테이블 뷰: 파일명 | 업로드일 | 만료일 | 태그 | 액션
- 사이드 패널(우측)로 파일 미리보기/메타데이터 노출
- 상단 검색바 풀폭, 필터/정렬을 오른쪽 정렬

## 8) 네비게이션/플로우
```
자산 리스트 → 자산 상세(확장) → 세금 계산 → 리포트 → 문서 업로드/저장
상단 ⋯ 메뉴: 간단 보기로 전환 / PDF 다운로드 / 공유
```