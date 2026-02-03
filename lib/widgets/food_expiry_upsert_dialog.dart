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
import '../services/food_expiry_prediction_engine.dart';
import '../services/food_expiry_service.dart';
import '../services/health_guardrail_service.dart';
import '../services/transaction_service.dart';
import '../services/user_pref_service.dart';
import '../utils/constants.dart';
import '../utils/icon_catalog.dart';
import '../utils/snackbar_utils.dart';
import '../utils/transaction_by_date_utils.dart';

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

  Future<bool> _ensureSpeechReady() async {
    if (_speechInitAttempted) {
      return _speechAvailable;
    }
    _speechInitAttempted = true;

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('마이크 권한이 필요합니다')));
      }
      _speechAvailable = false;
      return false;
    }

    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            if (_voiceDraft.trim().isNotEmpty) {
              _applyVoiceInput(_voiceDraft);
            }
            setState(() {
              _isVoiceListening = false;
            });
          }
        },
        onError: (error) {
          debugPrint('FoodExpiryUpsert: speech error: $error');
          if (!mounted) return;
          setState(() {
            _isVoiceListening = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('음성 인식 중 오류가 발생했습니다')));
        },
      );
    } catch (e) {
      debugPrint('FoodExpiryUpsert: speech init error: $e');
      _speechAvailable = false;
    }
    return _speechAvailable;
  }

  Future<void> _toggleVoiceInput() async {
    if (_isVoiceListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() {
        _isVoiceListening = false;
      });
      return;
    }

    final ok = await _ensureSpeechReady();
    if (!ok) return;

    if (!mounted) return;
    setState(() {
      _isVoiceListening = true;
      _voiceDraft = '';
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('말씀하세요… (예: 팽이버섯 2봉 냉장 내일)')));

    await _speech.listen(
      localeId: 'ko_KR',
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _voiceDraft = result.recognizedWords;
        });
        if (result.finalResult) {
          _applyVoiceInput(result.recognizedWords);
          setState(() {
            _isVoiceListening = false;
          });
        }
      },
      listenOptions: stt.SpeechListenOptions(),
    );
  }

  void _applyVoiceInput(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;

    final parsed = _parseUpsertVoice(text);

    setState(() {
      if (parsed.name != null && parsed.name!.trim().isNotEmpty) {
        _nameController.text = parsed.name!;
      }
      if (parsed.quantityText != null &&
          parsed.quantityText!.trim().isNotEmpty) {
        _quantityController.text = parsed.quantityText!;
      }
      if (parsed.unit != null && parsed.unit!.trim().isNotEmpty) {
        _unitController.text = parsed.unit!;
      }
      if (parsed.location != null && _locations.contains(parsed.location)) {
        _location = parsed.location!;
      }
      if (parsed.category != null && _categories.contains(parsed.category)) {
        _category = parsed.category!;
      }
      if (parsed.expiryDate != null) {
        _pickedExpiryDate = parsed.expiryDate;
      }
      if (parsed.priceText != null && parsed.priceText!.trim().isNotEmpty) {
        _priceController.text = parsed.priceText!;
      }
      if (parsed.healthTags.isNotEmpty) {
        final next = <String>{..._healthTags};
        next.addAll(parsed.healthTags);
        _healthTags = next.toList();
      }
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('음성 입력 적용: $text')));
  }

  _UpsertVoiceParseResult _parseUpsertVoice(String input) {
    final raw = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    final lower = raw.toLowerCase();

    String? location;
    for (final l in _locations) {
      if (raw.contains(l)) {
        location = l;
        break;
      }
    }

    String? category;
    for (final c in _categories) {
      if (raw.contains(c)) {
        category = c;
        break;
      }
    }

    final healthTags = <String>{};
    for (final t in HealthGuardrailService.defaultTags) {
      if (raw.contains(t)) healthTags.add(t);
    }

    DateTime? expiry;
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    if (raw.contains('오늘')) {
      expiry = dateOnly;
    } else if (raw.contains('내일')) {
      expiry = dateOnly.add(const Duration(days: 1));
    } else if (raw.contains('모레')) {
      expiry = dateOnly.add(const Duration(days: 2));
    } else {
      final m = RegExp(r'(\d{1,3})\s*일\s*(후|뒤)').firstMatch(raw);
      if (m != null) {
        final days = int.tryParse(m.group(1) ?? '');
        if (days != null) {
          expiry = dateOnly.add(Duration(days: days));
        }
      } else {
        final md = RegExp(r'(\d{1,2})\s*월\s*(\d{1,2})\s*일').firstMatch(raw);
        if (md != null) {
          final month = int.tryParse(md.group(1) ?? '');
          final day = int.tryParse(md.group(2) ?? '');
          if (month != null && day != null) {
            var candidate = DateTime(dateOnly.year, month, day);
            if (candidate.isBefore(
              dateOnly.subtract(const Duration(days: 1)),
            )) {
              candidate = DateTime(dateOnly.year + 1, month, day);
            }
            expiry = candidate;
          }
        }
      }
    }

    String? qtyText;
    String? unit;
    const unitPattern =
        r'(개|봉지|봉|팩|통|단|모|장|판|박스|상자|병|캔|그램|그람|g|kg|킬로|킬로그램|ml|밀리리터|l|리터)';
    final qtyMatch = RegExp(
      r'(\d+(?:[\.,]\d+)?)\s*' + unitPattern,
    ).firstMatch(lower);
    if (qtyMatch != null) {
      qtyText = (qtyMatch.group(1) ?? '').replaceAll(',', '.');
      unit = _normalizeUnit(qtyMatch.group(2));
    }

    String? priceText;
    final priceMatch = RegExp(r'(\d{1,9})\s*원').firstMatch(raw);
    if (priceMatch != null) {
      priceText = priceMatch.group(1);
    }

    String candidateName = raw;
    for (final l in _locations) {
      candidateName = candidateName.replaceAll(l, ' ');
    }
    for (final c in _categories) {
      candidateName = candidateName.replaceAll(c, ' ');
    }
    for (final t in HealthGuardrailService.defaultTags) {
      candidateName = candidateName.replaceAll(t, ' ');
    }
    candidateName = candidateName
        .replaceAll(RegExp(r'(오늘|내일|모레|유통기한|기한|까지|후|뒤)'), ' ')
        .replaceAll(
          RegExp(r'(등록|추가|저장|입력|해줘|해주세요|할래|해|좀|우리집|식재료|생활용품|품목|재료)'),
          ' ',
        );
    candidateName = candidateName.replaceAll(RegExp(r'\d{1,9}\s*원'), ' ');
    candidateName = candidateName.replaceAll(
      RegExp(r'(\d{1,3})\s*일\s*(후|뒤)'),
      ' ',
    );
    candidateName = candidateName.replaceAll(
      RegExp(r'(\d{1,2})\s*월\s*(\d{1,2})\s*일'),
      ' ',
    );
    if (qtyMatch != null) {
      candidateName = candidateName.replaceAll(qtyMatch.group(0) ?? '', ' ');
    }
    candidateName = candidateName.replaceAll(RegExp(r'\s+'), ' ').trim();

    final name = candidateName.isEmpty ? null : candidateName;

    return _UpsertVoiceParseResult(
      name: name,
      quantityText: qtyText,
      unit: unit,
      location: location,
      category: category,
      expiryDate: expiry,
      priceText: priceText,
      healthTags: healthTags,
    );
  }

  String? _normalizeUnit(String? rawUnit) {
    if (rawUnit == null) return null;
    final u = rawUnit.trim().toLowerCase();
    switch (u) {
      case '봉지':
        return '봉';
      case '상자':
        return '박스';
      case '그램':
      case '그람':
        return 'g';
      case '킬로':
      case '킬로그램':
        return 'kg';
      case '밀리리터':
        return 'ml';
      case '리터':
      case 'l':
        return 'L';
      default:
        return rawUnit.trim();
    }
  }

  Future<void> _loadLastCategory() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_kLastCategory)?.trim();
    if (!mounted) return;
    if (last == null || last.isEmpty) return;
    if (!_categories.contains(last)) return;
    setState(() {
      _category = last;
    });
  }

  Future<void> _saveLastCategory(String category) async {
    final next = category.trim();
    if (next.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastCategory, next);
  }

  Future<void> _loadLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_kLastLocation)?.trim();
    if (!mounted) return;
    if (last == null || last.isEmpty) return;
    if (!_locations.contains(last)) return;
    setState(() {
      _location = last;
    });
  }

  Future<void> _saveLastLocation(String location) async {
    final next = location.trim();
    if (next.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastLocation, next);
  }

  Future<void> _loadLastUnit() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_kLastUnit)?.trim();
    if (!mounted) return;
    if (last == null || last.isEmpty) return;

    // Only override when the field is still at default / empty.
    final current = _unitController.text.trim();
    if (current.isNotEmpty && current != '개') return;

    setState(() {
      _unitController.text = last;
    });
  }

  Future<void> _saveLastUnit(String unit) async {
    final next = unit.trim();
    if (next.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastUnit, next);
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

  String _historySubtitle(ShoppingCartHistoryEntry item) {
    final timeLabel = DateFormat('HH:mm').format(item.at);
    return '${item.quantity}개 / $timeLabel';
  }

  String _expiryButtonLabel(DateTime? suggestedDate) {
    if (_pickedExpiryDate == null) {
      if (suggestedDate == null) return '날짜 선택';
      final predicted = DateFormat('yyyy-MM-dd').format(suggestedDate);
      return '예측: $predicted';
    }

    final manual = DateFormat('yyyy-MM-dd').format(_pickedExpiryDate!);
    return '수동: $manual';
  }

  void _updateTotal() {
    if (widget.existing == null) return;
    final double current = widget.existing!.quantity;
    final double add = double.tryParse(_addQtyController.text) ?? 0;
    final double sub = double.tryParse(_subQtyController.text) ?? 0;
    double result = current + add - sub;
    if (result < 0) result = 0;

    final String text = result == result.toInt()
        ? result.toInt().toString()
        : result.toString();

    // Avoid cursor jumps when editing directly by updating only when needed.
    // (We may later disable direct edit if this mode remains confusing.)
    if (_quantityController.text != text) {
      _quantityController.text = text;
    }
  }

  Future<void> _showHistoryPicker() async {
    final accountName = await UserPrefService.getLastAccountName();
    if (accountName == null) return;

    final history = await UserPrefService.getShoppingCartHistory(
      accountName: accountName,
    );

    if (!mounted) return;

    // Group by date
    final grouped = <String, List<ShoppingCartHistoryEntry>>{};
    for (final entry in history) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.at);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '쇼핑 기록에서 가져오기',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: sortedKeys.length,
                    itemBuilder: (ctx, i) {
                      final dateKey = sortedKeys[i];
                      final items = grouped[dateKey]!;
                      return ExpansionTile(
                        title: Text('$dateKey (${items.length}개)'),
                        children: [
                          ...items.map((item) {
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text(_historySubtitle(item)),
                              trailing: IconButton(
                                icon: const Icon(Icons.playlist_add),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _startImport(
                                    items,
                                    startIndex: items.indexOf(item),
                                  );
                                },
                              ),
                            );
                          }),
                          ListTile(
                            title: const Text(
                              '이 날짜의 모든 항목 가져오기',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            leading: const Icon(Icons.playlist_play),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              _startImport(items);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startImport(
    List<ShoppingCartHistoryEntry> items, {
    int startIndex = 0,
  }) {
    if (items.isEmpty) return;
    setState(() {
      _importQueue = items.sublist(startIndex);
      _importTotal = _importQueue.length;
    });
    _loadNextFromQueue();
  }

  void _loadNextFromQueue() {
    if (_importQueue.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('모든 항목을 가져왔습니다.')));
      }
      return;
    }

    final item = _importQueue.removeAt(0);
    setState(() {
      _nameController.text = item.name;
      _purchaseDate = item.at;
      _pickedExpiryDate = null; // Reset expiry for new item
      _memoController.clear();
      _quantityController.text = item.quantity.toString();
      _unitController.text = '개'; // Default unit for imported items
    });
  }

  void _skipCurrentImport() {
    _loadNextFromQueue();
  }

  void _stopImport() {
    setState(() {
      _importQueue.clear();
      _importTotal = 0;
    });
  }

  FoodExpiryPrediction? _prediction() {
    return FoodExpiryPredictionEngine.predict(
      name: _nameController.text,
      memo: _memoController.text,
      purchaseDate: _purchaseDate,
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final p = _prediction();
    final effective = _pickedExpiryDate ?? p?.suggestedExpiryDate;
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final unit = _unitController.text.trim().isEmpty
        ? '개'
        : _unitController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final supplier = _supplierController.text.trim();

    if (name.isEmpty || effective == null) {
      return;
    }

    if (widget.existing == null) {
      await ConsumableInventoryService.instance.addItem(
        name: name,
        purchaseDate: _purchaseDate,
        expiryDate: effective,
        currentStock: quantity,
        unit: unit,
        category: _category,
        location: _location,
        price: price,
        supplier: supplier,
        healthTags: _healthTags,
      );
    } else {
      final used = widget.existing!.quantity - quantity;
      if (used > 0) {
        final warning = await HealthGuardrailService.recordUsageAndCheck(
          itemName: name,
          amount: used,
          tags: _healthTags,
        );
        if (mounted && warning != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(warning.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      final updatedItem = ConsumableInventoryItem(
        id: widget.existing!.id,
        name: name,
        currentStock: quantity,
        unit: unit,
        threshold: 1.0,
        bundleSize: 1.0,
        category: _category,
        location: _location,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        healthTags: _healthTags,
        expiryDate: effective,
        purchaseDate: _purchaseDate,
        price: price,
        supplier: supplier,
      );
      await ConsumableInventoryService.instance.updateItem(updatedItem);
    }

    if (_importQueue.isEmpty) {
      final message =
          await FeedbackService.getFoodExpirySavedMessageWithTemplate(
            itemName: name,
            expiryDate: effective,
          );
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, message);
    }

    await _saveLastCategory(_category);
    await _saveLastLocation(_location);
    await _saveLastUnit(unit);

    // Handle "Add to shopping list" if checked
    if (_addToShoppingList) {
      final accountName = await UserPrefService.getLastAccountName();
      if (accountName != null) {
        final currentItems = await UserPrefService.getShoppingCartItems(
          accountName: accountName,
        );
        final now = DateTime.now();
        final newItem = ShoppingCartItem(
          id: 'sc_${now.microsecondsSinceEpoch}',
          name: name,
          quantity: quantity.toInt(),
          unitPrice: price,
          createdAt: now,
          updatedAt: now,
        );
        await UserPrefService.setShoppingCartItems(
          accountName: accountName,
          items: [newItem, ...currentItems],
        );
      }
    }

    if (_importQueue.isNotEmpty) {
      _loadNextFromQueue();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Widget _buildFieldLabel(String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  InputDecoration _formInputDecoration({
    String? hintText,
    Widget? suffixIcon,
    EdgeInsets? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 2),
      ),
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true,
    );
  }

  // 박스 수량 자동 계산 로직
  void _calculateTotalQuantity() {
    final box = double.tryParse(_boxQtyController.text);
    final pcs = double.tryParse(_pcsPerBoxController.text);

    if (box != null && box > 0 && pcs != null && pcs > 0) {
      final total = box * pcs;
      // 소수점 .0 제거 (예: 20.0 -> 20)
      final text = total == total.toInt() ? total.toInt().toString() : total.toString();
      
      if (_quantityController.text != text) {
        _quantityController.text = text;
      }
    }
  }

  // 최근 지출 내역 연동(One-Stop Flow)
  Future<void> _prefillFromLatestTransaction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? account = prefs.getString('lastAccountName');
      
      // 마지막 계정 정보가 없으면 첫 번째 계정 사용
      if (account == null) {
        final accounts = TransactionService().getAllAccountNames();
        if (accounts.isNotEmpty) account = accounts.first;
      }

      if (account != null) {
        // 1. DB -> Utils 동기화
        await TransactionByDateUtils.syncFromDatabase(account);
        // 2. 데이터 로드
        final groupedData = await TransactionByDateUtils.load(account);

        if (groupedData.isNotEmpty) {
          // 날짜 내림차순 정렬 (최신순)
          final sortedDates = groupedData.keys.toList()..sort((a, b) => b.compareTo(a));
          final latestDate = sortedDates.first;
          final txList = groupedData[latestDate];

          if (txList != null && txList.isNotEmpty) {
            final latestTx = txList.first; // 그 날짜의 가장 최신 항목
            
            if (!mounted) return;
            setState(() {
              // 이름이 비어있으면 자동 채움
              if (_nameController.text.isEmpty) {
                _nameController.text = latestTx['name'] ?? '';
              }
              // 가격 채움
              if (latestTx['amount'] != null) {
                _priceController.text = (latestTx['amount'] as num).toInt().toString();
              }
              // 수량 채움 (DB에는 총 수량만 있으므로 Box 필드가 아닌 총 수량 필드에 바로 입력)
              if (latestTx['quantity'] != null) {
                 _quantityController.text = latestTx['quantity'].toString();
              }
            });
          }
        }
      }
    } catch (e) {
      // Auto-fill error silently ignored
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = _prediction();

    final isImporting = _importQueue.isNotEmpty || _importTotal > 0;
    final remaining = _importQueue.length;
    final currentImportIndex = _importTotal - remaining;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      widget.existing == null
                          ? '식료품/생활용품 등록'
                          : '식료품/생활용품 정보 수정',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 3,
                      width: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (isImporting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Chip(
                    label: Text(
                      '가져오기 중 ${currentImportIndex + 1} / $_importTotal',
                    ),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  ),
                ),

              // Item Name
              _buildFieldLabel('품목명', theme),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      decoration: _formInputDecoration(
                        hintText: '품목명을 입력하세요',
                        suffixIcon: const Icon(Icons.edit_note, size: 20),
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (AppConstants.voiceInputEnabled) ...[
                    IconButton.outlined(
                      onPressed: _toggleVoiceInput,
                      icon: Icon(
                        _isVoiceListening
                            ? IconCatalog.stopCircle
                            : IconCatalog.mic,
                      ),
                      tooltip: _isVoiceListening ? '음성 입력 중지' : '음성 입력',
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton.outlined(
                    onPressed: _showHistoryPicker,
                    icon: const Icon(IconCatalog.history),
                    tooltip: '쇼핑 기록 불러오기',
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),

              // Category
              _buildFieldLabel('카테고리', theme),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _formInputDecoration(),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),

              // Health Tags
              _buildFieldLabel('건강 태그 (선택)', theme),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HealthGuardrailService.defaultTags.map((tag) {
                  final isSelected = _healthTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (v) {
                      setState(() {
                        final next = <String>{..._healthTags};
                        if (v) {
                          next.add(tag);
                        } else {
                          next.remove(tag);
                        }
                        _healthTags = next.toList();
                      });
                    },
                  );
                }).toList(),
              ),

              // Quantity & Unit
              // 1. Box Calculator
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('BOX 수량', theme),
                          TextField(
                            controller: _boxQtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _formInputDecoration(hintText: 'Box 수'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      child: Text('x', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('입수량(Pcs)', theme),
                          TextField(
                            controller: _pcsPerBoxController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _formInputDecoration(hintText: '개/Box'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Total Quantity & Unit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('총 수량 (Total)', theme),
                        TextField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _formInputDecoration(hintText: '0'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('단위', theme),
                        TextField(
                          controller: _unitController,
                          decoration: _formInputDecoration(
                            hintText: '단위 (예: 개, g, kg)',
                          ),
                        ),
                        const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              ),

              // Location
              _buildFieldLabel('보관 위치', theme),
              DropdownButtonFormField<String>(
                initialValue: _location,
                decoration: _formInputDecoration(),
                items: _locations.map((l) {
                  return DropdownMenuItem(value: l, child: Text(l));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _location = val);
                },
              ),

              // Expiration Date
              _buildFieldLabel('유통기한', theme),
              InkWell(
                onTap: () async {
                  final initial =
                      _pickedExpiryDate ??
                      p?.suggestedExpiryDate ??
                      DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) {
                    setState(() => _pickedExpiryDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _expiryButtonLabel(p?.suggestedExpiryDate),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined, size: 18),
                    ],
                  ),
                ),
              ),

              // Price
              _buildFieldLabel('가격', theme),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _formInputDecoration(hintText: '0'),
              ),

              // Supplier
              _buildFieldLabel('구입처', theme),
              TextField(
                controller: _supplierController,
                decoration: _formInputDecoration(
                  hintText: '구입처를 입력하세요',
                  suffixIcon: const Icon(Icons.keyboard_arrow_down),
                ),
              ),

              const SizedBox(height: 16),
              // Add to shopping list checkbox
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _addToShoppingList,
                      onChanged: (val) =>
                          setState(() => _addToShoppingList = val ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '장바구니에 추가',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.existing == null ? '등록하기' : '수정하기',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              if (isImporting) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _skipCurrentImport,
                        child: const Text('Skip This Item'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: _stopImport,
                        child: const Text(
                          'Stop Import',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
