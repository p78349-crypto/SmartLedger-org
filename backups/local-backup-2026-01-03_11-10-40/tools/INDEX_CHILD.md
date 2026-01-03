# INDEX (Child) — Per-File Details (Search Hints)

목적: Parent에서 고른 파일을 열기 전에 “무슨 키워드로/어디를” 검색할지 단서를 제공.

규칙
- 설명은 짧게, 대신 “검색 단서”를 많이.
- 가능한 경우: Screen/Service/Route/Args/PrefKeys/Widget Key/Test finder를 함께 적는다.

---

## lib/main.dart

- Entry: `LaunchScreen`, `AppRouter.onGenerateRoute`
- Search hints: `MaterialApp`, `onGenerateRoute`, `LaunchScreen`

## lib/screens/launch_screen.dart

- Flow: 시작→마지막 계정 확인→`AppRoutes.accountMain` 이동
- Search hints: `_goToAccountMain`, `pushReplacement`, `UserPrefService`

## lib/navigation/app_routes.dart

- Defines: `AppRoutes.*` + `*Args` classes
- Search hints: `AccountMainArgs`, `AccountArgs`, `TransactionAddArgs`

## lib/navigation/app_router.dart

- Central routing: `onGenerateRoute`에서 `settings.arguments as ...`
- Search hints: `switch (settings.name)`, `MaterialPageRoute`, `as AccountArgs`

## lib/screens/account_main_screen.dart

- Main UI: PageView/배너/아이콘 그리드
- Search hints: `PageController`, `_PageBannerBar`, `main_icon_slot_`, `IconActionsMenu`
- Reserved page policy (user-facing 1-based page numbers):
	- 4~5=통계(Stats), 6~7=자산(Asset), 8~9=ROOT, 10=설정(Settings)
- Reserved page policy (0-based indices used in code):
	- stats={3,4}, asset={5,6}, root={7,8}, settings={9}
- Search hints (policy): `_statsReservedPages`, `_assetReservedPages`, `_rootReservedPages`, `_settingsOnlyPages`, `_isAllowedOnPage`
- Search hints (policy): `_statsReservedPages`, `_assetReservedPages`, `_rootReservedPages`, `_settingsOnlyPages`, `_isAllowedOnPage`
- Search hints (shortcut): `shortcut_settings_page10`, `onRequestJumpToPage`, `_settingsReservedPageIndex`
- Search hints (reserved icons): `_iconsForReservedPage`, `_getOrderedIcons`, `_loadSlots`, `_normalizeReservedPageIconSlotsBestEffort`
- Behavior notes: ROOT/설정 페이지 아이콘이 비면 모듈 SSOT 기반 best-effort 자동 채움(테스트용 가시성 확보)

## lib/utils/pref_keys.dart

- PrefKeys SSOT: settings/feature/security flags
- Search hints (ROOT auth): `PrefKeys.rootAuthMode`, `PrefKeys.rootAuthSessionUntilMs`, `settingKeys`

## lib/screens/asset_tab_screen.dart

- Asset security UI + ROOT 보안(통합/별도) 옵션 선택
- Search hints: `PrefKeys.assetSecurityEnabled`, `PrefKeys.rootAuthMode`, `RadioListTile`, `integrated`, `separate`

## lib/widgets/root_auth_gate.dart

- ROOT auth enforcement widget (통합/별도 모드)
- Search hints: `RootAuthGate`, `LocalAuthentication`, `_ensureAssetSession`, `_ensureRootSession`, `PrefKeys.rootAuthSessionUntilMs`

## lib/screens/root_transaction_manager_screen.dart

- ROOT screen: wraps UI with `RootAuthGate`
- Search hints: `RootAuthGate`, `RootTransactionManagerScreen`

## lib/screens/root_search_screen.dart

- ROOT screen: wraps UI with `RootAuthGate`
- Search hints: `RootAuthGate`, `RootSearchScreen`

## lib/screens/root_account_manage_screen.dart

- ROOT screen: wraps UI with `RootAuthGate`
- Search hints: `RootAuthGate`, `RootAccountManageScreen`

## lib/screens/root_month_end_screen.dart

- ROOT screen: wraps UI with `RootAuthGate`
- Search hints: `RootAuthGate`, `RootMonthEndScreen`

## lib/screens/icon_management_screen.dart

- Icon management hub: 슬롯 탭→(add 모드) 카탈로그 선택→적용
- Search hints (state): `_catalogOnlyUnplaced`, `_pendingIds`, `_targetSlotIndex`, `_mode`
- Search hints (widget keys): `icon_mgmt_slot_`, `ValueKey('icon_mgmt_slot_')`
- Search hints (catalog): `MainFeatureIconCatalog`, `pageCount`, `pages`, `_CatalogSection`
- Reserved page policy (page picker / placement rules):
	- 4~5=통계(Stats), 6~7=자산(Asset), 8~9=ROOT, 10=설정(Settings)
	- (0-based indices) stats={3,4}, asset={5,6}, root={7,8}, settings={9}
