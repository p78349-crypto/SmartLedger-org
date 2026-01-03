# INDEX Tools (local helpers)

This folder contains helper scripts and utilities to keep `tools/INDEX_CODE_FEATURES.md` up-to-date and useful.

Find-only (fast navigation) indexes

- `tools/INDEX_PARENT.md`
  - Quick file map (what to open).
- `tools/INDEX_CHILD.md`
  - Per-file search hints (what to search).
- Open both quickly:
  - VS Code task: `Open Find INDEX (Parent + Child)`
  - Or PowerShell: `pwsh ./tools/open_find_indexes.ps1 -ReuseWindow`

Docs

- `SSOT_QUALITY_GATE.md`
  - Defines the single source of truth for the Quality Gate result and how to run it.

Available tools

- `add-index-entry.ps1` (PowerShell, interactive)
  - Prompts for Date/What/Old/New/Note/Files and inserts a Markdown table row beneath the INDEX table header.
  - Usage: `pwsh ./tools/add-index-entry.ps1` (Windows PowerShell Core)
  - Example: `pwsh ./tools/add-index-entry.ps1 -What "CI: index check" -Files ".github/workflows/index-check.yml" -Stage`
  - Recommended (detailed note habit):
    - Example: `pwsh ./tools/add-index-entry.ps1 -What "Fix: analyzer errors" -Why "빌드 차단 해소" -Verify "flutter analyze" -Tests "flutter test" -Files "lib/screens/account_main_screen.dart" -Stage`

- `add-index-entry-auto.ps1` (PowerShell, auto Files)
  - Wrapper for `add-index-entry.ps1` that auto-fills `Files` from `git diff` (staged + unstaged by default).
  - Usage: `pwsh ./tools/add-index-entry-auto.ps1`
  - Example: `pwsh ./tools/add-index-entry-auto.ps1 -What "Fix: ..." -Stage`

- `INDEX_ENTRY_TEMPLATE.md`
  - Example row format and tips for keeping entries consistent.

- `validate_index.sh` (bash)
  - Validates the table is present and each row starts with an ISO date and has 5 columns.
  - Usage: `./tools/validate_index.sh` or `pwsh ./tools/validate_index.sh` on Windows (Git Bash / WSL recommended).

- `validate_index.ps1` (PowerShell)
  - Windows-friendly validator (same intent as `validate_index.sh`).
  - Usage: `pwsh ./tools/validate_index.ps1`

Playbooks (screen/module checklists)

- `tools/INDEX_CODE_FEATURES.md` now supports a **Screen Playbooks** section.
- When you add a Change Log line, put a pointer in Note like: `Playbook=AccountMainScreen`.
- The validators (`validate_index.ps1` / `validate_index.sh`) will fail if a row references a Playbook that does not exist as a heading (`### Playbook: ...`).

- `export_index.dart`
  - Exports `tools/INDEX_CODE_FEATURES.md` to CSV (`tools/index_export.csv`) and JSON (`tools/index_export.json`).
  - Usage: `dart run tools/export_index.dart`

- `generate_release_notes.sh`
  - Simple generator that extracts table rows since a given date (YYYY-MM-DD).
  - Usage: `./tools/generate_release_notes.sh 2025-12-18`

- `generate_release_notes.ps1` (PowerShell)
  - Windows-friendly release notes generator (same intent as `generate_release_notes.sh`).
  - Usage: `pwsh ./tools/generate_release_notes.ps1 2025-12-18`

- `open_find_indexes.ps1` (PowerShell)
  - Opens `tools/INDEX_PARENT.md` and `tools/INDEX_CHILD.md`.
  - Usage: `pwsh ./tools/open_find_indexes.ps1 -ReuseWindow`

- `check_long_lines.ps1` (PowerShell)
  - Checks `lib/**/*.dart` for lines longer than 80 chars (no ignores).
  - Usage: `pwsh ./tools/check_long_lines.ps1 -Root lib -MaxLen 80`
  - VS Code task: `Check long lines (lib dart >80)`

Tips

- Use the VS Code tasks from `.vscode/tasks.json` to run the Add INDEX Entry helper and export/validate tasks quickly.
- If you change source files locally, run `./tools/validate_index.sh` before committing to avoid CI surprises when you later open a PR.

Habit workflow (quick)

1) Code change done → immediately add INDEX row
- `pwsh ./tools/add-index-entry.ps1` (fill `Why/Verify/Tests/Files`)

1.1) (Optional but recommended) Link to a Playbook
- Fill `Playbook` in the prompt (e.g., `AccountMainScreen`) so the Change Log entry can jump to a per-screen debug/checklist.

2) Validate format
- `pwsh ./tools/validate_index.ps1` (Windows) or `bash ./tools/validate_index.sh` (Git Bash/WSL)
- VS Code task “Validate INDEX format (PowerShell)” (Windows)

Recommended (end-of-work, one-shot)

- VS Code task: `End of work: INDEX 기록(추가→검증→내보내기)`
- VS Code task (auto files): `End of work: INDEX 기록(자동파일→검증→내보내기)`
- VS Code task (no prompt): `End of work: INDEX 검증+내보내기(무프롬프트)`

3) Run checks
- `flutter analyze` (or `flutter analyze --no-fatal-infos` if you only want errors to fail)
- `flutter test`

Thank you for keeping the INDEX accurate — it becomes very valuable over time.