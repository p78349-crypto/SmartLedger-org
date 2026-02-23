part of 'account_main_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension AccountMainHelpers on _AccountMainScreenState {
  Future<void> _confirmAndResetMainPages() async {
    if (!mounted) return;

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메인 페이지 초기화'),
        content: const Text(
          '메인 페이지(0~14) 구성과 아이콘 배치가 모두 초기화됩니다.\n'
          '※ 거래/자산 등 데이터는 삭제되지 않습니다. (배치만 초기화)\n\n'
          '계속할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('초기화'),
          ),
        ],
      ),
    );

    if (shouldReset != true) return;

    final rawAccountName = widget.accountName;
    final trimmedAccountName = rawAccountName.trim();

    // Defensive: some legacy data may have been saved with accidental
    // whitespace differences in the account name.
    await UserPrefService.resetAccountMainPages(
      accountName: rawAccountName,
      pageCount: _pageCount,
    );
    if (trimmedAccountName.isNotEmpty && trimmedAccountName != rawAccountName) {
      await UserPrefService.resetAccountMainPages(
        accountName: trimmedAccountName,
        pageCount: _pageCount,
      );
    }

    if (!mounted) return;

    setState(() {
      _currentIndex = 0;
    });
    _controller.jumpToPage(0);

    for (final key in _pageKeys) {
      await key.currentState?.reloadFromPrefsPublic();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('메인 페이지가 초기화되었습니다')));
  }

  void _showQuickJumpSheet() {
    final total = _pageCount;
    if (total <= 1) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  '페이지 바로가기',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...List.generate(total, (index) {
                // ROOT 페이지(인덱스 5) 숨김 처리
                if (_hideRootPage && index == 5) {
                  return const SizedBox.shrink();
                }
                final label = _pageNameLabels[index];
                // ROOT 페이지를 건너뛴 디스플레이 인덱스 계산
                final displayIndex = _hideRootPage && index > 5 ? index - 1 : index;
                return ListTile(
                  title: Text(label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _controller.animateToPage(
                      displayIndex,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // NOTE: Kept intentionally for future opt-in/manual use.
  // ignore: unused_element
  Future<void> _normalizeReservedPageIconSlotsBestEffort() async {
    // Fire-and-forget. Avoid blocking first paint.
    try {
      // Asset page policy: asset icons are fixed to index 4.
      // Safety: never drops icons; if targets are full, leaves as-is.
      const enforceAssetPlacement = true;

      // Icon-id sets by module (derived from the catalog SSOT).
      final statsIds = <String>{
        ...MainFeatureIconCatalog.iconsForModuleKey('stats').map((e) => e.id),
      };

      final assetIds = MainFeatureIconCatalog.iconsForModuleKey(
        'asset',
      ).map((e) => e.id).toSet();

      final rootIds = MainFeatureIconCatalog.iconsForModuleKey(
        'root',
      ).map((e) => e.id).toSet();
      final settingsIds = MainFeatureIconCatalog.iconsForModuleKey(
        'settings',
      ).map((e) => e.id).toSet();

      // Policy pages (0-based main page indices).
      const statsTargetPages = <int>[3];
      const assetTargetPages = <int>[4];
      const rootTargetPages = <int>[5];
      const settingsTargetPages = <int>[6];

      List<int> targetsForId(String id) {
        if (settingsIds.contains(id)) return settingsTargetPages;
        if (rootIds.contains(id)) return rootTargetPages;
        if (enforceAssetPlacement && assetIds.contains(id)) {
          return assetTargetPages;
        }
        if (statsIds.contains(id)) return statsTargetPages;
        return const <int>[];
      }

      bool isReservedId(String id) {
        return statsIds.contains(id) ||
            (enforceAssetPlacement && assetIds.contains(id)) ||
            rootIds.contains(id) ||
            settingsIds.contains(id);
      }

      // Load all pages.
      final pages = <int, List<String>>{};
      for (int i = 0; i < _pageCount; i++) {
        pages[i] = await UserPrefService.getPageIconSlots(
          accountName: widget.accountName,
          pageIndex: i,
        );
      }

      // De-duplicate: keep first occurrence across all pages, drop the rest.
      final seen = <String>{};
      for (int pageIndex = 0; pageIndex < _pageCount; pageIndex++) {
        final slots = pages[pageIndex]!;
        for (int si = 0; si < slots.length; si++) {
          final id = slots[si];
          if (id.isEmpty) continue;
          if (seen.add(id)) continue;
          slots[si] = '';
        }
      }

      // Collect moves (id -> target pages), clear from illegal pages.
      final moves = <String, List<int>>{};
      for (int pageIndex = 0; pageIndex < _pageCount; pageIndex++) {
        final slots = pages[pageIndex]!;
        for (int si = 0; si < slots.length; si++) {
          final id = slots[si];
          if (id.isEmpty) continue;
          if (!isReservedId(id)) continue;

          final targets = targetsForId(id);
          if (targets.isEmpty) continue;

          // If current page is not allowed, move.
          if (!targets.contains(pageIndex)) {
            moves[id] = targets;
            slots[si] = '';
          }
        }
      }

      // Apply moves: place into first empty slot across target pages.
      for (final entry in moves.entries) {
        final id = entry.key;
        final targets = entry.value;

        var placed = false;
        for (final pageIndex in targets) {
          final slots = pages[pageIndex]!;
          final emptyIndex = slots.indexOf('');
          if (emptyIndex == -1) continue;
          slots[emptyIndex] = id;
          placed = true;
          break;
        }

        // If targets are full, keep behavior safe: do not drop.
        if (!placed) {
          final fallbackPage = targets.first;
          final fallbackSlots = pages[fallbackPage]!;
          final emptyIndex = fallbackSlots.indexOf('');
          if (emptyIndex != -1) {
            fallbackSlots[emptyIndex] = id;
          }
        }
      }

      // Persist only if changed.
      for (int i = 0; i < _pageCount; i++) {
        final next = pages[i]!;
        final current = await UserPrefService.getPageIconSlots(
          accountName: widget.accountName,
          pageIndex: i,
        );
        if (_listEquals(current, next)) continue;
        await UserPrefService.setPageIconSlots(
          accountName: widget.accountName,
          pageIndex: i,
          slots: next,
        );
      }
    } catch (_) {
      // Best-effort: ignore.
    }
  }

  Future<void> _restoreSavedIndexIfNeeded() async {
    // If caller explicitly provided a non-zero initial index, respect it.
    if (widget.initialIndex != 0) return;

    final saved = await UserPrefService.getMainPageIndex(
      accountName: widget.accountName,
    );
    if (!mounted) return;

    var desired =
        _pageCount > 0 ? (saved ?? 0).clamp(0, _pageCount - 1) : 0;
    
    // ROOT 페이지가 숨겨진 경우, ROOT 페이지(5)로 복원하려고 하면 대시보드(0)로 이동
    if (_hideRootPage && desired == 5) {
      desired = 0;
    }
    
    // ROOT 페이지를 건너뛴 디스플레이 인덱스 계산
    if (_hideRootPage && desired > 5) {
      desired = desired - 1;
    }
    
    if (desired == _currentIndex) return;

    _isRestoringIndex = true;
    _currentIndex = _hideRootPage && desired >= 5 ? desired + 1 : desired;
    _controller.jumpToPage(desired);
    _isRestoringIndex = false;
  }
}
