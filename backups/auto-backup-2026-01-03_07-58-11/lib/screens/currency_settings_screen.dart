import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  String _currency = 'KRW';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _currency = prefs.getString(PrefKeys.currency) ?? 'KRW';
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.currency, _currency);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('통화')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 24),
          const Text('통화 단위', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            value: _currency,
            items: const [
              DropdownMenuItem(value: 'KRW', child: Text('KRW(₩)')),
              DropdownMenuItem(value: 'USD', child: Text('USD(\$)')),
              DropdownMenuItem(value: 'EUR', child: Text('EUR(€)')),
              DropdownMenuItem(value: 'JPY', child: Text('JPY(¥)')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _currency = v;
              });
              _save();
            },
          ),
        ],
      ),
    );
  }
}

