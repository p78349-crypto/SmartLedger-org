import 'package:flutter/material.dart';
import 'asset.dart';

class DashboardSummary {
  final double totalAssets;
  final double totalCostBasis;
  final double totalProfitLoss;
  final double totalProfitLossRate;
  final Color profitLossColor;
  final String profitLossLabel;
  final String formattedTotalAssets;
  final String formattedProfitLoss;
  final String formattedProfitLossRate;

  DashboardSummary({
    required this.totalAssets,
    required this.totalCostBasis,
    required this.totalProfitLoss,
    required this.totalProfitLossRate,
    required this.profitLossColor,
    required this.profitLossLabel,
    required this.formattedTotalAssets,
    required this.formattedProfitLoss,
    required this.formattedProfitLossRate,
  });

  bool get hasProfit => totalProfitLoss > 0;
  bool get hasLoss => totalProfitLoss < 0;
  bool get isNeutral => totalProfitLoss == 0;
}

class AssetCardInfo {
  final Asset asset;
  final double profitLoss;
  final double profitLossRate;
  final Color profitLossColor;
  final String formattedAmount;
  final String? formattedCostBasis;
  final String formattedProfitLoss;
  final String formattedProfitLossRate;

  AssetCardInfo({
    required this.asset,
    required this.profitLoss,
    required this.profitLossRate,
    required this.profitLossColor,
    required this.formattedAmount,
    this.formattedCostBasis,
    required this.formattedProfitLoss,
    required this.formattedProfitLossRate,
  });

  bool get hasProfit => profitLoss > 0;
  bool get hasLoss => profitLoss < 0;
  bool get isNeutral => profitLoss == 0;
  bool get hasCostBasis => formattedCostBasis != null;
}