- Search hints (policy): `_isAllowedOnPage`, `_isBlockedForPage`, `_updateSpecialPageIndices`, `_assetPageIndex`, `_rootPageIndex`
- Search hints (policy): `_isAllowedOnPage`, `_isBlockedForPage`, `_updateSpecialPageIndices`, `_assetPageIndex`, `_rootPageIndex`
- Search hints (shortcut): `shortcut_settings_page10`
- Behavior notes: (REMOVED) 1페이지 하단 4칸 전용 편집 모드/allowlist 정책 제거 → 모든 페이지는 12칸 전체 그리드 편집
- Behavior notes: 드롭/배치는 예약 페이지 정책(4~10 전용 규칙)으로 계속 차단될 수 있음(`_isBlockedForCurrentPage`)

## lib/utils/main_feature_icon_catalog.dart

- Icon SSOT: `MainFeatureIconCatalog.pages` / `MainFeatureIcon.id`
- Search hints (shortcut): `shortcut_settings_page10`, `10페이지\n이동`

## lib/screens/shopping_cart_screen.dart

- Shopping cart UI: 상단 입력(AppBar.bottom) + 리스트(체크/거래추가/삭제) + 하단 합계/일괄 입력
- Search hints (top input): `AppBar.bottom`, `PreferredSize`, `TextField`, `FilledButton`
- Search hints (row): `_toggleChecked`, `_confirmAndDeleteItem`, `_deleteItem`, `IconButton`
- Search hints (inline editors): `_syncInlineControllers`, `_applyInlineEdits`, `_unitPriceTextForInlineEditor`, `_qtyControllers`, `_unitPriceControllers`, `_qtyFocusNodes`, `_unitPriceFocusNodes`
- Search hints (bottom bar): `bottomNavigationBar`, `_buildCheckedSummaryBar`, `checkedTotal`, `_addCheckedItemsToLedgerBulk`, `CurrencyFormatter.format`
- Search hints (prep): `ShoppingCartNextPrepUtils.run`, `ShoppingCartNextPrepDialogUtils`

## lib/screens/shopping_cheapest_month_screen.dart

- Stats UI: 품목명 입력 → 최근 1년 '식비' 단가 기반 최저월 분석
- Search hints (load): `_loadData`, `TransactionService().loadTransactions()`, `_transactions`
- Search hints (analysis): `ShoppingPriceSeasonalityUtils.cheapestMonthLastYear`, `_runAnalysis`, `hintKo`
- Search hints (UX): `SnackbarUtils.show`, `FilledButton.icon`, `TextField(onSubmitted)`

## lib/utils/shopping_price_seasonality_utils.dart

- Algorithm: 최근 365일 / expense + mainCategory=='식비' / unitPrice>0 / 품목명 normalize match
- Search hints: `cheapestMonthLastYear`, `minSamplesPerMonth`, `minTotalSamples`, `_medianOfSorted`
- Output: `ShoppingCheapestMonthResult`, `hintKo`, `monthLabelKo`

## lib/screens/backup_screen.dart

- Backup UI: 파일 목록/복원/삭제/상태 표시
- Search hints: `BackupService`, `Directory('/storage/emulated/0/Download')`, `FilePicker`
- Backup security options (user-selectable in this screen):
	- 암호화(필수): `PrefKeys.backupEncryptionEnabled`
	- 2단계(옵션, 기기 인증 추가): `PrefKeys.backupTwoFactorEnabled`
- Search hints (encryption): `_prepareBackupEncryptionPassword`, `_prepareRestorePasswordIfNeeded`, `BackupService().isEncryptedBackupText(...)`, `BackupCrypto.*`

## lib/services/backup_service.dart

- Backup core: export/import JSON + file I/O + lastBackup 저장
- Search hints: `saveBackupToDownloads`, `restoreFromFile`, `exportAccountData`, `importAccountDataAsNew`
- Auto-backup skip condition: `PrefKeys.backupEncryptionEnabled` (password input needed)

## lib/screens/privacy_policy_screen.dart

- Privacy UI: 정책 표시 + 동의 저장
- Search hints: `PrefKeys.privacyPolicyConsentChoice`, `SharedPreferences`, `_PrivacyConsentChoice`

## test/screens/account_main_icon_picker_test.dart

- Widget tests: 아이콘 다중 선택/일괄 적용 + rename/remove
- Search hints: `icon_mgmt_slot_8`, `하단에서 추가할 아이콘을 체크하세요`, `scrollUntilVisible`

## .vscode/tasks.json

- VS Code tasks: build/analyze/test/INDEX export/validate
- Search hints: `Quality Gate`, `Validate INDEX format`, `Open Find INDEX`, `Check long lines`

## tools/open_find_indexes.ps1

- Opens: `tools/INDEX_PARENT.md`, `tools/INDEX_CHILD.md`
- Search hints: `ReuseWindow`, `Open-FileInEditor`, `code --reuse-window`

## tools/check_long_lines.ps1

- Checks: `lib/**/*.dart` line length (default 80)
- Search hints: `MaxLen`, `Select-String -AllMatches`, `Pattern = ".{...}"`

## SECURITY_GUIDE.md

- User guide: 자산/ROOT 보안(통합/별도) + 백업/복원 암호화/2단계 동작 설명
- Search hints: `자산 보안`, `ROOT 보안`, `통합`, `별도`, `1분`, `백업 암호화`, `2단계`, `기기 인증`, `암호 4자`
