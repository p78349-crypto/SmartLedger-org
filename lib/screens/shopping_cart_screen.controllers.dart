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

    final unitPriceRemoved =
        _unitPriceControllers.keys.where((k) => !ids.contains(k));
    for (final k in unitPriceRemoved.toList(growable: false)) {
      _unitPriceControllers.remove(k)?.dispose();
    }

    final bundleSizeRemoved =
        _bundleSizeControllers.keys.where((k) => !ids.contains(k));
    for (final k in bundleSizeRemoved.toList(growable: false)) {
      _bundleSizeControllers.remove(k)?.dispose();
    }

    final memoRemoved = _memoControllers.keys.where((k) => !ids.contains(k));
    for (final k in memoRemoved.toList(growable: false)) {
      _memoControllers.remove(k)?.dispose();
    }

    // FocusNode cleanup
    final qtyFnRemoved = _qtyFocusNodes.keys.where((k) => !ids.contains(k));
    for (final k in qtyFnRemoved.toList(growable: false)) {
      _qtyFocusNodes.remove(k)?.dispose();
    }

    final upFnRemoved =
        _unitPriceFocusNodes.keys.where((k) => !ids.contains(k));
    for (final k in upFnRemoved.toList(growable: false)) {
      _unitPriceFocusNodes.remove(k)?.dispose();
    }

    final bsFnRemoved =
        _bundleSizeFocusNodes.keys.where((k) => !ids.contains(k));
    for (final k in bsFnRemoved.toList(growable: false)) {
      _bundleSizeFocusNodes.remove(k)?.dispose();
    }

    final memoFnRemoved = _memoFocusNodes.keys.where((k) => !ids.contains(k));
    for (final k in memoFnRemoved.toList(growable: false)) {
      _memoFocusNodes.remove(k)?.dispose();
    }

    for (final item in next) {
      _qtyControllers.putIfAbsent(item.id, () {
        final val = item.bundleCount < 0 ? 0 : item.bundleCount;
        return TextEditingController(text: val == 0 ? '' : val.toString());
      });
      _unitPriceControllers.putIfAbsent(
        item.id,
        () => TextEditingController(
          text: _unitPriceTextForInlineEditor(item.unitPrice),
        ),
      );
      _bundleSizeControllers.putIfAbsent(item.id, () {
        final val = item.unitsPerBundle < 0 ? 0 : item.unitsPerBundle;
        return TextEditingController(text: val == 0 ? '' : val.toString());
      });
      _memoControllers.putIfAbsent(
        item.id,
        () => TextEditingController(text: item.memo),
      );

      _qtyFocusNodes.putIfAbsent(item.id, () {
        final node = FocusNode();
        node.addListener(() {
          if (node.hasFocus) {
            final c = _qtyControllers[item.id];
            if (c != null) {
              final isFirst = _qtyFirstFocus[item.id] ?? true;
              if (isFirst) {
                _qtyFirstFocus[item.id] = false;
                c.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: c.text.length,
                );
              }
            }
          }
          if (mounted) setState(() {});
        });
        return node;
      });

      _unitPriceFocusNodes.putIfAbsent(item.id, () {
        final node = FocusNode();
        node.addListener(() {
          if (node.hasFocus) {
            final c = _unitPriceControllers[item.id];
            if (c != null) {
              final isFirst = _unitPriceFirstFocus[item.id] ?? true;
              if (isFirst) {
                _unitPriceFirstFocus[item.id] = false;
                c.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: c.text.length,
                );
              }
            }
          }
          if (mounted) setState(() {});
        });
        return node;
      });

      _bundleSizeFocusNodes.putIfAbsent(item.id, () {
        final node = FocusNode();
        node.addListener(() {
          if (node.hasFocus) {
            final c = _bundleSizeControllers[item.id];
            if (c != null) {
              final isFirst = _bundleSizeFirstFocus[item.id] ?? true;
              if (isFirst) {
                _bundleSizeFirstFocus[item.id] = false;
                c.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: c.text.length,
                );
              }
            }
          }
          if (mounted) setState(() {});
        });
        return node;
      });

      _memoFocusNodes.putIfAbsent(item.id, () {
        final node = FocusNode();
        node.addListener(() {
          if (mounted) setState(() {});
        });
        return node;
      });
    }
  }
}
