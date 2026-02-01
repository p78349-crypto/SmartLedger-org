import 'package:url_launcher/url_launcher.dart';
import 'package:smart_ledger/services/aicore_gemini_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/models/transaction.dart';

/// 타사 앱 제어 + 가계부 통합 서비스
///
/// Gemini Nano로 자연어 이해 → 다른 앱 제어
/// "쿠팡에서 사과 검색" → 쿠팡 앱 자동 실행
class SmartAppController {
  final AICoreGeminiService _aicore = AICoreGeminiService();

  /// 자연어 명령 처리
  ///
  /// 예시:
  /// - "편의점 우유 3000원 기록하고 쿠팡에서 우유 검색"
  /// - "배민에서 치킨 주문"
  /// - "카카오맵으로 강남역 가는 길 찾아줘"
  Future<Map<String, dynamic>> processCommand(
    String userCommand,
    String accountName,
  ) async {
    try {
      // 1. Gemini Nano로 명령 분석
      final parsed = await _parseCommand(userCommand);

      if (parsed.containsKey('error')) {
        return parsed;
      }

      final results = <String, dynamic>{};
      final tasks = parsed['tasks'] as List? ?? [parsed];

      // 2. 각 작업 실행
      for (final task in tasks) {
        final taskMap = task as Map<String, dynamic>;
        final type = taskMap['type'] as String?;

        switch (type) {
          case 'record':
            results['record'] = await _recordTransaction(taskMap, accountName);
            break;
          case 'search_shopping':
            results['shopping'] = await _openShoppingApp(taskMap);
            break;
          case 'food_delivery':
            results['delivery'] = await _openDeliveryApp(taskMap);
            break;
          case 'navigation':
            results['navigation'] = await _openMapApp(taskMap);
            break;
          case 'finance':
            results['finance'] = await _openFinanceApp(taskMap);
            break;
        }
      }

      return {'success': true, 'results': results};
    } catch (e) {
      return {'error': '명령 처리 실패: $e'};
    }
  }

  /// Gemini Nano로 명령 파싱
  Future<Map<String, dynamic>> _parseCommand(String command) async {
    final prompt =
        '''
다음 사용자 명령을 JSON으로 변환하세요:

"$command"

JSON 형식:
{
  "tasks": [
    {
      "type": "record|search_shopping|food_delivery|navigation|finance",
      "data": { /* 작업별 데이터 */ }
    }
  ]
}

작업 타입:
- record: 가계부 기록 (store, item, amount)
- search_shopping: 쇼핑앱 검색 (app: "coupang"|"gmarket", query)
- food_delivery: 배달앱 (app: "baemin"|"yogiyo", food)
- navigation: 지도앱 (destination)
- finance: 금융앱 (app: "toss"|"kakao", action)
''';

    final result = await _aicore.parseReceiptText(prompt);
    return result;
  }

  /// 가계부 기록
  Future<bool> _recordTransaction(
    Map<String, dynamic> data,
    String accountName,
  ) async {
    try {
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.expense,
        description: data['store'] ?? '기타',
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.now(),
        memo: '음성 입력: ${data['item'] ?? ""}',
      );

      await TransactionService().addTransaction(accountName, transaction);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 쇼핑 앱 실행
  Future<bool> _openShoppingApp(Map<String, dynamic> data) async {
    final app = data['app'] as String? ?? 'coupang';
    final query = data['query'] as String? ?? '';

    final appUrls = {
      'coupang': 'coupang://search?q=$query',
      'gmarket': 'gmarket://search?keyword=$query',
      'elevenst': 'elevenst://search?keyword=$query',
    };

    final url = appUrls[app];
    if (url == null) return false;

    return await _launchAppOrWeb(
      url,
      'https://www.coupang.com/np/search?q=$query',
    );
  }

  /// 배달 앱 실행
  Future<bool> _openDeliveryApp(Map<String, dynamic> data) async {
    final app = data['app'] as String? ?? 'baemin';
    final food = data['food'] as String? ?? '';

    final appUrls = {
      'baemin': 'baeminapp://search?query=$food',
      'yogiyo': 'yogiyo://search?keyword=$food',
      'coupangeats': 'coupangeats://search?q=$food',
    };

    final url = appUrls[app];
    if (url == null) return false;

    return await _launchAppOrWeb(url, 'https://www.baemin.com/search?q=$food');
  }

  /// 지도 앱 실행
  Future<bool> _openMapApp(Map<String, dynamic> data) async {
    final destination = data['destination'] as String? ?? '';

    // 카카오맵 우선, 실패 시 네이버 지도, 최종 구글 맵
    final urls = [
      'kakaomap://search?q=$destination',
      'nmap://search?query=$destination',
      'https://www.google.com/maps/search/?api=1&query=$destination',
    ];

    for (final url in urls) {
      if (await _launchUrl(url)) {
        return true;
      }
    }

    return false;
  }

  /// 금융 앱 실행
  Future<bool> _openFinanceApp(Map<String, dynamic> data) async {
    final app = data['app'] as String? ?? 'toss';
    final action = data['action'] as String? ?? 'home';

    final appUrls = {
      'toss': 'supertoss://$action',
      'kakao': 'kakaopay://$action',
      'payco': 'payco://$action',
    };

    final url = appUrls[app];
    if (url == null) return false;

    return await _launchUrl(url);
  }

  /// URL 실행 (앱 실패 시 웹 폴백)
  Future<bool> _launchAppOrWeb(String appUrl, String webUrl) async {
    // 1차: 앱 URL 시도
    if (await _launchUrl(appUrl)) {
      return true;
    }

    // 2차: 웹 브라우저 폴백
    return await _launchUrl(webUrl);
  }

  /// URL 실행
  Future<bool> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
