import 'package:flutter/material.dart';

/// 결제수단/메모 등 최근 입력값 칩(히스토리) 위젯 생성 및 재활용 유틸
///
/// 예시: 결제수단 입력란 아래에 최근 결제수단 칩을 표시할 때 사용
///   RecentInputUtils.buildHistoryChips(
///     items: paymentList,
///     onSelected: (value) { ... },
///     label: '최근 결제수단',
///   )
class RecentInputUtils {
  /// 지정된 TextEditingController의 텍스트를 모두 선택합니다.
  static void selectAllText(TextEditingController controller) {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  /// 최근 입력값 칩 리스트를 생성합니다.
  ///
  /// [items]: 최근 입력값 리스트 (최신순)
  /// [onSelected]: 칩 클릭 시 실행할 콜백 (선택된 값 전달)
  /// [label]: 칩 위에 표시할 제목 (예: '최근 메모', '최근 결제수단')
  /// [maxChips]: 최대 칩 개수 (기본 10)
  static Widget buildHistoryChips({
    required List<String> items,
    required void Function(String) onSelected,
    String? label,
    int maxChips = 10,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items.take(maxChips))
          ActionChip(
            label: Text(item, overflow: TextOverflow.ellipsis),
            onPressed: () => onSelected(item),
          ),
      ],
    );
    if (label == null) return chips;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
        ),
        const SizedBox(height: 4),
        chips,
      ],
    );
  }
}
