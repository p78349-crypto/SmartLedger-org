// ignore_for_file: invalid_use_of_protected_member
part of 'quick_simple_expense_input_screen.dart';

/// 간편지출 음성 입력, 편집, UI 빌더
extension QuickSimpleExpenseInputUI on _QuickSimpleExpenseInputScreenState {
  void _onEdit(int index) {
    final item = _displayedItems[index];
    setState(() {
      _editingIndex = index;
      _controller.text = '${item.description} ${item.amount.toInt()}';
      if (item.payment != '미지정') _controller.text += ' ${item.payment}';
      if (item.store != '미지정') _controller.text += ' ${item.store}';

      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  void _onVoiceInputReceived() {
    final text = VoiceInputBridge.instance.pendingInput.value;
    if (text != null && mounted) {
      _processVoiceInputWithNano(text);
    }
  }

  /// Gemini Nano를 사용하여 음성 입력을 "품목 금액" 형식으로 정규화
  Future<void> _processVoiceInputWithNano(String text) async {
    setState(() {
      _controller.text = text;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });

    try {
      final aicore = AICoreGeminiService();
      if (await aicore.isAvailable()) {
        final result = await aicore.processVoiceInput(text);

        if (result.containsKey('items')) {
          final items = result['items'] as List;
          if (items.isNotEmpty && mounted) {
            final first = items[0] as Map<String, dynamic>;
            final name = first['name'];
            final total = first['total'];

            if (name != null && total != null) {
              setState(() {
                _controller.text = '$name $total';
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length),
                );
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Nano] 간편지출 파싱 오류: $e');
    }
  }

  void _onVoiceSubmitRequested() {
    if (VoiceInputBridge.instance.requestSubmit.value && mounted) {
      _goNext();
      VoiceInputBridge.instance.clear();
    }
  }

  Widget _buildBottomNavigationBar(ThemeData theme) {
    final bottomActionButtonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 8),
      minimumSize: const Size(0, 56),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );

    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(height: 1, thickness: 1, color: theme.dividerColor),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: bottomActionButtonStyle,
                      onPressed: _openHistory,
                      child: const Text(
                        '최근 입력',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: bottomActionButtonStyle,
                      onPressed: _openTop20ExpenseStats,
                      child: const Text(
                        '지출 상위20',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _controller.text += '0',
              child: const Text('0'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _controller.text += '00',
              child: const Text('00'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _controller.text += '000',
              child: const Text('000'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _displayedItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _displayedItems[index];
        final amountLabel = CurrencyFormatter.format(item.amount);
        final paymentLabel =
            item.payment != '미지정' ? ' · ${item.payment}' : '';
        final storeLabel = item.store != '미지정' ? ' · ${item.store}' : '';
        final itemText =
            '${item.description} · $amountLabel$paymentLabel$storeLabel';
        return Card(
          color: _editingIndex == index
              ? theme.colorScheme.primaryContainer
              : null,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _onEdit(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      itemText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickSimpleExpenseHistoryScreen extends StatelessWidget {
  const _QuickSimpleExpenseHistoryScreen({required this.accountName});
  final String accountName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('최근 입력 내역')),
      body: FutureBuilder<List<QuickSimpleExpenseInputEntry>>(
        future: QuickSimpleExpenseInputHistoryService().loadEntries(
          accountName,
        ),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <QuickSimpleExpenseInputEntry>[];
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (items.isEmpty) {
            return const Center(child: Text('저장된 내역이 없습니다.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                SizedBox(key: ValueKey('sep-$index'), height: 8),
            itemBuilder: (context, i) {
              final e = items[i];
              return Card(
                child: ListTile(
                  title: Text(
                    '${e.description} · ${CurrencyFormatter.format(e.amount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${e.payment} · ${e.store}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
