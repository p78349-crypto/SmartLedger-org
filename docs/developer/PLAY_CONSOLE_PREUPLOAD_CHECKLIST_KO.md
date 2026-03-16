# Play Console 업로드 직전 체크리스트 (KO)

기준일: 2026-03-03
대상 산출물: `build/app/outputs/bundle/release/app-release.aab`

## 1) 빌드/품질 게이트
- [x] `flutter analyze` 오류 0
- [x] 핵심 스모크 테스트 통과 (`flutter test test/smoke/tx_db_caches_smoke_test.dart` 포함)
- [x] `flutter build appbundle --release` 성공
- [ ] 실제 단말 설치 확인 (`flutter install --release -d <deviceId>`)

## 2) 버전/릴리스 설정
- [x] `pubspec.yaml`의 `version` 확인 (현재: `1.0.1+2`)
- [ ] Play Console의 기존 최고 `versionCode`보다 높은지 확인
- [ ] 릴리스 노트(ko/en) 최신 기능 반영
- [ ] 내부 테스트/프로덕션 트랙 대상 국가 및 롤아웃 비율 설정

## 3) 결제/인증/핵심 기능 스모크(릴리스 빌드)
- [ ] 구독 상태 조회/구매/복원 플로우 점검
- [ ] ROOT/ASSET 접근 게이트 동작 확인
- [ ] 거래 추가/수정/삭제 후 월집계 값 정상 반영 확인
- [ ] 앱 재실행 후 주요 데이터 무결성 확인

## 4) 정책/컴플라이언스
- [ ] 데이터 안전(Data safety) 항목 최신화
- [ ] 개인정보처리방침 URL/앱 내 노출 최신화
- [ ] 결제/구독 고지 문구 최신화
- [x] 서명키/업로드키 관리 상태 확인

### 4-1) 서명 지문 (2026-03-03)
- Keystore: `android/app/smartledger-release-20260303.jks`
- Alias: `smartledger`
- SHA1: `A0:44:46:72:D2:AF:22:AF:C5:D7:A1:92:0B:59:67:DA:DF:14:1D:5D`
- SHA256: `D7:59:F7:D2:85:32:9B:92:A0:8D:1E:0A:DF:2E:02:E5:EC:70:6C:D2:C3:25:5B:20:F2:F6:C5:8D:C7:30:6B:A6`

## 5) 배포 실행 순서(권장)
1. 내부 테스트 트랙 업로드
2. QA/팀 확인(충돌, 결제, 인증, 복구)
3. 프로덕션 단계적 롤아웃 (예: 5% → 20% → 100%)
4. 모니터링 후 이상 시 즉시 롤백 또는 중단

## 빠른 판정 기준
- 위 1)~4) 항목이 모두 완료되면 업로드 진행
- 미완료 항목이 있으면 해당 항목 해결 후 재판정

## 오늘 실행 로그 요약 (2026-03-03)
- `flutter analyze` 통과
- `flutter test test/smoke/tx_db_caches_smoke_test.dart` 통과
- `flutter build appbundle --release` 성공 (`app-release.aab` 생성)
- 릴리즈 오케스트레이션 `-Stage release` 성공
