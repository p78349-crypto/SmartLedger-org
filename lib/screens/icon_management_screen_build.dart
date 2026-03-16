// ignore_for_file: invalid_use_of_protected_member

part of 'icon_management_screen.dart';

/// Catalog icon tile, apply button, and main build.
extension IconManagementBuild on _IconManagementScreenState {
  Widget _photoTopBoxButton(
    ThemeData theme, {
    required String title,
    String? subtitle,
    required VoidCallback? onTap,
    bool selected = false,
  }) {
    final scheme = theme.colorScheme;
    final borderColor = scheme.onSurface;
    final bg = selected
        ? scheme.surfaceContainerHighest
        : scheme.surface;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 2.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              if (subtitle != null && subtitle.trim().isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 기본아이콘 탭 터치 - 기본 아이콘 세트로 리셋
  void _onDefaultIconsTabTap() {
    setState(() {
      _photoCatalogTab = 0;
      // 기본 아이콘 목록으로 _pendingIds 리셋
      final defaultIcons = _autoFillSourceIconsForPage(_pageIndex)
          .where((icon) => !_isBlockedForCurrentPage(icon.id))
          .map((icon) => icon.id)
          .toSet();
      _pendingIds
        ..clear()
        ..addAll(defaultIcons);
    });
  }

  /// 전체아이콘 탭 터치 - 숨겨진 아이콘까지 모두 표시
  void _onAllIconsTabTap() {
    setState(() {
      _photoCatalogTab = 1;
      // 모든 아이콘을 _pendingIds에 추가
      final allIcons = <String>{};
      for (final page in MainFeatureIconCatalog.pages) {
        if (_catalogHiddenPages.contains(page.index)) continue;
        for (final icon in page.items) {
          if (_isBlockedForCurrentPage(icon.id)) continue;
          if (_isExcludedByDedicatedCatalogPolicy(icon.id)) continue;
          allIcons.add(icon.id);
        }
      }
      _pendingIds
        ..clear()
        ..addAll(allIcons);
    });
  }

  Future<void> _openPhotoPagePicker() async {
    if (!widget.pagePickerEnabled) return;
    final visible = _visiblePageIndices();
    if (visible.length <= 1) return;

    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final idx in visible)
                ListTile(
                  title: Text('Index $idx: ${_pageLabel(idx)}'),
                  trailing:
                      idx == _pageIndex ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context).pop(idx),
                ),
            ],
          ),
        );
      },
    );

    if (picked == null || picked == _pageIndex) return;
    setState(() {
      _pageIndex = picked;
      _pendingIds.clear();
    });
    await _loadAll();
  }

  List<MainFeatureIcon> _photoCatalogIcons() {
    if (_photoCatalogTab == 0) {
      final icons = _autoFillSourceIconsForPage(_pageIndex)
          .where((icon) => !_isBlockedForCurrentPage(icon.id))
          .toList(growable: false);
      icons.sort((a, b) => _effectiveLabelFor(a.id)
          .compareTo(_effectiveLabelFor(b.id)));
      return icons;
    }

    final all = <MainFeatureIcon>[];
    final seen = <String>{};
    for (final page in MainFeatureIconCatalog.pages) {
      if (_catalogHiddenPages.contains(page.index)) continue;
      for (final icon in page.items) {
        if (!seen.add(icon.id)) continue;
        if (_isBlockedForCurrentPage(icon.id)) continue;
        if (_isExcludedByDedicatedCatalogPolicy(icon.id)) continue;
        all.add(icon);
      }
    }
    all.sort(
      (a, b) => _effectiveLabelFor(a.id).compareTo(_effectiveLabelFor(b.id)),
    );
    return all;
  }

  Widget _buildPhotoCatalogIconTile(ThemeData theme, MainFeatureIcon icon) {
    final scheme = theme.colorScheme;
    final isSelected = _pendingIds.contains(icon.id);
    final blocked = _isBlockedForCurrentPage(icon.id);
    final isAllowed = !blocked;
    final isPlaced = _isPlacedOnPage(icon.id);

    final Color bgColor;
    final Color borderColor;
    final double borderWidth;
    if (isSelected) {
      bgColor = scheme.surface; // 흰색 배경
      borderColor = Colors.green.shade600;
      borderWidth = 3.0;
    } else if (isPlaced) {
      bgColor = scheme.surface; // 배치됨도 흰색 배경
      borderColor = scheme.tertiary;
      borderWidth = 2.5;
    } else {
      bgColor = scheme.surfaceContainerHighest;
      borderColor = scheme.onSurface;
      borderWidth = 1.4;
    }

    final circleIcon = isSelected
        ? Icons.check_circle
        : Icons.radio_button_unchecked;

    return Opacity(
      opacity: isAllowed ? 1.0 : 0.45,
      child: InkWell(
        key: ValueKey<String>('icon_mgmt_photo_${icon.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onCatalogTileTap(icon, blocked, isSelected),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Icon(
                      icon.icon,
                      size: 26,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _effectiveLabelFor(icon.id),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (isPlaced)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.tertiary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '배치',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onTertiary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  circleIcon,
                  size: isSelected ? 24 : 20,
                  color: isSelected ? Colors.green.shade600 : scheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _photoSectionTitle() {
    if (_isRootReservedPage(_pageIndex)) return 'ROOT';
    if (_isStatsReservedPage(_pageIndex)) return '통계';
    if (_isAssetReservedPage(_pageIndex)) return '자산';
    if (_isSettingsOnlyPage(_pageIndex)) return '설정';
    return 'Index $_pageIndex';
  }

  String _pageLabel(int idx) {
    const labels = <int, String>{
      0: '홈',
      1: '구매',
      2: '수입',
      3: '통계',
      4: '자산',
      5: 'ROOT',
      6: '설정',
    };
    return labels[idx] ?? '';
  }

  Widget _buildCatalogIconTile(ThemeData theme, MainFeatureIcon icon) {
    final scheme = theme.colorScheme;
    final isSelected = _pendingIds.contains(icon.id);
    final blocked = _isBlockedForCurrentPage(icon.id);
    final isAllowed = !blocked;
    final isPlaced = _isPlacedOnPage(icon.id);

    final bgColor = isSelected
        ? scheme.primaryContainer
        : (isPlaced ? scheme.tertiaryContainer : scheme.surface);
    final borderColor = isSelected
        ? scheme.primary
        : (isPlaced ? scheme.tertiary : scheme.outlineVariant);

    return Opacity(
      opacity: isAllowed ? 1.0 : 0.45,
      child: InkWell(
        key: ValueKey<String>('icon_mgmt_catalog_${icon.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onCatalogTileTap(icon, blocked, isSelected),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            color: bgColor,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon.icon, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      _effectiveLabelFor(icon.id),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 22,
                  color: isSelected ? Colors.green.shade600 : scheme.outline,
                ),
              ),
              if (isPlaced)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.tertiary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '배치',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onTertiary,
                      ),
                    ),
                  ),
                ),
              if (!isAllowed)
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(
                      '하단불가',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onCatalogTileTap(
    MainFeatureIcon icon,
    bool blocked,
    bool isSelected,
  ) {
    if (blocked) {
      final msg = _settingsIconIds.contains(icon.id)
          ? '설정 아이콘은 Index 6에서만 노출할 수 있습니다'
          : (_rootIconIds.contains(icon.id)
              ? 'ROOT 아이콘은 Index 5에서만 노출할 수 있습니다'
              : (_isStatsReservedPage(_pageIndex)
                  ? 'Index 3은 통계 아이콘 전용입니다'
                  : (_isAssetReservedPage(_pageIndex)
                      ? 'Index 4는 자산 아이콘 전용입니다'
                      : '현재 페이지 정책상 배치할 수 없습니다')));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    setState(() {
      if (isSelected) {
        _pendingIds.remove(icon.id);
      } else {
        _pendingIds.add(icon.id);
      }
    });
  }

  Widget _buildApplyEnterKeyButton(ThemeData theme) {
    final scheme = theme.colorScheme;
    final isEnabled = _pendingIds.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: ElevatedButton(
          onPressed: isEnabled ? _applyPending : null,
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            backgroundColor: WidgetStatePropertyAll(scheme.primary),
            foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
          ),
          child: const Text(
            'ENT',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildMain(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.titleOverride ?? '아이콘 관리';

    if (widget.usePhotoStyleLayout) {
      final icons = _photoCatalogIcons();
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            Tooltip(
              message: '적용',
              child: _buildApplyEnterKeyButton(theme),
            ),
            IconButton(
              tooltip: '닫기',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      _photoTopBoxButton(
                        theme,
                        title: '페이지선택',
                        subtitle: '$_pageIndex: ${_pageLabel(_pageIndex)} · ${_pendingIds.length}개',
                        onTap: _openPhotoPagePicker,
                      ),
                      const SizedBox(width: 10),
                      _photoTopBoxButton(
                        theme,
                        title: '기본아이콘',
                        selected: _photoCatalogTab == 0,
                        onTap: _onDefaultIconsTabTap,
                      ),
                      const SizedBox(width: 10),
                      _photoTopBoxButton(
                        theme,
                        title: '전체아이콘',
                        selected: _photoCatalogTab == 1,
                        onTap: _onAllIconsTabTap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '아이콘을 표시하거나 숨길수 있습니다',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _photoSectionTitle(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: icons.length,
                    itemBuilder: (context, index) =>
                        _buildPhotoCatalogIconTile(theme, icons[index]),
                  ),
                ],
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.showCurrentPageIndicator
                    ? 'Index $_pageIndex · 선택: ${_pendingIds.length}'
                    : '선택: ${_pendingIds.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        actions: [
          Tooltip(
            message: '적용',
            child: _buildApplyEnterKeyButton(theme),
          ),
          if (widget.showClearSelectionAction)
            IconButton(
              tooltip: '선택해제',
              onPressed: _pendingIds.isEmpty ? null : _clearSelection,
              icon: const Icon(Icons.clear),
            ),
          if (!widget.showClearSelectionAction &&
              widget.reserveClearSelectionActionSpace)
            const SizedBox(width: 48),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '2) 현재 배치',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildCurrentSlots(theme),
                const SizedBox(height: 12),
                const Text(
                  '3) 아이콘 선택',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildIconCatalogPicker(theme),
              ],
            ),
    );
  }
}
