import 'dart:async';

import 'package:flutter/services.dart';
import '../models/transaction.dart';
import 'deep_link_diagnostics.dart';

part 'deep_link_service_actions.dart';
part 'deep_link_service_models.dart';

/// Deep link 처리 서비스 (App Actions, Bixby 등).
///
/// URI 스킴: `smartledger://` — transaction/add, dashboard, feature/*,
/// shopping/cart/add, recipe/recommend, receipt/analyze, stock/check,
/// stock/use, nav/open 등을 지원합니다.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  static const _channel = MethodChannel('com.example.smartledger/deeplink');

  final _linkController = StreamController<DeepLinkAction>.broadcast();

  /// Stream of parsed deep link actions.
  Stream<DeepLinkAction> get linkStream => _linkController.stream;

  bool _initialized = false;

  /// Initialize the deep link listener.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Handle method calls from native side
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final uri = call.arguments as String?;
        if (uri != null && uri.isNotEmpty) {
          final action = parseUri(uri);
          await DeepLinkDiagnostics.record(
            uri: uri,
            parsed: action != null,
            actionSummary: action != null ? _summarizeAction(action) : null,
            failureReason: action == null ? 'UNSUPPORTED_OR_INVALID' : null,
            source: 'android:onDeepLink',
          );

          if (action != null) {
            _linkController.add(action);
          }
        }
      }
      return null;
    });

    // Check for initial deep link (app launched via deep link)
    try {
      final initial = await _channel.invokeMethod<String>('getInitialLink');
      if (initial != null && initial.isNotEmpty) {
        final action = parseUri(initial);

        await DeepLinkDiagnostics.record(
          uri: initial,
          parsed: action != null,
          actionSummary: action != null ? _summarizeAction(action) : null,
          failureReason: action == null ? 'UNSUPPORTED_OR_INVALID' : null,
          source: 'android:initial',
        );

        if (action != null) {
          _linkController.add(action);
        }
      }
    } on PlatformException catch (_) {
      // Platform channel not available (e.g., on desktop)
    }
  }

  String _summarizeAction(DeepLinkAction action) {
    switch (action) {
      case AddTransactionAction():
        return 'transaction/add type=${action.type} autoSubmit=${action.autoSubmit} confirmed=${action.confirmed}';
      case OpenDashboardAction():
        return 'dashboard/open';
      case OpenFeatureAction():
        return 'feature/open id=${action.featureId}';
      case AddToCartAction():
        return 'shopping/cart/add name=${action.name}';
      case RecipeRecommendAction():
        return 'recipe/recommend meal=${action.mealType ?? ""}';
      case ReceiptAnalyzeAction():
        return 'receipt/analyze';
      case OpenRouteAction():
        return 'nav/open route=${action.routeName} intent=${action.intent ?? ""}';
      case CheckStockAction():
        return 'stock/check';
      case UseStockAction():
        return 'stock/use autoSubmit=${action.autoSubmit} confirmed=${action.confirmed}';
    }
  }

  /// Parse a deep link URI into an action.
  DeepLinkAction? parseUri(String uriString) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return null;
    if (uri.scheme != 'smartledger') return null;

    final host = uri.host;
    final pathSegments = uri.pathSegments;
    final params = uri.queryParameters;

    switch (host) {
      case 'transaction':
        if (pathSegments.isNotEmpty && pathSegments.first == 'add') {
          return DeepLinkAction.addTransaction(
            type: params['type'] ?? 'expense',
            amount: double.tryParse(params['amount'] ?? ''),
            quantity: double.tryParse(params['quantity'] ?? ''),
            unit: params['unit'],
            unitPrice: double.tryParse(params['unitPrice'] ?? ''),
            description: params['description'],
            category: params['category'],
            paymentMethod: params['paymentMethod'] ?? params['payment'],
            store: params['store'],
            memo: params['memo'],
            savingsAllocation: _parseSavingsAllocation(
              params['savingsAllocation'],
            ),
            currency: params['currency'] ?? 'KRW',
            autoSubmit: params['autoSubmit'] == 'true',
            confirmed: params['confirmed'] == 'true',
            openReceiptScannerOnStart:
                (params['action'] ?? '').trim().toLowerCase() == 'scan' ||
                (params['intent'] ?? '').trim().toLowerCase() == 'scan_receipt',
          );
        }
        break;

      case 'dashboard':
        return const DeepLinkAction.openDashboard();

      case 'feature':
        if (pathSegments.isNotEmpty) {
          return DeepLinkAction.openFeature(pathSegments.first);
        } else if (params.containsKey('feature')) {
          return DeepLinkAction.openFeature(params['feature']!);
        }
        break;

      case 'shopping':
        if (pathSegments.length >= 2 && pathSegments[0] == 'cart') {
          if (pathSegments[1] == 'add') {
            final name = params['name'];
            if (name != null && name.isNotEmpty) {
              return DeepLinkAction.addToCart(
                name: name,
                location: params['location'],
                quantity: int.tryParse(params['quantity'] ?? ''),
                price: double.tryParse(params['price'] ?? ''),
              );
            }
          }
        }
        break;

      case 'recipe':
        if (pathSegments.isNotEmpty && pathSegments.first == 'recommend') {
          final mealType = params['meal'];
          final ingredientsStr = params['ingredients'];
          final ingredients = ingredientsStr
              ?.split(',')
              .map((e) => e.trim())
              .toList();
          final prioritizeExpiring = params['expiring'] == 'true';

          return DeepLinkAction.recommendRecipe(
            mealType: mealType,
            ingredients: ingredients,
            prioritizeExpiring: prioritizeExpiring,
          );
        }
        break;

      case 'receipt':
        if (pathSegments.isNotEmpty && pathSegments.first == 'analyze') {
          final ingredientsStr = params['ingredients'];
          final ingredients = ingredientsStr
              ?.split(',')
              .map((e) => e.trim())
              .toList();

          return DeepLinkAction.analyzeReceipt(ingredients: ingredients);
        }
        break;

      case 'stock':
        if (pathSegments.isNotEmpty) {
          final action = pathSegments.first;
          final product = params['product'];

          if (action == 'check' && product != null) {
            return DeepLinkAction.checkStock(productName: product);
          } else if (action == 'use' && product != null) {
            final amountParam = params['amount'];
            final parsedAmount = amountParam == null
                ? null
                : double.tryParse(amountParam);
            return DeepLinkAction.useStock(
              productName: product,
              amount: parsedAmount,
              autoSubmit: params['autoSubmit'] == 'true',
              confirmed: params['confirmed'] == 'true',
            );
          }
        }
        break;

      case 'nav':
        if (pathSegments.isNotEmpty && pathSegments.first == 'open') {
          final route = params['route'];
          if (route == null || route.isEmpty) return null;

          final extras = _sanitizeNavExtras(params);
          return DeepLinkAction.openRoute(
            routeName: route,
            accountName: params['account'],
            intent: params['intent'],
            params: extras,
            autoSubmit: params['autoSubmit'] == 'true',
            confirmed: params['confirmed'] == 'true',
          );
        }
        break;
    }

    return null;
  }

  static const int _maxNavExtraCount = 40;
  static const int _maxNavKeyLength = 50;
  static const int _maxNavValueLength = 300;

  Map<String, String> _sanitizeNavExtras(Map<String, String> params) {
    final extras = Map<String, String>.of(params)
      ..remove('route')
      ..remove('account')
      ..remove('intent')
      ..remove('autoSubmit')
      ..remove('confirmed');

    if (extras.isEmpty) return const <String, String>{};

    final sanitized = <String, String>{};
    for (final entry in extras.entries) {
      if (sanitized.length >= _maxNavExtraCount) break;

      final rawKey = entry.key.trim();
      if (rawKey.isEmpty || rawKey.length > _maxNavKeyLength) continue;
      if (!RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(rawKey)) continue;

      final rawValue = entry.value.trim();
      if (rawValue.isEmpty) continue;
      final value = rawValue.length <= _maxNavValueLength
          ? rawValue
          : rawValue.substring(0, _maxNavValueLength);

      sanitized[rawKey] = value;
    }

    return sanitized;
  }

  void dispose() {
    _linkController.close();
  }
}
