# Page Reconnection Plan (Template)

Purpose: Safely re-enable main pages one-by-one after a global block. Follow the checklist for each page to avoid data loss and regression.

## How to use
- Work page-by-page (0-based index). Complete all steps for the page before moving to the next.
- Keep a backup snapshot of prefs for the account under test before any change.

---

## Global pre-checks (do once)
- [ ] Create prefs backup: dump `main_page_configs`, `main_page_index`, and all `page_{i}_*` keys for the target account. Save JSON with timestamp. (See `UserPrefService` keys.)
- [ ] Ensure code base has `MainFeatureIconCatalog.setPagesBlocked(false)` available to enable pages at runtime.
- [ ] Run `flutter analyze` and fix any existing errors.
- [ ] Decide migration policy: (A) restore prefs from backup for the specific page, (B) map old keys into new layout, or (C) start empty.

---

## Per-page checklist (repeat for each pageIndex)
Replace `PAGE_INDEX` with the 0-based page index.

1. Identify affected artifacts
   - [ ] List prefs keys: `page_PAGE_INDEX_icon_order`, `page_PAGE_INDEX_icon_slots`, `page_PAGE_INDEX_slot_groups`, any `main_page_names` entries.
   - [ ] Find code references that treat `PAGE_INDEX` as reserved or special (search `widget.pageIndex == PAGE_INDEX`, `initialPageIndex: PAGE_INDEX`).

2. Backup (required)
   - [ ] Dump current pref keys for `PAGE_INDEX` (JSON file: `backup_page_PAGE_INDEX_<account>_<ts>.json`).

3. Migrate or restore data
   - [ ] If restoring: inject the backed-up keys for the target account. Verify values are valid JSON/expected length.
   - [ ] If migrating: transform legacy keys to current schema and write them via `UserPrefService` helpers.
   - [ ] If starting empty: ensure any consuming code tolerates empty slots for this page.

4. Enable page runtime flag
   - [ ] Call `MainFeatureIconCatalog.setPagesBlocked(false)` if enabling globally; alternatively expose per-page enable API (not currently implemented).
   - [ ] Restart app or reload relevant widgets to pick up catalog changes.

5. Verify UI and behavior
   - [ ] Open `AccountMainScreen` and navigate to the page. Confirm icons shown as expected.
   - [ ] Verify `IconManagementScreen` shows page section and allows edits.
   - [ ] Test quick actions and bottom `Page1BottomQuickIcons` (if page 0) for regressions.
   - [ ] Verify no reserved-page conflicts (settings/asset/stats indices) caused by enabling this page.

6. Run smoke tests
   - [ ] `flutter analyze` (no new issues)
   - [ ] Manual flows: open page, launch each icon route, open icon management, rename page, reset page.

7. Persist and document
   - [ ] If migration performed, save transformation script and commit under `tools/migrations/`.
   - [ ] Mark page as "reconnected" in project tracking (e.g., update `docs/page_reconnect_status.md`).

8. Rollback plan (if issues found)
   - [ ] Re-apply backup JSON to restore prefs for the account.
   - [ ] Call `MainFeatureIconCatalog.setPagesBlocked(true)` to re-block pages if needed.
   - [ ] Revert code changes or migration commits as necessary.

---

## Acceptance criteria (per page)
- Page loads without exceptions and icons/routes behave as before.
- No prefs corruption; backups allow full restore.
- Reserved page indices still align with app expectations.
- Automated and manual smoke tests pass.

---

## Notes & recommendations
- Prefer enabling one non-reserved page first as a dry run.
- Implement a per-page enable API if re-enabling individual pages is required in the future.
- Keep migration scripts idempotent and reversible.



