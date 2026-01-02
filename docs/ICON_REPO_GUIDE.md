# ICON_REPO_GUIDE

This guide explains how to add and maintain custom SVG icons for the project.

## Structure
- `assets/icons/custom/` — SVG files
- `assets/icons/metadata/icons.json` — manifest mapping `id` -> `assetPath`

## Manifest fields
- `id` (string): matches `MainFeatureIcon.id` if you plan to map a feature to a custom asset
- `assetPath` (string): relative path to SVG
- `designer` (string): who created the icon
- `license` (string): license or terms (e.g., `CC-BY-4.0`)
- `variants` (array): optional variant names

## SVG guidelines
- Use viewBox=0 0 24 24
- Single color fill preferred; use `currentColor` where possible
- Keep file size under 8 KB where possible

## Workflow
1. Add SVG to `assets/icons/custom/` and commit.  
2. Add manifest entry in `assets/icons/metadata/icons.json`.  
3. Run `python tools/validate_icons.py` locally (or `tools\validate_icons.ps1` on Windows), or rely on CI which runs the validation during PR checks.  
4. CI: `.github/workflows/validate-icons.yml` runs icon validation and `flutter test` on push/PR.  

