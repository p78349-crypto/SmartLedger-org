import 'package:flutter/material.dart';
import 'icon_management_screen.dart';
import '../utils/main_feature_icon_catalog.dart';

class IconManagementAssetScreen extends StatelessWidget {
  const IconManagementAssetScreen({super.key, required this.accountName});

  final String accountName;

  static Set<int> _pagePickerHiddenPages() {
    // Keep only the asset-reserved page (page 4 => 0-based {3}).
    const allowed = <int>{3};
    final hidden = <int>{};
    for (var i = 0; i < 15; i++) {
      if (!allowed.contains(i)) hidden.add(i);
    }
    return hidden;
  }

  static Set<int> _catalogHiddenPages() {
    // Show only icons that belong to the asset+income modules.
    // (asset module icons live on catalog page 4; income module icons
    // live on page 2)
    const allowed = <int>{1, 3};
    final hidden = <int>{};
    for (var i = 0; i < 15; i++) {
      if (!allowed.contains(i)) hidden.add(i);
    }
    return hidden;
  }

  @override
  Widget build(BuildContext context) {
    return IconManagementScreen(
      accountName: accountName,
      titleOverride: '자산 아이콘 관리',
      initialPageIndex: MainFeatureIconCatalog.pageCount > 0 ? 3 : 0,
      hiddenPageIndices: _pagePickerHiddenPages(),
      catalogHiddenPageIndices: _catalogHiddenPages(),
      redirectAssetRootToDedicatedScreens: false,
      groupCatalogByModule: true,
    );
  }
}
