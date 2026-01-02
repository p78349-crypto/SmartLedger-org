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
- One UI input field prototype: `lib/widgets/one_ui_input_field.dart` and transaction screen updates.

### Notes
- Image processing performance optimizations (Isolate/compute) are scheduled after design/icon work is finalized.
