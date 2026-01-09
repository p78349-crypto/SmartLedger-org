import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_locale_controller.dart';
import '../utils/pref_keys.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _language = AppLocaleController.systemCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Keep reading the same pref key for backward compatibility.
    final prefs = await SharedPreferences.getInstance();
    final lang =
        prefs.getString(PrefKeys.language) ?? AppLocaleController.systemCode;

    if (!mounted) return;
    setState(() {
      _language = lang;
      _isLoading = false;
    });
  }

  Future<void> _saveLanguage(String language) async {
    setState(() => _language = language);
    await AppLocaleController.instance.setLanguageCode(language);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('언어를 저장했습니다.')));
  }

  String _labelFor(String code) {
    switch (code) {
      case AppLocaleController.systemCode:
        return '시스템(자동)';
      case 'en':
        return '영어';
      case 'ja':
        return '일본어';
      case 'ko':
      default:
        return '한국어';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('언어 설정')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '언어 선택',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: _language,
                  items: const [
                    DropdownMenuItem(
                      value: AppLocaleController.systemCode,
                      child: Text('시스템(자동)'),
                    ),
                    DropdownMenuItem(value: 'ko', child: Text('한국어')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ja', child: Text('日本語')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    _saveLanguage(v);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  '현재 언어: ${_labelFor(_language)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }
}
