import 'package:flutter/material.dart';

import '../services/quick_simple_expense_input_history_service.dart';
import '../utils/currency_formatter.dart';

/// Screen that shows previously entered quick-expense items.
class QuickSimpleExpenseHistoryScreen extends StatelessWidget {
  const QuickSimpleExpenseHistoryScreen({super.key, required this.accountName});

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
