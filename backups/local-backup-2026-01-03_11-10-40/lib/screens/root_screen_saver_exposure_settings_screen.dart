import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/utils/pref_keys.dart';
import 'package:smart_ledger/widgets/root_auth_gate.dart';

class RootScreenSaverExposureSettingsScreen extends StatefulWidget {
  const RootScreenSaverExposureSettingsScreen({super.key});

  @override
  State<RootScreenSaverExposureSettingsScreen> createState() =>
      _RootScreenSaverExposureSettingsScreenState();
}

class _RootScreenSaverExposureSettingsScreenState
    extends State<RootScreenSaverExposureSettingsScreen> {
  bool _showAssetSummary = true;
  bool _showCharts = true;
  bool _showBudget = true;
  bool _showEmergency = true;
  bool _showSpending = true;
  bool _showRecent = true;
  bool _showAssetFlow = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _showAssetSummary =
          prefs.getBool(PrefKeys.screenSaverShowAssetSummary) ?? true;
      _showCharts = prefs.getBool(PrefKeys.screenSaverShowCharts) ?? true;
      _showBudget = prefs.getBool(PrefKeys.screenSaverShowBudget) ?? true;
      _showEmergency = prefs.getBool(PrefKeys.screenSaverShowEmergency) ?? true;
      _showSpending = prefs.getBool(PrefKeys.screenSaverShowSpending) ?? true;
      _showRecent = prefs.getBool(PrefKeys.screenSaverShowRecent) ?? true;
      _showAssetFlow = prefs.getBool(PrefKeys.screenSaverShowAssetFlow) ?? true;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return RootAuthGate(
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.visibility_outlined, color: Colors.amber),
              SizedBox(width: 8),
              Text('보호기 노출자료(ROOT)'),
            ],
          ),
        ),
        body: ListView(
          children: [
            const ListTile(
              title: Text('노출 자료 설정'),
              subtitle: Text('보호기에서 보여줄 패널을 선택합니다.'),
            ),
            SwitchListTile(
              title: const Text('자산 요약'),
              value: _showAssetSummary,
              onChanged: (v) async {
                await _setBool(PrefKeys.screenSaverShowAssetSummary, v);
                if (!mounted) return;
                setState(() => _showAssetSummary = v);
              },
            ),
            SwitchListTile(
              title: const Text('차트(자산 배분/추이)'),
              value: _showCharts,
              onChanged: (v) async {
                await _setBool(PrefKeys.screenSaverShowCharts, v);
                if (!mounted) return;
                setState(() => _showCharts = v);
              },
            ),
            SwitchListTile(
              title: const Text('예산 상태'),
              value: _showBudget,
              onChanged: (v) async {
                await _setBool(PrefKeys.screenSaverShowBudget, v);
                if (!mounted) return;
                setState(() => _showBudget = v);
              },
            ),
            SwitchListTile(
              title: const Text('비상금 상태'),
              value: _showEmergency,
              onChanged: (v) async {
                await _setBool(PrefKeys.screenSaverShowEmergency, v);
                if (!mounted) return;
                setState(() => _showEmergency = v);
              },
            ),
            SwitchListTile(
              title: const Text('지출 건수'),
              value: _showSpending,
              onChanged: (v) async {
                await _setBool(PrefKeys.screenSaverShowSpending, v);
                if (!mounted) return;
                setState(() => _showSpending = v);
              },
            ),
            SwitchListTile(
              title: const Text('최근 거래 요약'),
              value: _showRecent,
              onChanged: (v) async {
                await _setBool(PrefKeys.screenSaverShowRecent, v);
                if (!mounted) return;
                setState(() => _showRecent = v);
              },
            ),
            SwitchListTile(
              title: const Text('자산 흐름 요약'),
              value: _showAssetFlow,
              onChanged: (v) async {
                await _setBool(PrefKeys.screenSaverShowAssetFlow, v);
                if (!mounted) return;
                setState(() => _showAssetFlow = v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
