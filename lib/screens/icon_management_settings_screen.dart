import 'package:flutter/material.dart';
import 'icon_management_screen.dart';
import '../utils/main_feature_icon_catalog.dart';

class IconManagementSettingsScreen extends StatelessWidget {
  const IconManagementSettingsScreen({super.key, required this.accountName});

  final String accountName;

  static Set<int> _pagePickerHiddenPages() {
    // Allow all pages to be selectable from Settings icon management.
    return <int>{};
  }

  static Set<int> _catalogHiddenPages() {
    // Show icons from all pages in the catalog.
    return <int>{};
  }

  @override
  Widget build(BuildContext context) {
    return IconManagementScreen(
      accountName: accountName,
      titleOverride: '설정 아이콘 관리',
      initialPageIndex: MainFeatureIconCatalog.pageCount > 0 ? 6 : 0,
      hiddenPageIndices: _pagePickerHiddenPages(),
      catalogHiddenPageIndices: _catalogHiddenPages(),
      redirectAssetRootToDedicatedScreens: false,
      showCatalogSectionTitles: false,
      usePhotoStyleLayout: true,
    );
  }
}
