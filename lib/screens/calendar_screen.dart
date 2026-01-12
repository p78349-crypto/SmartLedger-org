library calendar_screen;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../theme/app_colors.dart';
import '../utils/refund_utils.dart';

part 'calendar_screen_helpers.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final NumberFormat _currencyFormat = NumberFormat.compact(locale: 'ko');

  @override
  void initState() {
    super.initState();
    try {
      Intl.defaultLocale = 'ko_KR';
    } catch (e) {
      debugPrint('⚠️ Locale initialization warning: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: TransactionService().loadTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text('${widget.accountName} 달력'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text('${widget.accountName} 달력'),
            ),
            body: Center(child: Text('데이터 로드 오류: ${snapshot.error}')),
          );
        }

        final transactionService = TransactionService();
        final transactions = transactionService.getTransactions(
          widget.accountName,
        );
        final events = _groupTransactionsByDay(transactions);

        return Scaffold(
          appBar: AppBar(title: Text('${widget.accountName} 달력')),
          body: _buildCalendar(context, events),
        );
      },
    );
  }
}
