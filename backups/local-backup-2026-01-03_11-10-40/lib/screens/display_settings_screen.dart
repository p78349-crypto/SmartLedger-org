import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisplaySettingsScreen extends StatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  State<DisplaySettingsScreen> createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends State<DisplaySettingsScreen> {
  static const String _fontSizeKey = 'font_size';
  static const String _showTimeInListKey = 'show_time_in_list';

  double _fontSize = 16;
  bool _showTimeInList = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fontSize = prefs.getDouble(_fontSizeKey) ?? 16;
      _showTimeInList = prefs.getBool(_showTimeInListKey) ?? true;
    });
  }

  Future<void> _saveFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, _fontSize);
  }

  Future<void> _saveShowTimeInList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showTimeInListKey, _showTimeInList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('표시/폰트')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 24),
          const Text('표시', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('지출/수입/이체 시.분표시'),
            value: _showTimeInList,
            onChanged: (v) {
              setState(() {
                _showTimeInList = v;
              });
              _saveShowTimeInList();
            },
          ),
          const Divider(height: 32),
          const SizedBox(height: 16),
          const Text('폰트 크기 설정', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            min: 12,
            max: 24,
            divisions: 6,
            value: _fontSize,
            label: '${_fontSize.toInt()}px',
            onChanged: (v) => setState(() => _fontSize = v),
            onChangeEnd: (_) => _saveFontSize(),
          ),
        ],
      ),
    );
  }
}
