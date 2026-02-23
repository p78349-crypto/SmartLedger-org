import 'package:flutter/material.dart';

/// 음성 명령 실행 결과 목록 생성
List<Widget> buildVoiceResultDetails(
  Map<String, dynamic> result,
) {
  final results =
      result['results'] as Map<String, dynamic>? ?? {};
  final widgets = <Widget>[];

  if (results.containsKey('record')) {
    widgets.add(
      buildVoiceResultItem(
        icon: Icons.save,
        title: '가계부 입력',
        subtitle: results['record'] == true
            ? '✅ 저장 완료'
            : '❌ 저장 실패',
        color: Colors.blue,
      ),
    );
  }

  if (results.containsKey('shopping')) {
    widgets.add(
      buildVoiceResultItem(
        icon: Icons.shopping_cart,
        title: '쇼핑앱 실행',
        subtitle: results['shopping'] == true
            ? '✅ 앱 실행됨'
            : '❌ 실행 실패',
        color: Colors.orange,
      ),
    );
  }

  if (results.containsKey('delivery')) {
    widgets.add(
      buildVoiceResultItem(
        icon: Icons.delivery_dining,
        title: '배달앱 실행',
        subtitle: results['delivery'] == true
            ? '✅ 앱 실행됨'
            : '❌ 실행 실패',
        color: Colors.purple,
      ),
    );
  }

  if (results.containsKey('navigation')) {
    widgets.add(
      buildVoiceResultItem(
        icon: Icons.map,
        title: '지도앱 실행',
        subtitle: results['navigation'] == true
            ? '✅ 앱 실행됨'
            : '❌ 실행 실패',
        color: Colors.green,
      ),
    );
  }

  return widgets;
}

/// 개별 결과 항목 위젯
Widget buildVoiceResultItem({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
