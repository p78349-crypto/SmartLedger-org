# 개발 모드 디버그 기능 정책

## 목적
UI 요소의 정확한 위치 조정 및 레이아웃 작업을 위한 개발 도구

## 구현 위치
- `lib/screens/account_main_screen.dart`

## 1. 화면 크기 정보 출력

### 코드 사양
```dart
if (kDebugMode) {
  final size = MediaQuery.of(context).size;
  final padding = MediaQuery.of(context).padding;
  debugPrint('📱 화면 크기: ${size.width} x ${size.height}');
  debugPrint('📱 SafeArea 여백: top=${padding.top}, bottom=${padding.bottom}');
  debugPrint('📱 방향: ${isLandscape ? "가로" : "세로"}');
}
```

### 출력 정보
1. 화면 크기 (width × height)
2. SafeArea 여백 (top, bottom, left, right)
3. 화면 방향 (가로/세로)

### 활용
UI 요소 위치 조정 시 정확한 픽셀 값 계산
- 예: "오른쪽으로 X픽셀 이동"
- 예: "하단에서 Y픽셀 위치"

## 2. 그리드 오버레이

### 코드 사양
```dart
if (kDebugMode)
  Positioned.fill(
    child: IgnorePointer(
      child: GridPaper(
        color: Colors.blue.withValues(alpha: 0.15),
        interval: 50,
        divisions: 1,
        subdivisions: 5,
      ),
    ),
  ),
```

### 기능
- 50픽셀 간격의 파란색 그리드 표시
- 5개의 서브디비전으로 10픽셀 단위 세밀 조정 가능
- `IgnorePointer`로 터치 이벤트 방해 없음
- 투명도 15%로 콘텐츠 가시성 유지

### 활용
- UI 요소 정렬 확인
- 간격 및 여백 시각적 검증
- 픽셀 단위 정밀 배치

## 동작 방식
- **개발/디버그 모드**: 모든 기능 활성화
- **릴리즈 빌드**: `kDebugMode` 플래그에 의해 자동으로 코드 제거됨 (빌드 최적화)

## 정책
- ✅ **프로토타입/개발 모드**: 활성화
- ✅ **릴리즈 빌드**: Flutter 컴파일러가 자동 제거
- ✅ **수동 제거 불필요**: `kDebugMode` 조건문으로 자동 관리
- ✅ **성능 영향 없음**: 릴리즈 빌드에 포함되지 않음

## 작성일
2026-01-04

## 참고
- Flutter의 `kDebugMode`는 릴리즈 빌드 시 해당 코드 블록을 완전히 제거
- 수동 제거 작업 불필요
- 프로토타입 단계에서 UI 작업 편의성 극대화
