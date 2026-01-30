import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Gemma 2 2B Budget Specialist API 서비스
/// 
/// 로컬에서 실행 중인 Gemma API 서버와 통신하여
/// 영수증 텍스트를 구조화된 데이터로 변환합니다.
class GemmaApiService {
  static const String _apiUrl = 'http://localhost:5000';
  static const Duration _healthCheckTimeout = Duration(seconds: 5);
  static const Duration _extractTimeout = Duration(seconds: 60);

  static final GemmaApiService _instance = GemmaApiService._internal();
  factory GemmaApiService() => _instance;
  GemmaApiService._internal();

  bool _isServerHealthy = false;
  DateTime? _lastHealthCheck;

  /// 서버 상태 확인
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_apiUrl/health'),
          )
          .timeout(_healthCheckTimeout);

      _isServerHealthy = response.statusCode == 200;
      _lastHealthCheck = DateTime.now();

      if (_isServerHealthy) {
        debugPrint('✅ Gemma API Server: healthy');
      } else {
        debugPrint('⚠️ Gemma API Server: unhealthy (${response.statusCode})');
      }

      return _isServerHealthy;
    } catch (e) {
      _isServerHealthy = false;
      _lastHealthCheck = DateTime.now();
      debugPrint('❌ Gemma API Server: not reachable ($e)');
      return false;
    }
  }

  /// 영수증 정보 추출
  /// 
  /// [receiptText]: OCR로 추출된 영수증 텍스트
  /// 
  /// Returns: 구조화된 영수증 데이터 또는 null
  Future<ReceiptExtractionResult?> extractReceiptInfo(
      String receiptText) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_apiUrl/extract'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'receipt_text': receiptText}),
          )
          .timeout(_extractTimeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));

        if (result['success'] == true && result['data'] != null) {
          debugPrint('✅ Gemma extraction successful');
          return ReceiptExtractionResult.fromJson(result['data']);
        } else {
          debugPrint('⚠️ Gemma extraction failed: ${result['error']}');
          debugPrint('Raw response: ${result['raw_response']}');
          return null;
        }
      } else {
        debugPrint('❌ Gemma API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Gemma extraction error: $e');
      return null;
    }
  }

  /// 샘플 영수증 테스트
  Future<Map<String, dynamic>?> testSampleReceipt() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_apiUrl/test'),
          )
          .timeout(_extractTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint('❌ Gemma test error: $e');
      return null;
    }
  }

  /// 서버 실행 여부 (캐시된 상태)
  bool get isServerHealthy => _isServerHealthy;

  /// 마지막 헬스 체크 시간
  DateTime? get lastHealthCheck => _lastHealthCheck;

  /// 헬스 체크가 필요한지 확인 (5분마다)
  bool get needsHealthCheck {
    if (_lastHealthCheck == null) return true;
    final elapsed = DateTime.now().difference(_lastHealthCheck!);
    return elapsed.inMinutes >= 5;
  }
}

/// 영수증 추출 결과
class ReceiptExtractionResult {
  final String? storeName;
  final DateTime? date;
  final List<ReceiptItem> items;
  final double? totalAmount;

  ReceiptExtractionResult({
    this.storeName,
    this.date,
    required this.items,
    this.totalAmount,
  });

  factory ReceiptExtractionResult.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final items = itemsJson
        .map((item) => ReceiptItem.fromJson(item as Map<String, dynamic>))
        .toList();

    DateTime? date;
    if (json['date'] != null) {
      try {
        date = DateTime.parse(json['date'] as String);
      } catch (e) {
        debugPrint('Failed to parse date: ${json['date']}');
      }
    }

    return ReceiptExtractionResult(
      storeName: json['store_name'] as String?,
      date: date,
      items: items,
      totalAmount: _parseDouble(json['total_amount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'store_name': storeName,
        'date': date?.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'total_amount': totalAmount,
      };

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// 영수증 항목
class ReceiptItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] as String? ?? '',
      quantity: _parseInt(json['quantity']) ?? 1,
      unitPrice: _parseDouble(json['unit_price']) ?? 0.0,
      totalPrice: _parseDouble(json['total_price']) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
      };

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
