library assistant_route_catalog;

import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import '../services/account_service.dart';
import 'app_routes.dart';

part 'assistant_route_catalog_top_level.dart';
part 'assistant_route_catalog_quick_input.dart';
part 'assistant_route_catalog_ledger.dart';
part 'assistant_route_catalog_stats.dart';
part 'assistant_route_catalog_shopping.dart';
part 'assistant_route_catalog_assets.dart';
part 'assistant_route_catalog_settings.dart';
part 'assistant_route_catalog_root.dart';

@immutable
class AssistantRouteSpec {
  final String routeName;

  /// If true, route requires an accountName-derived args.
  final bool requiresAccount;

  /// Build RouteSettings.arguments for this route.
  ///
  /// Return null only when the route truly requires no args.
  final Object? Function(String? accountName) buildArgs;

  const AssistantRouteSpec({
    required this.routeName,
    required this.requiresAccount,
    required this.buildArgs,
  });
}

class AssistantRouteCatalog {
  AssistantRouteCatalog._();

  static String? resolveDefaultAccountName() {
    final accounts = AccountService().accounts;
    if (accounts.isEmpty) return null;
    return accounts.first.name;
  }

  /// Whitelist of routes that can be opened via assistant deep links.
  ///
  /// Keep this list explicit to avoid opening unintended internal screens.
  static final Map<String, AssistantRouteSpec> specs = {
    ..._topLevelSpecs,
    ..._quickInputSpecs,
    ..._ledgerSpecs,
    ..._statsSpecs,
    ..._shoppingSpecs,
    ..._assetSpecs,
    ..._settingsSpecs,
    ..._rootSpecs,
  };
}
