# UI 디자인 정책 (UI Design Policy)

## 1. 개요
앱의 시각적 일관성과 사용자 경험(UX) 품질을 유지하기 위한 디자인 가이드라인입니다.

## 2. 버튼 디자인 (Button Design)
### 2.1 기본 디자인 원칙
- **모양(Shape)**: 모든 버튼은 **사각형 라운드(Rounded Rectangle)** 형태를 사용한다.
- **예외**: 아이콘 전용 버튼(IconButton) 등 특수한 목적의 경우를 제외하고, 텍스트가 포함된 모든 인터랙션 버튼에 적용한다.

### 2.2 구현 상세 (Flutter)
- 기본적으로 `BorderRadius.circular(8)` 이상의 라운드 값을 권장한다.
- 테마 설정을 통해 전역적으로 적용하거나, 개별 위젯의 `style` 속성을 통해 정의한다.

```dart
// 예시: ElevatedButton 스타일 설정
ElevatedButton(
  style: ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  onPressed: () {},
  child: Text('저장하기'),
)
```

### 2.3 디자인 의도
- 앱 전체의 톤앤매너(Tone & Manner)를 부드럽고 현대적으로 유지한다.
- 사용자가 버튼임을 쉽게 인지할 수 있도록 일관된 시각적 피드백을 제공한다.

## 3. 기록 및 업데이트
- 이 정책은 2026-01-31에 추가되었습니다.
- 앱 디자인 시스템 변경 시 이 문서를 먼저 업데이트합니다.
