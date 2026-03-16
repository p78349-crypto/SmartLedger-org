import 'package:flutter/material.dart';
import 'icon_management_screen.dart';
import '../utils/main_feature_icon_catalog.dart';

class IconManagementAssetScreen extends StatelessWidget {
  const IconManagementAssetScreen({super.key, required this.accountName});

  final String accountName;

  static Set<int> _pagePickerHiddenPages() {
    // Keep only the asset-reserved page (0-based index 4).
    const allowed = <int>{4};
    final hidden = <int>{};
    final pageCount = MainFeatureIconCatalog.pageCount;
    for (var i = 0; i < pageCount; i++) {
      if (!allowed.contains(i)) hidden.add(i);
    }
    return hidden;
  }

  static Set<int> _catalogHiddenPages() {
    // Show only icons that belong to the asset module (catalog page 4).
    const allowed = <int>{4};
    final hidden = <int>{};
    final pageCount = MainFeatureIconCatalog.pageCount;
    for (var i = 0; i < pageCount; i++) {
      if (!allowed.contains(i)) hidden.add(i);
    }
    return hidden;
  }

  @override
  Widget build(BuildContext context) {
    return IconManagementScreen(
      accountName: accountName,
      titleOverride: '자산 아이콘 관리',
      initialPageIndex: MainFeatureIconCatalog.pageCount > 0 ? 4 : 0,
      hiddenPageIndices: _pagePickerHiddenPages(),
      catalogHiddenPageIndices: _catalogHiddenPages(),
      redirectAssetRootToDedicatedScreens: false,
      groupCatalogByModule: true,
    );
  }
}
