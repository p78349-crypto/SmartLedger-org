import 'package:flutter/material.dart';
import '../models/shopping_cart_history_entry.dart';
import '../models/shopping_cart_item.dart';
import '../navigation/app_routes.dart';
import '../services/consumable_inventory_service.dart';
import '../services/product_location_service.dart';
import '../services/user_pref_service.dart';
import '../shared/result.dart';
import '../utils/currency_formatter.dart';
import '../utils/icon_catalog.dart';
import '../widgets/smart_input_field.dart';

part 'shopping_cart_screen_build.dart';
part 'shopping_cart_screen_controllers.dart';
part 'shopping_cart_screen_data_ops.dart';
part 'shopping_cart_screen_inline_edit.dart';
part 'shopping_cart_screen_item_actions.dart';
part 'shopping_cart_screen_portrait_tile.dart';
part 'shopping_cart_screen_purchase_picker.dart';
part 'shopping_cart_screen_wide_tile.dart';

// -- Library-level constants (accessible from all part files) --

const double _inlineFieldHeight = 36.0;
const BorderRadius _inlineFieldRadius = BorderRadius.all(
  Radius.circular(12),
);
const Color _inlineFieldBorderColor = Color(0xFFD8C5CA);
const Color _inlineFieldFocusedBorderColor = Color(0xFF884A5E);
const Color _inlineFieldFillColor = Color(0xFFF8EFF2);

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({
    super.key,
    required this.accountName,
    this.initialItems,
  });

  final String accountName;
  final List<ShoppingCartItem>? initialItems;

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  bool _isLoading = true;
  List<ShoppingCartItem> _items = const [];

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _unitPriceControllers = {};
  final Map<String, TextEditingController> _bundleSizeControllers = {};
  final Map<String, TextEditingController> _memoControllers = {};

  final Map<String, FocusNode> _qtyFocusNodes = {};
  final Map<String, FocusNode> _unitPriceFocusNodes = {};
  final Map<String, FocusNode> _bundleSizeFocusNodes = {};
  final Map<String, FocusNode> _memoFocusNodes = {};

  final Map<String, bool> _qtyFirstFocus = {};
  final Map<String, bool> _unitPriceFirstFocus = {};
  final Map<String, bool> _bundleSizeFirstFocus = {};

  @override
  void initState() {
    super.initState();

    _nameFocusNode.addListener(() {
      if (_nameFocusNode.hasFocus) {
        _nameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _nameController.text.length,
        );
      }
    });

    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    for (final c in _unitPriceControllers.values) {
      c.dispose();
    }
    for (final c in _bundleSizeControllers.values) {
      c.dispose();
    }
    for (final c in _memoControllers.values) {
      c.dispose();
    }
    for (final n in _qtyFocusNodes.values) {
      n.dispose();
    }
    for (final n in _unitPriceFocusNodes.values) {
      n.dispose();
    }
    for (final n in _bundleSizeFocusNodes.values) {
      n.dispose();
    }
    for (final n in _memoFocusNodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildMain(context);
}
