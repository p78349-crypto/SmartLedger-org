part of 'account_main_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension IconGridPageSlots on _IconGridPageState {
  Future<void> _loadSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final assetLockEnabled =
        prefs.getBool(PrefKeys.biometricAuthEnabled) ?? false;
    final allowAssetOutsideWhenUnlocked =
        prefs.getBool(PrefKeys.iconAllowAssetIconsOutsideAssetWhenUnlocked) ??
        false;
    final untilMs = prefs.getInt(PrefKeys.assetAuthSessionUntilMs);
    final assetSessionUnlocked =
        untilMs != null && DateTime.now().millisecondsSinceEpoch < untilMs;

    final slots = await UserPrefService.getPageIconSlots(
      accountName: widget.accountName,
      pageIndex: widget.pageIndex,
    );
    final validated = slots.map((s) {
      final id = s.trim();
      if (id.isEmpty) return '';
      if (!_allKnownIconIds.contains(id)) return '';
      final allowed = _isAllowedOnPage(
        pageIndex: widget.pageIndex,
        iconId: id,
        assetLockEnabled: assetLockEnabled,
        allowAssetOutsideWhenUnlocked: allowAssetOutsideWhenUnlocked,
        assetSessionUnlocked: assetSessionUnlocked,
      );
      return allowed ? id : '';
    }).toList();

    // If slots are empty (or became empty after applying page policy), prefill
    // from available icons (visible + allowed set).
    final allEmptyStored = slots.every((s) => s.isEmpty);
    final allEmptyAfterValidation = validated.every((s) => s.isEmpty);
    final isReservedPage =
        _isStatsReservedPage(widget.pageIndex) ||
        _isAssetReservedPage(widget.pageIndex) ||
        _isRootReservedPage(widget.pageIndex) ||
        _isSettingsOnlyPage(widget.pageIndex);

    if (allEmptyStored || (isReservedPage && allEmptyAfterValidation)) {
      final visibleAndAllowedIcons = _getOrderedIcons()
          .where(
            (i) => _isAllowedOnPage(
              pageIndex: widget.pageIndex,
              iconId: i.id,
              assetLockEnabled: assetLockEnabled,
              allowAssetOutsideWhenUnlocked: allowAssetOutsideWhenUnlocked,
              assetSessionUnlocked: assetSessionUnlocked,
            ),
          )
          .toList();

      var writeIndex = 0;
      for (final icon in visibleAndAllowedIcons) {
        if (writeIndex >= _defaultSlotCount) break;
        validated[writeIndex] = icon.id;
        writeIndex++;
      }

      await UserPrefService.setPageIconSlots(
        accountName: widget.accountName,
        pageIndex: widget.pageIndex,
        slots: validated,
      );
    }

    // Page 1 convenience: if the screen saver shortcut is missing, try to
    // place it next to '오늘 지출' without overwriting any existing slot.
    if (widget.pageIndex == ScreenSaverIds.shortcutAllowedMainPageIndex) {
      _ensureScreenSaverShortcut(validated);
    }

    // Page 0: ensure "음성 단축어" is visible early.
    if (widget.pageIndex == 0) {
      _ensureVoiceShortcuts(validated);
    }

    if (!mounted) return;
    setState(() {
      _slots = validated;
    });
  }

  Future<void> _ensureScreenSaverShortcut(List<String> validated) async {
    final hasShortcut = validated.contains(ScreenSaverIds.shortcutIconId);
    if (hasShortcut) return;

    const preferredIndex = 1;
    final preferredEmpty =
        preferredIndex < validated.length &&
        validated[preferredIndex].isEmpty;
    if (preferredEmpty) {
      validated[preferredIndex] = ScreenSaverIds.shortcutIconId;
    } else {
      final emptyIndex = validated.indexOf('');
      if (emptyIndex != -1) {
        validated[emptyIndex] = ScreenSaverIds.shortcutIconId;
      }
    }
    await UserPrefService.setPageIconSlots(
      accountName: widget.accountName,
      pageIndex: widget.pageIndex,
      slots: validated,
    );
  }

  Future<void> _ensureVoiceShortcuts(List<String> validated) async {
    final hasVoiceShortcuts = validated.contains(_voiceShortcutsIconId);
    if (hasVoiceShortcuts) return;

    const preferredIndex = 0;
    final preferredEmpty =
        preferredIndex < validated.length &&
        validated[preferredIndex].isEmpty;
    if (preferredEmpty) {
      validated[preferredIndex] = _voiceShortcutsIconId;
    } else {
      final emptyIndex = validated.indexOf('');
      if (emptyIndex != -1) {
        validated[emptyIndex] = _voiceShortcutsIconId;
      }
    }
    await UserPrefService.setPageIconSlots(
      accountName: widget.accountName,
      pageIndex: widget.pageIndex,
      slots: validated,
    );
  }

  Future<void> _saveSlotsDebounced() async {
    if (_isSavingSlots) return; // simple guard
    _isSavingSlots = true;
    try {
      await UserPrefService.setPageIconSlots(
        accountName: widget.accountName,
        pageIndex: widget.pageIndex,
        slots: _slots,
      );
    } finally {
      _isSavingSlots = false;
    }
  }

  void _assignOrSwap(String draggedId, int targetIndex) {
    setState(() {
      final currentIndex = _slots.indexOf(draggedId);
      if (currentIndex == -1) {
        // dragged from palette, assign into slot
        _slots[targetIndex] = draggedId;
      } else {
        // dragged from another slot -> swap
        final temp = _slots[targetIndex];
        _slots[targetIndex] = draggedId;
        _slots[currentIndex] = temp;
      }
    });
    _saveSlotsDebounced();
  }

  void _navigateToIcon(MainFeatureIcon icon) {
    if (icon.id == ScreenSaverIds.shortcutIconId) {
      ScreenSaverLauncher.show(
        context: context,
        accountName: widget.accountName,
      );
      return;
    }
    if (icon.id == 'accountStatsMemoSearch') {
      MemoSearchUtils.openMemoOnlySearch(
        context,
        accountName: widget.accountName,
      );
      return;
    }
    if (icon.id == 'accountStatsMemoStats') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MemoStatsScreen(accountName: widget.accountName),
        ),
      );
      return;
    }
    if (icon.routeName == null) {
      debugPrint('🔴 Icon ${icon.id} has no routeName');
      return;
    }

    final request = IconLaunchUtils.buildRequest(
      routeName: icon.routeName!,
      accountName: widget.accountName,
    );
    if (request == null) {
      debugPrint('🔴 Failed to build request for route: ${icon.routeName}');
      return;
    }

    debugPrint(
      '🟢 Navigating to: ${request.routeName} with args: ${request.arguments}',
    );

    Navigator.of(context)
        .pushNamed(request.routeName, arguments: request.arguments)
        .catchError((error) {
          debugPrint('🔴 Navigation error: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('화면 이동 실패: $error')),
            );
          }
          return null;
        });
  }
}
