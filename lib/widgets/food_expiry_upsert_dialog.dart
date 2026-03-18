import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/consumable_inventory_item.dart';
import '../models/food_expiry_item.dart';
import '../models/shopping_cart_history_entry.dart';
import '../models/shopping_cart_item.dart';
import '../navigation/app_routes_args.dart';
import '../services/consumable_inventory_service.dart';
import '../services/feedback_service.dart';
import '../services/health_guardrail_service.dart';
import '../services/transaction_service.dart';
import '../services/user_pref_service.dart';
import '../utils/constants.dart';
import '../utils/icon_catalog.dart';
import '../utils/snackbar_utils.dart';
import '../utils/transaction_by_date_utils.dart';

part 'food_expiry_upsert_dialog_voice.dart';
part 'food_expiry_upsert_dialog_logic.dart';
part 'food_expiry_upsert_dialog_import.dart';
part 'food_expiry_upsert_dialog_form.dart';
part 'food_expiry_upsert_dialog_build.dart';

class FoodExpiryUpsertDialog extends StatefulWidget {
  final FoodExpiryItem? existing;
  final FoodExpiryUpsertPrefill? prefill;
  final bool autoSubmit;

  const FoodExpiryUpsertDialog({
    super.key,
    this.existing,
    this.prefill,
    this.autoSubmit = false,
  });

  @override
  State<FoodExpiryUpsertDialog> createState() => _FoodExpiryUpsertDialogState();
}

class _UpsertVoiceParseResult {
  const _UpsertVoiceParseResult({
    required this.name,
    required this.quantityText,
    required this.unit,
    required this.location,
    required this.category,
    required this.expiryDate,
    required this.priceText,
    required this.healthTags,
  });

  final String? name;
  final String? quantityText;
  final String? unit;
  final String? location;
  final String? category;
  final DateTime? expiryDate;
  final String? priceText;
  final Set<String> healthTags;
}

class _FoodExpiryUpsertDialogState extends State<FoodExpiryUpsertDialog> {
  static const String _kLastCategory = 'food_expiry_last_category_v1';
  static const String _kLastLocation = 'food_expiry_last_location_v1';
  static const String _kLastUnit = 'food_expiry_last_unit_v1';

  late TextEditingController _nameController;
  late TextEditingController _memoController;
  late TextEditingController _quantityController;

  // WMS-style calculation controllers
  final TextEditingController _boxQtyController = TextEditingController();
  final TextEditingController _pcsPerBoxController = TextEditingController();

  late TextEditingController _unitController;
  late TextEditingController _priceController;
  late TextEditingController _supplierController;
  late DateTime _purchaseDate;
  DateTime? _pickedExpiryDate;

  String _category = '기타';
  String _location = '냉장';
  bool _addToShoppingList = false;
  List<String> _healthTags = const <String>[];

  final List<String> _categories = [
    '채소',
    '과일',
    '육류',
    '수산물',
    '유제품',
    '냉동식품',
    '가공식품',
    '음료',
    '양념/소스',
    '기타',
  ];

  final List<String> _locations = ['냉장', '냉동', '실온', '팬트리'];

  // Adjustment fields for existing items
  final TextEditingController _addQtyController = TextEditingController();
  final TextEditingController _subQtyController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _memoFocus = FocusNode();

  // Import Queue State
  List<ShoppingCartHistoryEntry> _importQueue = [];
  int _importTotal = 0;

  // Voice input (STT)
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _speechInitAttempted = false;
  bool _isVoiceListening = false;
  String _voiceDraft = '';
  // listeners for controllers to update preview text
  late VoidCallback _quantityListener;
  late VoidCallback _unitListener;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _memoController = TextEditingController(text: widget.existing?.memo ?? '');
    _quantityController = TextEditingController(
      text: widget.existing?.quantity.toString() ?? '1',
    );

    // Calculate total if box or pcs changes
    _boxQtyController.addListener(_calculateTotalQuantity);
    _pcsPerBoxController.addListener(_calculateTotalQuantity);

    _unitController = TextEditingController(text: widget.existing?.unit ?? '');
    // Update preview when quantity or unit changes
    _quantityListener = () {
      if (!mounted) return;
      setState(() {});
    };
    _unitListener = () {
      if (!mounted) return;
      setState(() {});
    };
    _quantityController.addListener(_quantityListener);
    _unitController.addListener(_unitListener);
    _priceController = TextEditingController(
      text: widget.existing?.price.toString() ?? '0',
    );
    _supplierController = TextEditingController(
      text: widget.existing?.supplier ?? '',
    );
    _purchaseDate = widget.existing?.purchaseDate ?? DateTime.now();
    _pickedExpiryDate = widget.existing?.expiryDate;
    _category = widget.existing?.category ?? '기타';
    _location = widget.existing?.location ?? '냉장';
    _healthTags = widget.existing?.healthTags ?? const <String>[];

    if (widget.existing == null) {
      if (widget.prefill == null) {
        _loadLastCategory();
        _loadLastLocation();
        _loadLastUnit();
        _prefillFromLatestTransaction();
      }

      final p = widget.prefill;
      if (p != null) {
        if (p.name != null && p.name!.trim().isNotEmpty) {
          _nameController.text = p.name!.trim();
        }
        if (p.quantity != null) {
          final v = p.quantity!;
          _quantityController.text = v == v.roundToDouble()
              ? v.toStringAsFixed(0)
              : v.toString();
        }
        if (p.unit != null && p.unit!.trim().isNotEmpty) {
          _unitController.text = p.unit!.trim();
        }
        if (p.location != null && _locations.contains(p.location)) {
          _location = p.location!;
        }
        if (p.category != null && _categories.contains(p.category)) {
          _category = p.category!;
        }
        if (p.expiryDate != null) {
          _pickedExpiryDate = p.expiryDate;
        }
        if (p.price != null) {
          final v = p.price!;
          _priceController.text = v == v.roundToDouble()
              ? v.toStringAsFixed(0)
              : v.toString();
        }
        if (p.supplier != null && p.supplier!.trim().isNotEmpty) {
          _supplierController.text = p.supplier!.trim();
        }
        if (p.memo != null && p.memo!.trim().isNotEmpty) {
          _memoController.text = p.memo!.trim();
        }
        if (p.purchaseDate != null) {
          _purchaseDate = p.purchaseDate!;
        }
        if (p.healthTags != null && p.healthTags!.isNotEmpty) {
          final allowed = HealthGuardrailService.defaultTags.toSet();
          final next = <String>{..._healthTags};
          for (final t in p.healthTags!) {
            final tag = t.trim();
            if (tag.isEmpty) continue;
            if (!allowed.contains(tag)) continue;
            next.add(tag);
          }
          _healthTags = next.toList();
        }

        if (widget.autoSubmit) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _save();
          });
        }
      }
    }

    if (widget.existing != null) {
      _addQtyController.addListener(_updateTotal);
      _subQtyController.addListener(_updateTotal);
    }
  }

  @override
  void dispose() {
    _boxQtyController.dispose();
    _pcsPerBoxController.dispose();
    _nameController.dispose();
    _memoController.dispose();
    _quantityController.removeListener(_quantityListener);
    _unitController.removeListener(_unitListener);
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _supplierController.dispose();
    _addQtyController.dispose();
    _subQtyController.dispose();
    _nameFocus.dispose();
    _memoFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildDialog(context);
}
