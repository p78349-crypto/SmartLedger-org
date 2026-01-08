# Firebase 가족 공유 – 설정 가이드(초안)

이 문서는 현재 SmartLedger의 **미래 확장(가족 공유)** 을 위한 Firebase 설정 메모입니다.

- 현재 기본 모드: Firebase 미사용(로컬 저장만)
- Firebase 재도입 시: 이 문서의 절차를 참고

## 1) Firebase 프로젝트 준비
- Firebase Console에서 프로젝트 생성
- Android 앱 등록(패키지명 확인 필요)

## 2) FlutterFire 설정(권장)
- FlutterFire CLI 설치 후 실행:
  - `dart pub global activate flutterfire_cli`
  - 프로젝트 루트에서 `flutterfire configure`
- 생성된 `lib/firebase_options.dart`를 사용하도록 구성합니다.

## 3) 빌드 플래그로 기능 활성화
- 기본은 비활성화입니다.
- 활성화(예):
  - `flutter run --dart-define=ENABLE_FAMILY_SHARING=true`

## 4) 활성 가족 ID 지정
- 현재는 UI 없이 prefs 키로만 읽는 방식으로 설계되어 있었습니다:
  - key: `activeFamilyIdV1`
- 이후 설정 화면/초대 흐름 UI가 들어가면 자연스럽게 대체될 예정입니다.
