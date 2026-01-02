import 'package:flutter/material.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/main_feature_icon_catalog.dart';
import 'package:smart_ledger/utils/page1_bottom_quick_icons.dart';

class Page1BottomIconSettingsScreen extends StatefulWidget {
  final String accountName;

  const Page1BottomIconSettingsScreen({super.key, required this.accountName});

  @override
  State<Page1BottomIconSettingsScreen> createState() =>
      _Page1BottomIconSettingsScreenState();
}

class _Page1BottomIconSettingsScreenState
    extends State<Page1BottomIconSettingsScreen> {
  static const int _pageIndex = Page1BottomQuickIcons.pageIndex;
  static const int _slotCount = Page1BottomQuickIcons.slotCount;

  bool _isLoading = true;

  // The full 12-slot layout.
  List<String> _slots = List<String>.filled(_slotCount, '');

  int _selectedSlotOffset = 0; // 0..11 -> actual slot index = offset
  String? _selectedIconId;

  late final Map<String, MainFeatureIcon> _iconById;
  late final List<MainFeatureIcon> _allowedIcons;

  int _slotIndexForOffset(int offset) => offset;

  String _effectiveSlotIconId(int offset) {
    final idx = _slotIndexForOffset(offset);
    if (idx < 0 || idx >= _slots.length) return '';
    return _slots[idx];
  }

  List<String> _normalizeSlots(List<String> slots) {
    return Page1BottomQuickIcons.normalizeSlots(slots);
  }

  @override
  void initState() {
    super.initState();

    _iconById = {
      for (final icon in MainFeatureIconCatalog.pages.expand((p) => p.items))
        icon.id: icon,
    };

    _allowedIcons = _iconById.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final rawSlots = await UserPrefService.getPageIconSlots(
      accountName: widget.accountName,
      pageIndex: _pageIndex,
      slotCount: _slotCount,
    );

    final normalized = _normalizeSlots(rawSlots);

    final initialIconId = _effectiveSlotIconId(_selectedSlotOffset);
    final nextSelected = initialIconId.isNotEmpty ? initialIconId : null;

    if (!mounted) return;
    setState(() {
      _slots = normalized;
      _selectedIconId = nextSelected;
      _isLoading = false;
    });

    // Best-effort: persist normalization.
    if (normalized.join('|') != rawSlots.join('|')) {
      await UserPrefService.setPageIconSlots(
        accountName: widget.accountName,
        pageIndex: _pageIndex,
        slots: normalized,
      );
    }
  }

  void _selectSlot(int offset) {
    final currentIconId = _effectiveSlotIconId(offset);
    setState(() {
      _selectedSlotOffset = offset;
      _selectedIconId = currentIconId.isNotEmpty ? currentIconId : null;
    });
  }

  Future<void> _apply() async {
    final picked = _selectedIconId;
    if (picked == null || picked.trim().isEmpty) return;

    final idx = _slotIndexForOffset(_selectedSlotOffset);
    final next = List<String>.from(_slots);
    next[idx] = picked;

    final normalized = _normalizeSlots(next);

    setState(() {
      _slots = normalized;
    });

    await UserPrefService.setPageIconSlots(
      accountName: widget.accountName,
      pageIndex: _pageIndex,
      slots: normalized,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('적용했습니다')));
  }

  Widget _buildSlotPicker(ThemeData theme) {
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1) 아이콘 위치 선택 (1~24)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...List.generate(_slotCount, (i) {
          final isSelected = i == _selectedSlotOffset;
          final iconId = _effectiveSlotIconId(i);
          final meta = _iconById[iconId];
          final label = meta?.label ?? (iconId.isEmpty ? '미설정' : iconId);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? scheme.primaryContainer : scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: ListTile(
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? scheme.primary : scheme.outline,
              ),
              title: Text('${i + 1}번 아이콘'),
              subtitle: Text('현재: ${label.replaceAll('\\n', ' ')}'),
              onTap: () => _selectSlot(i),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDataPicker(ThemeData theme) {
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        const Text(
          '2) 표시할 데이터 선택 (전체 목록)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: _allowedIcons.length,
          itemBuilder: (context, index) {
            final icon = _allowedIcons[index];
            final isSelected = icon.id == _selectedIconId;

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selectedIconId = icon.id),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? scheme.primary : scheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected ? scheme.primaryContainer : scheme.surface,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon.icon, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            icon.label.replaceAll('\\n', '\n'),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 22,
                        color: isSelected ? scheme.primary : scheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Block this screen when main pages are globally disabled.
    if (MainFeatureIconCatalog.pageCount == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final canApply = _selectedIconId != null && _selectedIconId!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('1페이지 하단 아이콘')),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: FilledButton.icon(
            onPressed: canApply ? _apply : null,
            icon: const Icon(Icons.check),
            label: Text('적용 (선택: ${_selectedSlotOffset + 1}번)'),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '계정: ${widget.accountName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSlotPicker(theme),
                _buildDataPicker(theme),
                const SizedBox(height: 12),
              ],
            ),
    );
  }
}

