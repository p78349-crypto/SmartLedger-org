import 'package:flutter/material.dart';
import 'utils.dart';

export 'utils_example_interactive_builders.dart';

const _vSpace8 = SizedBox(height: 8);

Widget buildUtilsExampleSection(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );
}

Widget buildDateFormatterExamples() {
  final now = DateTime.now();
  final monthStartStr = DateFormatter.formatDate(
    DateFormatter.getMonthStart(now),
  );
  final monthEndStr = DateFormatter.formatDate(
    DateFormatter.getMonthEnd(now),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('현재 날짜: ${DateFormatter.formatDate(now)}'),
      Text('현재 날짜+시간: ${DateFormatter.formatDateTime(now)}'),
      Text('월 라벨: ${DateFormatter.formatMonthLabel(now)}'),
      Text(
        '파일명용: ${DateFormatter.formatForFileName(now, includeTime: true)}',
      ),
      Text('월 시작일: $monthStartStr'),
      Text('월 마지막일: $monthEndStr'),
    ],
  );
}

Widget buildCurrencyFormatterExamples() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('금액 포맷: ${CurrencyFormatter.format(1234567)}'),
      Text('부호 포함: ${CurrencyFormatter.formatSigned(50000)}'),
      Text('부호 포함 (음수): ${CurrencyFormatter.formatSigned(-30000)}'),
      Text('지출 포맷: ${CurrencyFormatter.formatOutflow(15000)}'),
      Text('수입 포맷: ${CurrencyFormatter.formatInflow(100000)}'),
      Text('간단한 포맷: ${CurrencyFormatter.formatCompact(1234567)}'),
      Text('퍼센트: ${CurrencyFormatter.formatPercent(75.5)}'),
      Text('비율: ${CurrencyFormatter.formatRatio(3, 4)}'),
    ],
  );
}

Widget buildConstantsExamples() {
  return const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('자동 백업 주기: ${AppConstants.autoBackupIntervalDays}일'),
      Text('최대 즐겨찾기 수: ${AppConstants.maxFavoritesCount}개'),
      Text('기본 통화: ${AppConstants.defaultCurrency}'),
      Text('기본 계정명: ${AppConstants.defaultAccountName}'),
      _vSpace8,
      Text('에러 메시지 예시:'),
      Text('- ${ErrorMessages.networkError}'),
      Text('- ${ErrorMessages.accountNotFound}'),
      _vSpace8,
      Text('성공 메시지 예시:'),
      Text('- ${SuccessMessages.saved}'),
      Text('- ${SuccessMessages.backupCompleted}'),
    ],
  );
}
