import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_ledger/utils/dev_overrides.dart';
import 'package:smart_ledger/utils/pref_keys.dart';
import 'package:smart_ledger/widgets/user_account_auth_gate.dart';

class RootAuthGate extends StatefulWidget {
  const RootAuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<RootAuthGate> createState() => _RootAuthGateState();
}

class _RootAuthGateState extends State<RootAuthGate> {
  bool _checking = true;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    // Dev override: compile-time flag to bypass security during prototype.
    // See: lib/utils/dev_overrides.dart
    if (kDevBypassSecurity) {
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _checking = false;
      });
      return;
    }

    // Developer/testing bypass via SharedPreferences key.
    if (prefs.getBool(PrefKeys.bypassSecurityForTesting) == true) {
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _checking = false;
      });
      return;
    }
    final enabled =
        prefs.getBool(PrefKeys.rootAuthEnabled) ??
        (prefs.getBool(PrefKeys.biometricAuthEnabled) ?? true);
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_enabled) return widget.child;

    return UserAccountAuthGate(child: widget.child);
  }
}

