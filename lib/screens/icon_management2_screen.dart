import 'package:flutter/material.dart';
import 'icon_management_screen.dart';
import '../utils/main_feature_icon_catalog.dart';

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
      showCurrentPageIndicator: false,
      showClearSelectionAction: false,
      reserveClearSelectionActionSpace: true,
      groupCatalogByModule: true,
    );
  }
}
