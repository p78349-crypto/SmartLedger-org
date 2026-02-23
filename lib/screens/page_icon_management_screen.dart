import 'package:flutter/material.dart';
import '../navigation/app_routes.dart';
import '../utils/main_feature_icon_catalog.dart';
import 'icon_management_screen.dart';

/// 페이지별 아이콘 관리 화면
/// 특정 페이지의 아이콘만 관리할 수 있도록 제한된 아이콘 관리 화면
class PageIconManagementScreen extends StatelessWidget {
  final String accountName;
  final int pageIndex;
  final String pageTitle;

  const PageIconManagementScreen({
    super.key,
    required this.accountName,
    required this.pageIndex,
    required this.pageTitle,
  });

  @override
  Widget build(BuildContext context) {
    return IconManagementScreen(
      accountName: accountName,
      initialPageIndex: pageIndex,
      pagePickerEnabled: false, // 페이지 전환 비활성화
      titleOverride: '$pageTitle 아이콘 관리',
      showCurrentPageIndicator: false, // 현재 페이지 표시 안함 (고정 페이지)
      hiddenPageIndices: _getHiddenPageIndices(pageIndex), // 다른 페이지 숨김
      catalogHiddenPageIndices: _getHiddenPageIndices(pageIndex), // 카탈로그에서도 다른 페이지 숨김
    );
  }

  /// 현재 페이지를 제외한 모든 페이지를 숨김 처리
  Set<int> _getHiddenPageIndices(int currentPageIndex) {
    final totalPages = MainFeatureIconCatalog.pageCount;
    final hiddenPages = <int>{};
    
    for (int i = 0; i < totalPages; i++) {
      if (i != currentPageIndex) {
        hiddenPages.add(i);
      }
    }
    
    return hiddenPages;
  }
}

/// 페이지별 아이콘 관리 화면으로 이동하는 헬퍼 클래스
class PageIconManagementHelper {
  PageIconManagementHelper._();

  /// 페이지별 아이콘 관리 화면으로 이동
  static void navigateToPageIconManagement(
    BuildContext context, {
    required String accountName,
    required int pageIndex,
    required String pageTitle,
  }) {
    Navigator.of(context).pushNamed(
      AppRoutes.pageIconManagement,
      arguments: PageIconManagementArgs(
        accountName: accountName,
        pageIndex: pageIndex,
        pageTitle: pageTitle,
      ),
    );
  }

  /// 페이지 이름을 반환
  static String getPageTitle(int pageIndex) {
    const pageNames = [
      '대시보드',
      '요리/쇼핑/지출',
      '수입',
      '통계',
      '자산',
      'ROOT',
      '설정',
    ];

    if (pageIndex >= 0 && pageIndex < pageNames.length) {
      return pageNames[pageIndex];
    }
    return '페이지 ${pageIndex + 1}';
  }
}