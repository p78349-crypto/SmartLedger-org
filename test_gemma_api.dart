// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Gemma API 간단 테스트 스크립트
void main() async {
  print('=== Gemma API 테스트 시작 ===\n');

  const apiUrl = 'http://localhost:5000';

  // 1. 헬스 체크
  print('1️⃣ 서버 헬스 체크...');
  try {
    final healthResponse = await http
        .get(Uri.parse('$apiUrl/health'))
        .timeout(const Duration(seconds: 5));

    if (healthResponse.statusCode == 200) {
      final health = jsonDecode(healthResponse.body);
      print('✅ 서버 정상 동작');
      print('   - 모델 로드: ${health['model_loaded']}');
      print('   - 디바이스: ${health['device']}');
      print('   - 시간: ${health['timestamp']}\n');
    } else {
      print('❌ 서버 응답 이상: ${healthResponse.statusCode}\n');
      return;
    }
  } catch (e) {
    print('❌ 서버 연결 실패: $e\n');
    print('💡 C:\\Users\\plain\\GemmaFineTuning\\budget_api_server.py 실행 확인 필요\n');
    return;
  }

  // 2. 샘플 영수증 테스트
  print('2️⃣ 샘플 영수증 추출 테스트...');
  print('⏳ 추론 중 (CPU 모드에서 30-120초 소요 가능)...\n');

  const sampleReceipt = '''이마트 서초점
2026-01-27 14:32

바나나        2,980원 x 2 = 5,960원
우유 1L      3,200원 x 1 = 3,200원
계란 30구    6,500원 x 1 = 6,500원

합계: 15,660원
카드결제
''';

  try {
    final startTime = DateTime.now();
    print('   DirectML GPU 가속 모드로 추론 시작...');
    print('   예상 시간: 10-30초\n');

    final extractResponse = await http
        .post(
          Uri.parse('$apiUrl/extract'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'receipt_text': sampleReceipt}),
        )
        .timeout(const Duration(seconds: 60));

    final duration = DateTime.now().difference(startTime);

    if (extractResponse.statusCode == 200) {
      final result = jsonDecode(extractResponse.body);

      if (result['success'] == true) {
        print('✅ 추출 성공! (${duration.inSeconds}초 소요)\n');

        final data = result['data'];
        print('📄 추출된 정보:');
        print('   - 상점: ${data['store_name']}');
        print('   - 날짜: ${data['date']}');
        print('   - 품목 수: ${data['items']?.length ?? 0}개');

        if (data['items'] != null) {
          print('\n   품목 목록:');
          for (final item in data['items']) {
            print('     • ${item['name']}: ${item['quantity']}개 x ${item['unit_price']}원 = ${item['total_price']}원');
          }
        }

        print('\n   총 금액: ${data['total_amount']}원');

        // 원본 응답 (디버깅용)
        if (result['raw_response'] != null) {
          print('\n🤖 모델 원본 응답 (일부):');
          print('   ${result['raw_response'].toString().substring(0, 200)}...\n');
        }
      } else {
        print('❌ 추출 실패: ${result['error']}\n');
      }
    } else {
      print('❌ API 오류: ${extractResponse.statusCode}');
      print('   응답: ${extractResponse.body}\n');
    }
  } catch (e) {
    print('❌ 추출 실패: $e\n');
  }

  print('=== 테스트 완료 ===');
}
