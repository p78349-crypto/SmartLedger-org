// ignore_for_file: invalid_use_of_protected_member

part of 'icon_management_screen.dart';

/// Icon catalog picker (grouped / flat / per-page modes).
extension IconManagementCatalog on _IconManagementScreenState {
  Widget _buildIconCatalogPicker(ThemeData theme) {
    if (widget.groupCatalogByModule) {
      return _buildGroupedByModuleCatalog(theme);
    }
    if (widget.flattenCatalog) return _buildFlatCatalog(theme);
    return _buildPerPageCatalog(theme);
  }

  Widget _buildGroupedByModuleCatalog(ThemeData theme) {
    const moduleOrder = <({String key, String title})>[
      (key: 'page0', title: '기본'),
      (key: 'purchase', title: '구매'),
      (key: 'stats', title: '통계'),
      (key: 'asset', title: '자산'),
      (key: 'root', title: 'ROOT'),
      (key: 'settings', title: '설정'),
    ];

    final sections = <(String title, List<MainFeatureIcon> icons)>[];
    for (final entry in moduleOrder) {
      if (widget.redirectAssetRootToDedicatedScreens &&
          (entry.key == 'asset' || entry.key == 'root')) {
        continue;
      }
      final icons = <MainFeatureIcon>[];
      final seen = <String>{};
      final includeIncomeInAsset = entry.key == 'asset' &&
          !widget.redirectAssetRootToDedicatedScreens;
      final sources = <MainFeatureIcon>[
        ...MainFeatureIconCatalog.iconsForModuleKey(entry.key),
        if (includeIncomeInAsset)
          ...MainFeatureIconCatalog.iconsForModuleKey('income'),
      ];

      for (final icon in sources) {
        if (!seen.add(icon.id)) continue;
        if (_isExcludedByDedicatedCatalogPolicy(icon.id)) continue;
        final pageIndex = _iconPageIndexById[icon.id];
        if (pageIndex != null &&
            _catalogHiddenPages.contains(pageIndex)) {
          continue;
        }
        icons.add(icon);
      }

      icons.sort((a, b) {
        final al = _effectiveLabelFor(a.id);
        final bl = _effectiveLabelFor(b.id);
        return al.compareTo(bl);
      });

      if (icons.isEmpty) continue;
      sections.add((entry.title, icons));
    }

    if (sections.isEmpty) return const SizedBox.shrink();
    return _buildSectionedGrid(theme, sections);
  }

  Widget _buildFlatCatalog(ThemeData theme) {
    final icons = <MainFeatureIcon>[];
    for (final page in MainFeatureIconCatalog.pages) {
      if (_catalogHiddenPages.contains(page.index)) continue;
      if (page.items.isEmpty) continue;
      icons.addAll(
        page.items.where(
          (icon) =>
              !_isBlockedForCurrentPage(icon.id) &&
              !_isExcludedByDedicatedCatalogPolicy(icon.id),
        ),
      );
    }

    icons.sort((a, b) {
      final al = _effectiveLabelFor(a.id);
      final bl = _effectiveLabelFor(b.id);
      return al.compareTo(bl);
    });

    if (icons.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) =>
          _buildCatalogIconTile(theme, icons[index]),
    );
  }

  Widget _buildPerPageCatalog(ThemeData theme) {
    final sections = <(String title, List<MainFeatureIcon> icons)>[];
    for (final page in MainFeatureIconCatalog.pages) {
      if (_catalogHiddenPages.contains(page.index)) continue;
      if (page.items.isEmpty) continue;

      final visible = List<MainFeatureIcon>.from(
        page.items.where(
          (icon) =>
              !_isBlockedForCurrentPage(icon.id) &&
              !_isExcludedByDedicatedCatalogPolicy(icon.id),
        ),
      )..sort((a, b) {
          final al = _effectiveLabelFor(a.id);
          final bl = _effectiveLabelFor(b.id);
          return al.compareTo(bl);
        });

      if (visible.isEmpty) continue;
      sections.add(
        (_catalogSectionTitleForPage(page.index), visible),
      );
    }

    if (sections.isEmpty) return const SizedBox.shrink();
    return _buildSectionedGrid(theme, sections);
  }

  Widget _buildSectionedGrid(
    ThemeData theme,
    List<(String title, List<MainFeatureIcon> icons)> sections,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          if (widget.showCatalogSectionTitles)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                section.$1,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: section.$2.length,
            itemBuilder: (context, index) =>
                _buildCatalogIconTile(theme, section.$2[index]),
          ),
        ],
      ],
    );
  }
}
