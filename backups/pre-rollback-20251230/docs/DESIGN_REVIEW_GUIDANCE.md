# Design review guidance for custom icons

Purpose: Ensure visual consistency, legibility, and accessibility for all custom icons.

Checks:
- Size & viewport: `viewBox="0 0 24 24"` and icons designed to be legible at 20–28 px
- Single-color vs multi-color: Prefer single color (use `currentColor`) for theme/color flexibility
- File size: Prefer <8 KB per SVG where possible
- Contrast: Ensure icon shapes are distinguishable in light/dark themes
- Naming: `id` in manifest should be meaningful (e.g., `asset_dashboard`) and match `MainFeatureIcon.id` when used for feature mapping
- Variants: Provide `outlined`/`filled` variants only if necessary; add to `variants` array in manifest

Review process:
- Designer verifies shapes and files, adds comments to PR
- Developer addresses feedback and re-submits
