import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_pref_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/pref_keys.dart';
import '../widgets/background_widget.dart';

part 'settings_screen_cards.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _zeroQuickButtonsEnabled = false;
  bool _aiInvestmentConsentAccepted = false;
  int? _aiInvestmentConsentAcceptedAtMs;
  String? _aiInvestmentConsentVersion;
  String? _aiInvestmentConsentLocale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final zeroQuickButtonsEnabled =
        prefs.getBool(PrefKeys.zeroQuickButtonsEnabled) ?? false;
    final aiInvestmentConsentAccepted =
        prefs.getBool(PrefKeys.aiInvestmentConsentAccepted) ?? false;
    final aiInvestmentConsentAcceptedAtMs =
        prefs.getInt(PrefKeys.aiInvestmentConsentAcceptedAtMs);
    final aiInvestmentConsentVersion =
        prefs.getString(PrefKeys.aiInvestmentConsentVersion);
    final aiInvestmentConsentLocale =
        prefs.getString(PrefKeys.aiInvestmentConsentLocale);
    if (!mounted) return;
    setState(() {
      _zeroQuickButtonsEnabled = zeroQuickButtonsEnabled;
      _aiInvestmentConsentAccepted = aiInvestmentConsentAccepted;
      _aiInvestmentConsentAcceptedAtMs = aiInvestmentConsentAcceptedAtMs;
      _aiInvestmentConsentVersion = aiInvestmentConsentVersion;
      _aiInvestmentConsentLocale = aiInvestmentConsentLocale;
      _isLoading = false;
    });
  }

  String _formatConsentDate(int? ms) {
    if (ms == null) return '기록 없음';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showAiInvestmentConsentDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final acceptedText = _aiInvestmentConsentAccepted ? '동의됨' : '미동의';
        final acceptedColor = _aiInvestmentConsentAccepted
            ? Colors.green
            : Theme.of(dialogContext).colorScheme.error;

        return AlertDialog(
          title: const Text('투자 분석 동의 기록'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('상태: '),
                  Text(
                    acceptedText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: acceptedColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('동의 시각: ${_formatConsentDate(_aiInvestmentConsentAcceptedAtMs)}'),
              const SizedBox(height: 4),
              Text('동의 버전: ${_aiInvestmentConsentVersion ?? '기록 없음'}'),
              const SizedBox(height: 4),
              Text('동의 로케일: ${_aiInvestmentConsentLocale ?? '기록 없음'}'),
            ],
          ),
          actions: [
            if (_aiInvestmentConsentAccepted)
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(PrefKeys.aiInvestmentConsentAccepted);
                  await prefs.remove(PrefKeys.aiInvestmentConsentAcceptedAtMs);
                  await prefs.remove(PrefKeys.aiInvestmentConsentVersion);
                  await prefs.remove(PrefKeys.aiInvestmentConsentLocale);
                  if (!mounted) return;
                  setState(() {
                    _aiInvestmentConsentAccepted = false;
                    _aiInvestmentConsentAcceptedAtMs = null;
                    _aiInvestmentConsentVersion = null;
                    _aiInvestmentConsentLocale = null;
                  });
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('투자 분석 동의 기록을 초기화했습니다.')),
                  );
                },
                child: const Text('기록 초기화'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        BackgroundHelper.colorNotifier,
        BackgroundHelper.typeNotifier,
        BackgroundHelper.imagePathNotifier,
        BackgroundHelper.blurNotifier,
      ]),
      builder: (context, _) {
        final bgColor = BackgroundHelper.colorNotifier.value;
        final bgType = BackgroundHelper.typeNotifier.value;
        final bgImagePath = BackgroundHelper.imagePathNotifier.value;
        final bgBlur = BackgroundHelper.blurNotifier.value;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text('설정'),
            backgroundColor: bgType == 'image' ? Colors.transparent : null,
            elevation: 0,
          ),
          extendBodyBehindAppBar: bgType == 'image',
          body: Stack(
            children: [
              if (bgType == 'image' && bgImagePath != null) ...[
                Positioned.fill(
                  child: Image.file(
                    File(bgImagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        ColoredBox(color: bgColor),
                  ),
                ),
                if (bgBlur > 0)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: bgBlur, sigmaY: bgBlur),
                      child: const ColoredBox(color: Colors.transparent),
                    ),
                  ),
                Positioned.fill(
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.2)),
                ),
              ],
              ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                children: [
                  buildSectionHeader(context, '입력 편의'),
                  buildSwitchCard(
                    context,
                    icon: IconCatalog.keyboardAltOutlined,
                    title: '숫자 입력 보조',
                    subtitle: '숫자 입력 시 0/00/000 버튼을 표시합니다.',
                    value: _zeroQuickButtonsEnabled,
                    onChanged: _isLoading ? null : setZeroQuickButtonsEnabled,
                  ),
                  const SizedBox(height: 24),
                  buildSectionHeader(context, '법적 고지'),
                  buildSettingsCard(
                    context,
                    icon: Icons.gavel_outlined,
                    title: '투자 분석 동의 기록',
                    subtitle: _aiInvestmentConsentAccepted
                        ? '동의됨 · ${_formatConsentDate(_aiInvestmentConsentAcceptedAtMs)}'
                        : '미동의 · 기록 없음',
                    onTap: _showAiInvestmentConsentDialog,
                  ),
                  const SizedBox(height: 24),
                  buildSectionHeader(context, '정보'),
                  buildSettingsCard(
                    context,
                    icon: Icons.description_outlined,
                    title: '오픈소스 라이선스',
                    subtitle: 'SmartLedger 라이선스 정보 확인',
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'SmartLedger',
                        applicationLegalese: 'Copyright (c) 2025 SmartLedger',
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
