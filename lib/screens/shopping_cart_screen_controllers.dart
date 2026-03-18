// ignore_for_file: invalid_use_of_protected_member
part of 'shopping_cart_screen.dart';

/// Extension: inline controller synchronisation.
extension ShoppingCartControllers on _ShoppingCartScreenState {
  void _syncInlineControllers(List<ShoppingCartItem> next) {
    final ids = next.map((e) => e.id).toSet();

    final qtyRemoved = _qtyControllers.keys.where((k) => !ids.contains(k));
    for (final k in qtyRemoved.toList(growable: false)) {
      _qtyControllers.remove(k)?.dispose();
    }

    final qtyFocusRemoved = _qtyFocusNodes.keys.where((k) => !ids.contains(k));
    for (final k in qtyFocusRemoved.toList(growable: false)) {
      _qtyFocusNodes.remove(k)?.dispose();
    }

    final unitRemoved = _unitPriceControllers.keys.where(
      (k) => !ids.contains(k),
    );
    for (final k in unitRemoved.toList(growable: false)) {
      _unitPriceControllers.remove(k)?.dispose();
    }

    final bundleSizeRemoved = _bundleSizeControllers.keys.where(
      (k) => !ids.contains(k),
    );
    for (final k in bundleSizeRemoved.toList(growable: false)) {
      _bundleSizeControllers.remove(k)?.dispose();
    }

    final memoRemoved = _memoControllers.keys.where((k) => !ids.contains(k));
    for (final k in memoRemoved.toList(growable: false)) {
      _memoControllers.remove(k)?.dispose();
    }

    final unitFocusRemoved = _unitPriceFocusNodes.keys.where(
      (k) => !ids.contains(k),
    );
    for (final k in unitFocusRemoved.toList(growable: false)) {
      _unitPriceFocusNodes.remove(k)?.dispose();
    }

    final bundleSizeFocusRemoved = _bundleSizeFocusNodes.keys.where(
      (k) => !ids.contains(k),
    );
    for (final k in bundleSizeFocusRemoved.toList(growable: false)) {
      _bundleSizeFocusNodes.remove(k)?.dispose();
    }

    final memoFocusRemoved = _memoFocusNodes.keys.where(
      (k) => !ids.contains(k),
    );
    for (final k in memoFocusRemoved.toList(growable: false)) {
      _memoFocusNodes.remove(k)?.dispose();
    }

    for (final item in next) {
      final qtyVal = item.bundleCount < 0 ? 0 : item.bundleCount;
      final qtyText = qtyVal == 0 ? '' : qtyVal.toString();
      final qtyC = _qtyControllers[item.id];
      if (qtyC == null) {
        _qtyControllers[item.id] = TextEditingController(text: qtyText);
      } else {
        final hasFocus = _qtyFocusNodes[item.id]?.hasFocus ?? false;
        if (!hasFocus && qtyC.text != qtyText) {
          qtyC.text = qtyText;
        }
      }

      _qtyFocusNodes.putIfAbsent(item.id, () {
        final node = FocusNode();
        _qtyFirstFocus[item.id] = true;
        node.addListener(() {
          if (node.hasFocus && (_qtyFirstFocus[item.id] ?? false)) {
            _qtyFirstFocus[item.id] = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (node.hasFocus) {
                final c = _qtyControllers[item.id];
                if (c != null) {
                  c.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: c.text.length,
                  );
                }
              }
            });
          }
          if (mounted) setState(() {});
        });
        return node;
      });

      final perBundleVal = item.unitsPerBundle < 0 ? 0 : item.unitsPerBundle;
      final perBundleText = perBundleVal == 0 ? '' : perBundleVal.toString();
      final perBundleController = _bundleSizeControllers[item.id];
      if (perBundleController == null) {
        _bundleSizeControllers[item.id] = TextEditingController(
          text: perBundleText,
        );
      } else {
        final hasFocus = _bundleSizeFocusNodes[item.id]?.hasFocus ?? false;
        if (!hasFocus && perBundleController.text != perBundleText) {
          perBundleController.text = perBundleText;
        }
      }

      _bundleSizeFocusNodes.putIfAbsent(item.id, () {
        final node = FocusNode();
        _bundleSizeFirstFocus[item.id] = true;
        node.addListener(() {
          if (node.hasFocus && (_bundleSizeFirstFocus[item.id] ?? false)) {
            _bundleSizeFirstFocus[item.id] = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (node.hasFocus) {
                final c = _bundleSizeControllers[item.id];
                if (c != null) {
                  c.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: c.text.length,
                  );
                }
              }
            });
          }
          if (mounted) setState(() {});
        });
        return node;
      });

      final unitText = _unitPriceTextForInlineEditor(item.unitPrice);
      final unitC = _unitPriceControllers[item.id];
      if (unitC == null) {
        _unitPriceControllers[item.id] = TextEditingController(text: unitText);
      } else {
        final hasFocus = _unitPriceFocusNodes[item.id]?.hasFocus ?? false;
        if (!hasFocus && unitC.text != unitText) {
          unitC.text = unitText;
        }
      }

      _unitPriceFocusNodes.putIfAbsent(item.id, () {
        final node = FocusNode();
        _unitPriceFirstFocus[item.id] = true;
        node.addListener(() {
          if (node.hasFocus && (_unitPriceFirstFocus[item.id] ?? false)) {
            _unitPriceFirstFocus[item.id] = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (node.hasFocus) {
                final c = _unitPriceControllers[item.id];
                if (c != null) {
                  c.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: c.text.length,
                  );
                }
              }
            });
          }
          if (mounted) setState(() {});
        });
        return node;
      });
    }
  }
}
