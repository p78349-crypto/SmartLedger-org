library asset_simple_input_screen;

import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/asset_service.dart';
import '../services/recent_input_service.dart';
import '../widgets/smart_input_field.dart';

part 'asset_simple_input_screen_ui.dart';

class AssetSimpleInputScreen extends StatefulWidget {
  final String accountName;
  const AssetSimpleInputScreen({
    super.key,
    required this.accountName,
    this.initialCategory,
    this.initialName,
    this.initialAmount,
    this.initialLocation,
    this.initialMemo,
    this.autoSubmitOnStart = false,
  });

  final String? initialCategory;
  final String? initialName;
  final double? initialAmount;
  final String? initialLocation;
  final String? initialMemo;
  final bool autoSubmitOnStart;

  @override
  State<AssetSimpleInputScreen> createState() => _AssetSimpleInputScreenState();
}

class _AssetSimpleInputScreenState extends State<AssetSimpleInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  String _category = '현금';
  List<String> _recentMemos = const [];

  _InitialAssetSimpleSnapshot? _initialSnapshot;

  String get _memoPrefsKey => 'recent_memos_asset_simple_${widget.accountName}';

  @override
  void initState() {
    super.initState();
    final category = (widget.initialCategory ?? '').trim();
    if (category.isNotEmpty) {
      _category = category;
    }
    final initialName = (widget.initialName ?? '').trim();
    if (initialName.isNotEmpty) {
      _nameController.text = initialName;
    }
    final initialAmount = widget.initialAmount;
    if (initialAmount != null) {
      final amountText = initialAmount == initialAmount.roundToDouble()
          ? initialAmount.toStringAsFixed(0)
          : initialAmount.toString();
      _amountController.text = amountText;
    }
    final initialLocation = (widget.initialLocation ?? '').trim();
    if (initialLocation.isNotEmpty) {
      _locationController.text = initialLocation;
    }
    final initialMemo = (widget.initialMemo ?? '').trim();
    if (initialMemo.isNotEmpty) {
      _memoController.text = initialMemo;
    }
    _loadRecentMemos();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _locationController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentMemos() async {
    final values = await RecentInputService.loadValues(_memoPrefsKey);
    if (!mounted) return;
    setState(() {
      _recentMemos = values;
      if (_memoController.text.isEmpty && values.isNotEmpty) {
        _memoController.text = values.first;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureInitialSnapshotIfNeeded();
    });

    if (widget.autoSubmitOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _submit();
        }
      });
    }
  }

  void _captureInitialSnapshotIfNeeded() {
    if (!mounted) return;
    if (_initialSnapshot != null) return;
    _initialSnapshot = _InitialAssetSimpleSnapshot(
      category: _category,
      nameText: _nameController.text,
      amountText: _amountController.text,
      locationText: _locationController.text,
      memoText: _memoController.text,
    );
  }

  Future<void> _promptRevertToInitial() async {
    _captureInitialSnapshotIfNeeded();
    final snapshot = _initialSnapshot;
    if (snapshot == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('입력값 되돌리기'),
          content: const Text('화면을 열었을 때의 입력값으로 되돌릴까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('되돌리기'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      FocusScope.of(context).unfocus();
      setState(() {
        _category = snapshot.category;
        _nameController.text = snapshot.nameText;
        _amountController.text = snapshot.amountText;
        _locationController.text = snapshot.locationText;
        _memoController.text = snapshot.memoText;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final messenger = ScaffoldMessenger.of(context);
      // 실무적으로 필요한 정보만 저장 (자산명, 종류, 금액, 위치, 메모)
      final AssetCategory category = switch (_category) {
        '현금' => AssetCategory.cash,
        '예금/적금' => AssetCategory.deposit,
        '소액 투자' => AssetCategory.stock,
        _ => AssetCategory.other,
      };
      final asset = Asset(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name:
            '$_category | ${_nameController.text.trim()} | '
            '${_locationController.text.trim()}',
        amount: double.parse(_amountController.text.trim()),
        category: category,
        memo: _memoController.text.trim(),
      );
      final memoValue = _memoController.text.trim();
      await AssetService().addAsset(widget.accountName, asset);
      if (memoValue.isNotEmpty) {
        await RecentInputService.saveValue(_memoPrefsKey, memoValue);
        await _loadRecentMemos();
      }
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('자산이 저장되었습니다.')));
      setState(() {
        _nameController.clear();
        _amountController.clear();
        _locationController.clear();
        _memoController
          ..clear()
          ..text = _recentMemos.isNotEmpty ? _recentMemos.first : '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final assets = AssetService().getAssets(widget.accountName);
    return _buildScaffold(context, assets);
  }
}
