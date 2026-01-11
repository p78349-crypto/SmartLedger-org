import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DeepLinkDiagnostics {
  DeepLinkDiagnostics._();

  static const _prefKey = 'deep_link_last_event_v1';

  static Future<void> record({
    required String uri,
    required bool parsed,
    String? actionSummary,
    String? failureReason,
    String? source,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = DeepLinkDiagnosticsEntry(
      uri: uri,
      receivedAt: DateTime.now(),
      parsed: parsed,
      actionSummary: actionSummary,
      failureReason: failureReason,
      source: source,
    );
    await prefs.setString(_prefKey, jsonEncode(entry.toJson()));
  }

  static Future<DeepLinkDiagnosticsEntry?> getLast() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return DeepLinkDiagnosticsEntry.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}

class DeepLinkDiagnosticsEntry {
  final String uri;
  final DateTime receivedAt;
  final bool parsed;
  final String? actionSummary;
  final String? failureReason;
  final String? source;

  const DeepLinkDiagnosticsEntry({
    required this.uri,
    required this.receivedAt,
    required this.parsed,
    this.actionSummary,
    this.failureReason,
    this.source,
  });

  Map<String, dynamic> toJson() => {
    'uri': uri,
    'receivedAt': receivedAt.toIso8601String(),
    'parsed': parsed,
    if (actionSummary != null) 'actionSummary': actionSummary,
    if (failureReason != null) 'failureReason': failureReason,
    if (source != null) 'source': source,
  };

  static DeepLinkDiagnosticsEntry fromJson(Map<String, dynamic> json) {
    return DeepLinkDiagnosticsEntry(
      uri: (json['uri'] ?? '') as String,
      receivedAt:
          DateTime.tryParse((json['receivedAt'] ?? '') as String) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      parsed: (json['parsed'] ?? false) as bool,
      actionSummary: json['actionSummary'] as String?,
      failureReason: json['failureReason'] as String?,
      source: json['source'] as String?,
    );
  }
}
