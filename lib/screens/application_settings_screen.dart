import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'background_settings_screen.dart';
import 'theme_settings_screen.dart';
import '../services/activity_household_estimator_service.dart';
import '../services/health_guardrail_service.dart';
import '../services/replacement_cycle_notification_service.dart';
import '../services/annual_household_report_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/pref_keys.dart';

part 'application_settings_screen_logic.dart';
part 'application_settings_screen_health_dialog.dart';
part 'application_settings_screen_household_dialog.dart';
part 'application_settings_screen_cycle_report_dialog.dart';
part 'application_settings_screen_build.dart';
part 'application_settings_screen_build_sections.dart';

class ApplicationSettingsScreen extends StatefulWidget {
  const ApplicationSettingsScreen({super.key});

  @override
  State<ApplicationSettingsScreen> createState() =>
      _ApplicationSettingsScreenState();
}

class _ApplicationSettingsScreenState extends State<ApplicationSettingsScreen>
    with WidgetsBindingObserver {
  bool _hasPermissions = false;
  bool _isChecking = true;

  bool _txRecentEnabled = true;
  bool _txRecentAutofill = true;
  int _txRecentMaxCount = 30;

  int _stockAutoAddDaysFood = 3;
  int _stockAutoAddDaysHousehold = 5;
  bool _stockDepletionNotifyEnabled = true;

  final TextEditingController _foodExpiryFeedbackTemplateController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    _loadTxRecentInputSettings();
    _loadStockUseSettings();
    _loadFoodExpiryFeedbackTemplate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _foodExpiryFeedbackTemplateController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
      _loadTxRecentInputSettings();
      _loadStockUseSettings();
      _loadFoodExpiryFeedbackTemplate();
    }
  }

  @override
  Widget build(BuildContext context) => _buildMain(context);
}
