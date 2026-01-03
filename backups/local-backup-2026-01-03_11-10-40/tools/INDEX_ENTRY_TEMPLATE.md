# INDEX Entry Template

Use this template when adding a new line to `tools/INDEX_CODE_FEATURES.md`.
Keep entries short and factual — one line per change.

Format (Markdown table row):
| Date | What changed | Old | New | Note |

Example:
| 2025-12-19 | CI: PR-level INDEX check 추가 | (없음) | .github/workflows/index-check.yml 추가 | PR에서 소스 변경 시 INDEX 갱신 필수 (CI 차단) |

Suggested Note format (recommended)

- Use a single cell with key/value parts separated by `;`.
- Recommended keys: `Playbook`, `Why`, `Verify`, `Risk`, `Tests`, `Files`.

Example:
| 2025-12-19 | AccountMainScreen analyzer 에러 제거 | analyze 에러 다수 | error 0 (info만 남김) | Playbook=AccountMainScreen; Why=빌드 차단 해소; Verify=flutter analyze; Tests=flutter test(일부 실패 확인); Files=lib/screens/account_main_screen.dart |

Tips:
- Use ISO date YYYY-MM-DD.
- Include file paths in the Note when relevant.
- Keep the What changed column concise (5–10 words).
