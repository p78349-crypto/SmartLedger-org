import 'package:flutter/material.dart';

/// 간단한 유틸 사용 예시 화면.
class UtilsExampleScreen extends StatelessWidget {
  const UtilsExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Utils 사용 예시')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('샘플 항목 1'),
            subtitle: Text('유틸리티 기능을 여기에 추가하세요.'),
          ),
          ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('샘플 항목 2'),
            subtitle: Text('테스트 전용 자리 표시자'),
          ),
        ],
      ),
    );
  }
}
