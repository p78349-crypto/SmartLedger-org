# Docs Hub

문서 접근성을 높이기 위한 통합 허브입니다.

## 1) 시작점
- 전체 문서 카탈로그: [DOCS_MASTER_CATALOG.md](DOCS_MASTER_CATALOG.md)
- 사용자 도움말 허브: [app-help/README.md](app-help/README.md)
- 개발자 문서 허브: [developer/README.md](developer/README.md)

## 2) 빠른 탐색 가이드
- 기능 사용법이 필요하면 `app-help`부터 확인
- 구현/운영/장애 대응은 `developer`부터 확인
- 문서 위치를 모를 때는 `DOCS_MASTER_CATALOG.md`에서 폴더별로 검색

## 2-1) 카탈로그 갱신 명령
- PowerShell:
	- `./scripts/update_docs_catalog.ps1`
- 필요 시 출력 파일 지정:
	- `./scripts/update_docs_catalog.ps1 -OutputFile ./docs/hub/DOCS_MASTER_CATALOG.md`

## 3) 원본 인덱스
- Docs Index: [../README.md](../README.md)
- User Manual Index: [../user-manual/README.md](../user-manual/README.md)
- Developer Docs Index: [../developer/README.md](../developer/README.md)
