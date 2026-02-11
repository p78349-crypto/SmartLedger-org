import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
// intl removed: use DateFormatter for formatting
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';
import '../models/asset_move.dart';
import '../services/asset_move_service.dart';
import '../services/asset_service.dart';
import '../services/budget_service.dart';
import '../services/emergency_fund_service.dart';
import '../services/monthly_agg_cache_service.dart';
import '../services/transaction_service.dart';
import '../utils/asset_dashboard_utils.dart';
import '../utils/asset_flow_stats.dart';
import '../utils/date_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/pref_keys.dart';

part 'in_app_screen_saver_logic.dart';
part 'in_app_screen_saver_build.dart';
part 'in_app_screen_saver_panels.dart';
part 'in_app_screen_saver_cards.dart';
part 'in_app_screen_saver_cards_info.dart';
part 'in_app_screen_saver_data.dart';

const int _exitAuthMaxFailedAttempts = 5;
const Duration _exitAuthLockDuration = Duration(minutes: 10);
const Duration _clockTick = Duration(seconds: 1);
const Duration _dataRefreshTick = Duration(seconds: 15);

class InAppScreenSaver extends StatefulWidget {
  final String accountName;
  final String title;
  final VoidCallback onDismiss;

  const InAppScreenSaver({
    super.key,
    required this.accountName,
    required this.title,
    required this.onDismiss,
  });

  @override
  State<InAppScreenSaver> createState() => _InAppScreenSaverState();
}

class _InAppScreenSaverState extends State<InAppScreenSaver> {
  Timer? _clockTimer;
  Timer? _refreshTimer;

  DateTime _now = DateTime.now();
  _DashboardData? _data;
  String? _error;
  bool _authInProgress = false;

  _ScreenSaverExposureConfig _exposure = const _ScreenSaverExposureConfig();
  String? _backgroundPhotoPath;

  @override
  void initState() {
    super.initState();
    _initMain();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildMain(context);
}
