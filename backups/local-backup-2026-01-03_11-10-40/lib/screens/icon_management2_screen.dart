import 'package:flutter/material.dart';
import 'package:smart_ledger/screens/icon_management_screen.dart';
import 'package:smart_ledger/utils/main_feature_icon_catalog.dart';

class IconManagement2Screen extends StatelessWidget {
  const IconManagement2Screen({super.key, required this.accountName});

  final String accountName;

  @override
  Widget build(BuildContext context) {
    return IconManagementScreen(
      accountName: accountName,
      titleOverride: '아이콘 관리 2',
      prefProfileKey: 'icon_mgmt2',
      initialPageIndex: MainFeatureIconCatalog.pageCount > 0 ? 5 : 0,
      pagePickerEnabled: true,
      showCurrentPageIndicator: false,
      showClearSelectionAction: false,
      reserveClearSelectionActionSpace: true,
      groupCatalogByModule: true,
      flattenCatalog: false,
      showCatalogSectionTitles: true,
      hiddenPageIndices: const <int>{},
    );
  }
}
