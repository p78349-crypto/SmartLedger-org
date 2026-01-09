import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/asset_service.dart';
import '../services/recent_input_service.dart';
import '../widgets/smart_input_field.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountName),
        actions: [
          IconButton(
            tooltip: '입력값 되돌리기',
            icon: const Icon(Icons.restart_alt),
            onPressed: _promptRevertToInitial,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildSectionHeader('자산 종류'),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: '자산 종류',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: const [
                            DropdownMenuItem(value: '현금', child: Text('현금')),
                            DropdownMenuItem(
                              value: '예금/적금',
                              child: Text('예금/적금'),
                            ),
                            DropdownMenuItem(
                              value: '소액 투자',
                              child: Text('소액 투자'),
                            ),
                            DropdownMenuItem(
                              value: '기타 실물 자산',
                              child: Text('기타 실물 자산'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _category = v!),
                        ),

                        _buildSectionHeader('기본 정보'),
                        SmartInputField(
                          controller: _nameController,
                          label: '자산명',
                          hint: '예: 시중은행 입출금통장',
                          prefixIcon: const Icon(Icons.label),
                          validator: (v) =>
                              v == null || v.isEmpty ? '자산명을 입력하세요' : null,
                        ),
                        const SizedBox(height: 12),
                        SmartInputField(
                          controller: _amountController,
                          label: '금액',
                          prefixIcon: const Icon(Icons.attach_money),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return '금액을 입력하세요';
                            final n = double.tryParse(v);
                            if (n == null || n < 0) return '유효한 금액을 입력하세요';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        SmartInputField(
                          controller: _locationController,
                          label: '위치(은행/앱/보관장소)',
                          prefixIcon: const Icon(Icons.location_on),
                        ),

                        _buildSectionHeader('메모'),
                        SmartInputField(
                          controller: _memoController,
                          label: '메모(선택)',
                          prefixIcon: const Icon(Icons.note),
                          suffixIcon: _recentMemos.isEmpty
                              ? null
                              : PopupMenuButton<String>(
                                  tooltip: '최근 메모 선택',
                                  onSelected: (value) {
                                    setState(
                                      () => _memoController.text = value,
                                    );
                                  },
                                  itemBuilder: (context) => _recentMemos
                                      .map(
                                        (memo) => PopupMenuItem(
                                          value: memo,
                                          child: Text(memo),
                                        ),
                                      )
                                      .toList(),
                                ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.save),
                            label: const Text('자산 저장'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '자산 목록',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (assets.isEmpty)
                    const Center(child: Text('등록된 자산이 없습니다.'))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: assets.length,
                      separatorBuilder: (context, idx) => const Divider(),
                      itemBuilder: (context, idx) {
                        final a = assets[idx];
                        final theme = Theme.of(context);
                        return ListTile(
                          title: Text(a.name, style: theme.textTheme.bodyLarge),
                          trailing: Text(
                            '${a.amount.toStringAsFixed(0)}원',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _InitialAssetSimpleSnapshot {
  const _InitialAssetSimpleSnapshot({
    required this.category,
    required this.nameText,
    required this.amountText,
    required this.locationText,
    required this.memoText,
  });

  final String category;
  final String nameText;
  final String amountText;
  final String locationText;
  final String memoText;
}
