# Contributing Guidelines

Please follow this checklist when you make changes to the codebase.

## Mandatory: Update the INDEX
- Every change that adds/removes/renames files, routes, prefs, or modifies behavior must have a matching entry in `tools/INDEX_CODE_FEATURES.md`.
- Add one line with: Date | What changed | Old | New | Note
- Example:
  | 2025-12-18 | 아이콘 슬롯 배치 도입 | 자유형 아이콘 리스트 | 슬롯 기반(4x3) 그리드 도입 | lib/screens/account_main_screen.dart, lib/services/user_pref_service.dart |
- Tip: Use the helper script `tools/add-index-entry.ps1` (Windows PowerShell) to interactively add an entry and optionally stage the file for commit.
- Use `tools/validate_index.sh` locally to verify format before committing: `pwsh ./tools/validate_index.sh` (Git bash/WSL/PowerShell on Windows) or `./tools/validate_index.sh` on macOS/Linux.
- You can export INDEX to CSV/JSON with Dart: `dart run tools/export_index.dart` and generate lightweight release notes via `tools/generate_release_notes.sh <since-date>`.

## 인덱스 작성 습관화 체크리스트 (권장)
- 변경 사항을 로컬에서 작업할 때마다 아래를 습관화하세요:
  1. 기능/버그 수정/파일 변경 후 **`pwsh ./tools/add-index-entry.ps1`** 를 실행하여 간단한 한 줄 요약을 추가합니다.
  - 추천 Note 키: `Playbook`(화면/모듈 체크리스트), `Why`(이유), `Verify`(검증 방법), `Tests`(실행한 테스트), `Risk`(리스크/주의), `Files`(영향 파일)
  2. `tools/INDEX_CODE_FEATURES.md`를 수정하고 **스테이징**합니다 (commit 전에 `git add tools/INDEX_CODE_FEATURES.md`).
  3. `pwsh ./tools/validate_index.sh` 로 포맷을 검증합니다.
  4. 유닛 및 위젯 테스트를 실행합니다 (`flutter test` 등).
  5. 커밋 메시지에 필요 시 `[skip-index]` 를 포함하여 검토자의 동의 하에 인덱스 업데이트를 생략할 수 있습니다 (권장하지 않음).
- 로컬에서 훅을 활성화하려면 한번만 실행하세요:

  ```bash
  git config core.hooksPath .githooks
  ```

- 자동화: 이 저장소는 **pre-commit 훅**과 **CI PR 검사**(`.github/workflows/index-check.yml`)를 포함하여 인덱스 업데이트 규칙을 강제합니다. PR에서 소스 파일이 변경되면 INDEX 수정 여부를 확인하고, 누락 시 PR 체크가 실패합니다.

**왜 필요한가?** 인덱스는 변경 이력/릴리스 노트/코드 분석에 큰 도움을 줍니다. 작은 수고가 장기적으로 유지보수 비용을 크게 줄여줍니다.


## Commit checks
- This repo includes a pre-commit hook that enforces the INDEX update rule: `git config core.hooksPath .githooks` (run once in your local repo if not set).
- If you change files under `lib/`, `tools/` or `pubspec.yaml` you must also stage `tools/INDEX_CODE_FEATURES.md` before committing.
- Additionally, there is a CI workflow (`.github/workflows/index-check.yml`) that will **block pull requests** where source files changed but `tools/INDEX_CODE_FEATURES.md` was not updated. This helps keep the INDEX consistent across the project and teaches a habit of adding concise entries for each change.

## Formatting & Tests
- Run `flutter analyze` and `flutter test` where applicable before pushing.

## Policy: Landscape-first for text/stat screens

The app will actively leverage **landscape (가로화면)** for screens that are
primarily used for **reading** dense information (통계/리포트/거래 리스트/텍스트 출력).

### Rules
- Keep portrait UX stable: landscape optimizations must not break the portrait layout.
- Use a simple orientation gate:
  - `final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;`
- Prefer “one-line per row” layouts in landscape:
  - Use `Row + Expanded(flex: ...)` with `maxLines: 1` + `TextOverflow.ellipsis`.
  - Avoid horizontal scrolling by default (readability first).
- Optional: a single header row (열 제목) is allowed in landscape.
  - If it causes noticeable truncation, remove it (don’t force it).
- Do not introduce new colors/fonts/shadows for this.
  - Reuse `Theme.of(context)` text styles and existing tokens.
- Keep tap targets reasonable.
  - If switching away from `ListTile`, validate touch area and spacing.

### Verification
- Check both orientations (portrait + landscape) on a real device/emulator.
- Run: `flutter analyze --no-fatal-infos` and `flutter test`.
- If this policy changes screen behavior, add an entry to
  `tools/INDEX_CODE_FEATURES.md` Change Log.

Thank you — keeping a clear INDEX makes debugging and releases much easier.