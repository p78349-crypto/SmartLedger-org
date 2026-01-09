import 'dart:async';

import 'package:flutter/widgets.dart';

import '../services/food_expiry_service.dart';

mixin FoodExpiryItemsAutoRefreshMixin<T extends StatefulWidget> on State<T> {
  late final VoidCallback _itemsListener;
  Timer? _debounceTimer;
  bool _isRefreshing = false;
  bool _pendingRefresh = false;

  /// If provided, changes are debounced by this duration.
  ///
  /// Default is a small debounce to avoid repeated recompute when multiple
  /// items update in quick succession.
  Duration? get foodExpiryItemsRefreshDebounce =>
      const Duration(milliseconds: 250);

  /// Requests a refresh, honoring debounce and coalescing while a refresh is
  /// already in-flight.
  @protected
  void requestFoodExpiryItemsRefresh() {
    if (!mounted) return;
    final debounce = foodExpiryItemsRefreshDebounce;
    if (debounce == null || debounce <= Duration.zero) {
      _runRefresh();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      if (!mounted) return;
      _runRefresh();
    });
  }

  Future<void> _runRefresh() async {
    if (_isRefreshing) {
      _pendingRefresh = true;
      return;
    }

    _isRefreshing = true;
    try {
      await Future.sync(onFoodExpiryItemsChanged);
    } finally {
      _isRefreshing = false;
    }

    if (_pendingRefresh) {
      _pendingRefresh = false;
      if (!mounted) return;
      scheduleMicrotask(_runRefresh);
    }
  }

  @mustCallSuper
  @override
  void initState() {
    super.initState();
    _itemsListener = requestFoodExpiryItemsRefresh;
    FoodExpiryService.instance.items.addListener(_itemsListener);
  }

  @mustCallSuper
  @override
  void dispose() {
    FoodExpiryService.instance.items.removeListener(_itemsListener);
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pendingRefresh = false;
    super.dispose();
  }

  FutureOr<void> onFoodExpiryItemsChanged();
}
