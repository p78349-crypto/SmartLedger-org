library income_split_service;


import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/asset.dart';
import '../models/asset_move.dart';
import '../utils/date_formatter.dart';
import 'asset_move_service.dart';
import 'asset_service.dart';

part 'income_split_service_impl.dart';
part 'income_split_service_asset_moves.dart';

/// 수입 항목
class IncomeItem {
  final String id;
  final String name; // 급여, 보너스, 부업 등
  final double amount;
  final String category; // salary, bonus, sideincome, other

  IncomeItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'amount': amount, 'category': category};
  }

  factory IncomeItem.fromJson(Map<String, dynamic> json) {
    return IncomeItem(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
    );
  }
}

/// 수입 배분 설정 (예금/예산/비상금)
class IncomeSplit {
  final String accountName;
  final List<IncomeItem> incomeItems; // 급여, 보너스 등 수입 항목들
  final double savingsAmount;
  final double budgetAmount;
  final double emergencyAmount;
  final double assetTransferAmount;
  final Map<String, double> categoryBudgets;

  IncomeSplit({
    required this.accountName,
    required this.incomeItems,
    required this.savingsAmount,
    required this.budgetAmount,
    required this.emergencyAmount,
    required this.assetTransferAmount,
    Map<String, double>? categoryBudgets,
  }) : categoryBudgets = categoryBudgets ?? <String, double>{};

  double get totalIncome =>
      incomeItems.fold(0, (sum, item) => sum + item.amount);

  double get categoryBudgetTotal =>
      categoryBudgets.values.fold(0, (sum, amount) => sum + amount);

  Map<String, dynamic> toJson() {
    return {
      'accountName': accountName,
      'incomeItems': incomeItems.map((item) => item.toJson()).toList(),
      'savingsAmount': savingsAmount,
      'budgetAmount': budgetAmount,
      'emergencyAmount': emergencyAmount,
      'assetTransferAmount': assetTransferAmount,
      'categoryBudgets': categoryBudgets,
    };
  }

  factory IncomeSplit.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['incomeItems'] as List<dynamic>?;
    final items = itemsJson != null
        ? itemsJson
              .map((item) => IncomeItem.fromJson(item as Map<String, dynamic>))
              .toList()
        : <IncomeItem>[];

    return IncomeSplit(
      accountName: json['accountName'] as String,
      incomeItems: items,
      savingsAmount: (json['savingsAmount'] as num?)?.toDouble() ?? 0,
      budgetAmount: (json['budgetAmount'] as num?)?.toDouble() ?? 0,
      emergencyAmount: (json['emergencyAmount'] as num?)?.toDouble() ?? 0,
      assetTransferAmount:
          (json['assetTransferAmount'] as num?)?.toDouble() ?? 0,
      categoryBudgets:
          (json['categoryBudgets'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ??
          <String, double>{},
    );
  }
}
