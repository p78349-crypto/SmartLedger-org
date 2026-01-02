import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/utils/pref_keys.dart';
import 'package:smart_ledger/utils/screen_saver_background_photo.dart';
import 'package:smart_ledger/widgets/root_auth_gate.dart';

class RootScreenSaverSettingsScreen extends StatefulWidget {
  const RootScreenSaverSettingsScreen({super.key});

  @override
  State<RootScreenSaverSettingsScreen> createState() =>
      _RootScreenSaverSettingsScreenState();
}

class _RootScreenSaverSettingsScreenState
    extends State<RootScreenSaverSettingsScreen> {
  bool _screenSaverEnabled = false;
  int _idleSeconds = 60;
  String? _bgPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _screenSaverEnabled = prefs.getBool(PrefKeys.screenSaverEnabled) ?? false;
      _idleSeconds = prefs.getInt(PrefKeys.screenSaverIdleSeconds) ?? 60;
      _bgPath = prefs.getString(PrefKeys.screenSaverLocalBackgroundImagePath);
    });
  }

  Future<void> _pickBackgroundPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final savedPath = await ScreenSaverBackgroundPhoto.saveFromPickedFile(
      pickedFilePath: picked.path,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PrefKeys.screenSaverLocalBackgroundImagePath,
      savedPath,
    );
    if (!mounted) return;
    setState(() => _bgPath = savedPath);
  }

  Future<void> _removeBackgroundPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(PrefKeys.screenSaverLocalBackgroundImagePath);
    await ScreenSaverBackgroundPhoto.deleteIfExists(path);
    await prefs.remove(PrefKeys.screenSaverLocalBackgroundImagePath);
    if (!mounted) return;
    setState(() => _bgPath = null);
  }

  Future<void> _setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.screenSaverEnabled, value);
    if (!mounted) return;
    setState(() => _screenSaverEnabled = value);
  }

  Future<void> _setIdleSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefKeys.screenSaverIdleSeconds, seconds);
    if (!mounted) return;
    setState(() => _idleSeconds = seconds);
  }

  @override
  Widget build(BuildContext context) {
    return RootAuthGate(
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.amber),
              SizedBox(width: 8),
              Text('보호기 설정(ROOT)'),
            ],
          ),
        ),
        body: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('노출자료 설정'),
              subtitle: const Text('보호기에서 무엇을 보여줄지 선택'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(
                  context,
                ).pushNamed(AppRoutes.rootScreenSaverExposureSettings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('보호기 배경 사진(1장, 로컬 전용)'),
              subtitle: Text(
                _bgPath == null ? '설정 안 됨 · 백업에 포함되지 않음' : '설정됨 · 백업에 포함되지 않음',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickBackgroundPhoto,
            ),
            if (_bgPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('배경 사진 삭제'),
                onTap: _removeBackgroundPhoto,
              ),
            SwitchListTile(
              title: const Text('화면 보호기(요약 통계) 자동 실행'),
              subtitle: const Text('무입력 시간이 지나면 오늘 지출 요약 화면 표시'),
              value: _screenSaverEnabled,
              onChanged: _setEnabled,
            ),
            ListTile(
              title: const Text('자동 실행 시간(무입력)'),
              subtitle: Text('$_idleSeconds초'),
              trailing: DropdownButton<int>(
                value: _idleSeconds,
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30초')),
                  DropdownMenuItem(value: 60, child: Text('60초')),
                  DropdownMenuItem(value: 120, child: Text('120초')),
                  DropdownMenuItem(value: 300, child: Text('300초')),
                ],
                onChanged: _screenSaverEnabled
                    ? (v) {
                        if (v == null) return;
                        _setIdleSeconds(v);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

