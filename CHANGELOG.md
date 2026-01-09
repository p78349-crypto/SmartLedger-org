# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2025-12-30

### Added
- Icon repository: added 12 sample custom SVG icons (`assets/icons/custom/icon_01.svg` ... `icon_12.svg`).
- Icon manifest: `assets/icons/metadata/icons.json` expanded with new entries.
- Validation: added `tools/validate_icons.py` and `tools/validate_icons.ps1` to verify catalog ↔ manifest ↔ assets.
- CI: GitHub Actions workflow `.github/workflows/validate-icons.yml` runs icon validation + `flutter test` on push/PR.

### Changed
- `pubspec.yaml` updated to include new SVG assets and manifest.
- `docs/ICON_REPO_GUIDE.md` clarifications and CI instructions added.
- Smart Ledger input field prototype: `lib/widgets/smart_input_field.dart` and transaction screen updates.
- Documentation: refreshed Smart Ledger main-screen references (`tools/LEGACY_USER_MAIN_LOCATION.md`, `tools/INDEX_CODE_FEATURES.md`) and recorded design checklist status for `SmartInputField` rollout.

### Notes
- Image processing performance optimizations (Isolate/compute) are scheduled after design/icon work is finalized.

## [Unreleased] - 2026-01-08

### Changed
- Shopping recommendations: apply household activity trend ratio (short vs baseline) to suggested quantities, with clamped scaling and memo note.
- Quick stock use: apply the same activity ratio to auto-added “imminent depletion” shopping items.

### Notes
- 2026-01-09 checkpoint: `lib/**/*.dart` has 0 lines over 80 chars; `flutter analyze` reports no issues; import-style work continues (next: mixed import style cleanup).
