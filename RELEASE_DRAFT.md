릴리스 초안 (스토어 제출 준비)

작성일: 2026-01-01
최종 갱신: 2026-02-28
상태: 제출 준비 완료 (운영 체크 후 Play Console 업로드)
AAB 위치: `build/app/outputs/bundle/release/app-release.aab`
릴리스 버전: `1.0.1+2`

릴리스 노트 초안:
- 지출 입력(Expense input) 기능 완성
  - 상품명, 결제수단, 메모 필드의 최근입력 불러오기 기능 추가
  - 입력 UI 개선(입력창 내부 버튼 일관화)
  - SharedPreferences 기반 최근입력 저장/불러오기 통합
- QA: 내부 테스트 통과(디버그/릴리즈 빌드 성공)
- 알려진 미완료 항목: 일부 UI/다국어 정리 및 추가 기능 필요

배포 전 운영 체크 항목:
- 버전 정책 확인(Play Console 기존 versionCode보다 높은 값 사용)
- 스토어 정책 문구/데이터 안전 섹션 최신화
- 릴리스 노트/스크린샷/국가별 배포 설정 점검

다음 단계 제안:
1. [docs/developer/PLAY_CONSOLE_PREUPLOAD_CHECKLIST_KO.md](docs/developer/PLAY_CONSOLE_PREUPLOAD_CHECKLIST_KO.md) 체크 완료
2. 내부 테스트 트랙 1차 배포 후 충돌/결제/인증 핵심 시나리오 확인
3. 이상 없으면 프로덕션 단계적 롤아웃(예: 5% → 20% → 100%) 진행

메모: AAB는 레포와 분리하여 `backups/releases/`에 안전 보관했습니다.

---

최근 업데이트 (2026-02-28):
- 보안 아키텍처 정리 완료: 생체인식 공통, PIN/비밀번호 ROOT/USER/ASSET 분리.
- 자산/사용자 인증 게이트를 ROOT 패턴(단일/2중 인증)으로 정렬.
- 문서 일괄 갱신 완료: `보안.md`, 사용자 매뉴얼, docs 인덱스.
- 아이콘 이동 정책 확정: 하단 2번째 줄 우선 정렬(맨 하단 줄 마지막), 저장 슬롯 index는 기존 유지.
- 메인 그리드와 아이콘 관리 화면(드롭존/편집 순서/배치 목록) 정렬 정책 동기화 완료.
- 정책 문서 반영: `docs/policies/ICON_MANAGEMENT_SINGLE_SOURCE_KO.md` 4-C/E 업데이트.
- AI 투자 분석 기능에 강제 고지/동의 게이트 추가(체크박스 동의 필수, 미동의 시 진입 차단).
- 설정 > 법적 고지에 투자 분석 동의 기록 조회/초기화 기능 추가(상태/시각/버전/로케일).
- 검증 현황: `flutter analyze`/`flutter build apk --release`/`flutter build appbundle --release`/`flutter install --release` 성공.

배포 상태 메모:
- 현재 코드/빌드 기준으로 기술적 배포 가능 상태입니다.
- 실제 공개 배포는 사전 체크리스트 완료 후 진행하세요.
