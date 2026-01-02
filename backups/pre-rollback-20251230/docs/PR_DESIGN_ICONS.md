PR draft: "Add initial custom icon set, manifest, and validation"

Overview
--------
This PR adds:
- 12 sample custom SVG icons under `assets/icons/custom/` (icon_01.svg .. icon_12.svg)
- Expanded icon manifest `assets/icons/metadata/icons.json` with new entries
- `tools/validate_icons.py` and `tools/validate_icons.ps1` for validation
- `.github/workflows/validate-icons.yml` to run validation and `flutter test` on push/PR
- `test/icon_asset_mapping_test.dart` to ensure manifest references exist
- `docs/ICON_REPO_GUIDE.md` updates and `CHANGELOG.md` entry

Testing & Verification
----------------------
- Local PowerShell validator: `pwsh .\tools\validate_icons.ps1` (Windows)
- Local Python validator: `python tools/validate_icons.py` (requires Python)
- Flutter tests: `flutter test`
- CI runs the above on PRs automatically

Design review checklist (for reviewers)
--------------------------------------
- [ ] Approve icon shapes & sizes (view each SVG)
- [ ] Confirm icon naming convention (id matches `MainFeatureIcon.id` if mapping desired)
- [ ] Confirm license/attribution fields in `icons.json`
- [ ] Confirm `pubspec.yaml` asset registration
- [ ] Ensure validation script and tests pass locally

Notes for maintainers
---------------------
- If you add new custom icons, update `assets/icons/metadata/icons.json` and ensure assets are added to `pubspec.yaml`.
- The project supports 24 icon slots per page; consider prioritizing top N features for custom icon design.
