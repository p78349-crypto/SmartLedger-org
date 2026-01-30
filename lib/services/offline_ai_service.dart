import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalyzeResult {
  final String intent;
  final Map<String, dynamic> entities;

  AnalyzeResult({required this.intent, required this.entities});

  factory AnalyzeResult.fromJson(Map<String, dynamic> j) {
    return AnalyzeResult(intent: j['intent'] as String, entities: Map<String, dynamic>.from(j['entities'] ?? {}));
  }
}

class OfflineAiService {
  // Use localhost or 10.0.2.2 for Android emulator
  final String baseUrl;
  OfflineAiService({this.baseUrl = 'http://127.0.0.1:8000'});

  Future<AnalyzeResult> analyzeText(String text) async {
    final uri = Uri.parse('$baseUrl/analyze');
    final res = await http.post(uri, body: jsonEncode({'text': text}), headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('AI analyze failed: ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return AnalyzeResult.fromJson(j);
  }
}
