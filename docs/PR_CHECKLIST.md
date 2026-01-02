PR Checklist for Icon/Additions & Validation

- [ ] Include new SVGs under `assets/icons/custom/`
- [ ] Update `assets/icons/metadata/icons.json` with entries for each new icon
- [ ] Register new assets in `pubspec.yaml`
- [ ] Run local validator (`python tools/validate_icons.py` or `pwsh .\tools\validate_icons.ps1`)
- [ ] Ensure `flutter test` passes locally
- [ ] Add/Update design review comments for each icon (size/legibility/contrast)
- [ ] Tag designer(s) for visual verification
- [ ] Link to CHANGELOG entry summarizing the addition
