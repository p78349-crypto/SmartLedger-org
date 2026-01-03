import 'package:flutter/material.dart';
import 'package:smart_ledger/screens/icon_management_screen.dart';
import 'package:smart_ledger/utils/main_feature_icon_catalog.dart';

class IconManagementRootScreen extends StatelessWidget {
  const IconManagementRootScreen({super.key, required this.accountName});

  final String accountName;

  static Set<int> _pagePickerHiddenPages() {
    // Keep only the root-reserved page (page 5 => 0-based {4}).
    const allowed = <int>{4};
    final hidden = <int>{};
    for (var i = 0; i < 15; i++) {
      if (!allowed.contains(i)) hidden.add(i);
    }
    return hidden;
  }

  static Set<int> _catalogHiddenPages() {
    // Show only root module icons (catalog page 5 => 0-based {4}).
    const allowed = <int>{4};
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
      titleOverride: 'ROOT 아이콘 관리',
      initialPageIndex: MainFeatureIconCatalog.pageCount > 0 ? 4 : 0,
      hiddenPageIndices: _pagePickerHiddenPages(),
      catalogHiddenPageIndices: _catalogHiddenPages(),
      redirectAssetRootToDedicatedScreens: false,
      groupCatalogByModule: true,
    );
  }
}
