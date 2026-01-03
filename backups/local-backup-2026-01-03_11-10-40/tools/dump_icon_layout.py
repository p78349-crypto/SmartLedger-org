from __future__ import annotations

import re
from pathlib import Path

CATALOG = Path(__file__).resolve().parents[1] / "lib" / "utils" / "main_feature_icon_catalog.dart"


def main() -> None:
    text = CATALOG.read_text(encoding="utf-8").splitlines()
    page: int | None = None
    icons: list[dict[str, object]] = []
    current: dict[str, object] | None = None

    for line in text:
        m = re.search(r"MainFeaturePage\(index:\s*(\d+)", line)
        if m:
            page = int(m.group(1))
            continue

        if page is None:
            continue

        if "MainFeatureIcon(" in line:
            current = {"page": page, "id": None, "label": None, "route": None}
            continue

        if current is not None:
            m = re.search(r"id:\s*'([^']+)'", line)
            if m:
                current["id"] = m.group(1)
            m = re.search(r"label:\s*'([^']+)'", line)
            if m:
                current["label"] = m.group(1).replace("\\n", "/")
            m = re.search(r"routeName:\s*AppRoutes\.([A-Za-z0-9_]+)", line)
            if m:
                current["route"] = m.group(1)

            if re.match(r"^\s*\),\s*$", line) and current.get("id"):
                icons.append(current)
                current = None

    pages = sorted({int(i["page"]) for i in icons})

    print("Icon layout by page")
    for p in pages:
        print(f"\n=== Page {p} ===")
        for i in [x for x in icons if int(x["page"]) == p]:
            ident = str(i.get("id") or "")
            label = str(i.get("label") or "")
            route = str(i.get("route") or "")
            print(f"- {ident} | {label} | {route}")


if __name__ == "__main__":
    main()
