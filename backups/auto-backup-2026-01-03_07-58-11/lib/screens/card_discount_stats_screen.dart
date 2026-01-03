import 'package:flutter/material.dart';

class CardDiscountStatsScreen extends StatefulWidget {
  const CardDiscountStatsScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<CardDiscountStatsScreen> createState() => _CardDiscountStatsScreenState();
}

class _CardDiscountStatsScreenState extends State<CardDiscountStatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카드 할인 통계'),
      ),
      body: const SizedBox.shrink(),
    );
  }
}

