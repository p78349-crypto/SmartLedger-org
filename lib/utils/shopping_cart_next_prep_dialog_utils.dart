import 'package:flutter/material.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';

enum ShoppingCartNextPrepAction {
  recentPurchases20,
  recommendFrequent20,
  recommendFrequent20ByStoreMemo,
  recipeSearch,
}

class ShoppingCartNextPrepDialogUtils {
  ShoppingCartNextPrepDialogUtils._();

  static Future<ShoppingCartNextPrepAction?> show(
    BuildContext context, {
    required ShoppingCartNextPrepAction defaultAction,
  }) async {
    final actions = <ShoppingCartNextPrepAction>[
      ...ShoppingCartNextPrepAction.values,
    ];
    actions
      ..remove(defaultAction)
      ..insert(0, defaultAction);

    IconData iconOf(ShoppingCartNextPrepAction a) {
      switch (a) {
        case ShoppingCartNextPrepAction.recentPurchases20:
          return IconCatalog.history;
        case ShoppingCartNextPrepAction.recommendFrequent20:
          return IconCatalog.autoAwesome;
        case ShoppingCartNextPrepAction.recommendFrequent20ByStoreMemo:
          return IconCatalog.shoppingCart;
        case ShoppingCartNextPrepAction.recipeSearch:
          return IconCatalog.articleOutlined;
      }
    }

    String titleOf(ShoppingCartNextPrepAction a) {
      switch (a) {
        case ShoppingCartNextPrepAction.recentPurchases20:
          return '최근 구매 20개';
        case ShoppingCartNextPrepAction.recommendFrequent20:
          return '추천 품목 20개';
        case ShoppingCartNextPrepAction.recommendFrequent20ByStoreMemo:
          return '마트/쇼핑몰별 추천 20개';
        case ShoppingCartNextPrepAction.recipeSearch:
          return '요리 레시피 검색';
      }
    }

    String subtitleOf(ShoppingCartNextPrepAction a) {
      switch (a) {
        case ShoppingCartNextPrepAction.recentPurchases20:
          return '가장 최근 구매한 품목을 최대 20개 추가합니다.';
        case ShoppingCartNextPrepAction.recommendFrequent20:
          return '가계부 입력 이력에서 2회 이상 구매한 품목만 추천합니다.';
        case ShoppingCartNextPrepAction.recommendFrequent20ByStoreMemo:
          return '가계부 메모(마트/쇼핑몰명) 기준으로 추천합니다.';
        case ShoppingCartNextPrepAction.recipeSearch:
          return '요리 레시피에서 필요한 식재료를 찾아 추가합니다.';
      }
    }

    return showModalBottomSheet<ShoppingCartNextPrepAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('쇼핑 준비'),
                subtitle: Text('원하는 준비 방식을 선택하세요.'),
              ),
              const Divider(height: 1),
              ...actions.map((a) {
                final isDefault = a == defaultAction;
                final title = isDefault ? '${titleOf(a)} (추천)' : titleOf(a);
                return ListTile(
                  leading: Icon(iconOf(a)),
                  title: Text(title),
                  subtitle: Text(subtitleOf(a)),
                  onTap: () => Navigator.of(sheetContext).pop(a),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
