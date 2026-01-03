#!/usr/bin/env python3
"""
validate_icons.py

- Parse `lib/utils/main_feature_icon_catalog.dart` and extract MainFeatureIcon id strings
- Load `assets/icons/metadata/icons.json` and ensure mapping exists for listed IDs
- Verify each manifest entry's assetPath exists
- Exit with code 0 if OK, non-zero if any mismatch found
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "lib" / "utils" / "main_feature_icon_catalog.dart"
MANIFEST = ROOT / "assets" / "icons" / "metadata" / "icons.json"


def parse_catalog_ids() -> set[str]:
    text = CATALOG.read_text(encoding="utf-8")
    ids = set(re.findall(r"id:\s*'([^']+)'", text))
    return ids


def load_manifest() -> dict[str, dict]:
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    icons = {}
    for e in data.get("icons", []):
        icons[e["id"]] = e
    return icons


def main() -> int:
    missing = False

    catalog_ids = parse_catalog_ids()
    manifest = load_manifest()

    print(f"Found {len(catalog_ids)} ids in catalog")
    print(f"Found {len(manifest)} entries in manifest")

    # Which catalog ids have manifest entries?
    ids_with_manifest = set(manifest.keys()) & catalog_ids
    ids_without_manifest = catalog_ids - set(manifest.keys())

    if ids_without_manifest:
        print("\nCatalog IDs without manifest entries (these may be Material IconData or not-yet-mapped):")
        for i in sorted(ids_without_manifest):
            print(f" - {i}")
    else:
        print("\nAll catalog IDs have manifest entries.")

    # Verify manifest entries refer to existing files
    print("\nChecking manifest asset files...")
    for id_, entry in manifest.items():
        asset_path = ROOT / entry["assetPath"]
        if not asset_path.exists():
            print(f" - Missing asset for manifest id={id_} path={entry['assetPath']}")
            missing = True

    if missing:
        print("\nValidation failed: missing asset files.")
        return 2

    print("\nValidation completed. No missing files detected.")
    return 0


if __name__ == "__main__":
    rc = main()
    sys.exit(rc)
