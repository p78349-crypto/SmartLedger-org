import 'package:flutter/material.dart';
import 'utils.dart';

/// Utils 사용 예시 파일
/// 이 파일은 참고용이며, 실제 프로젝트에서는 삭제하거나 주석 처리하세요.
class UtilsExampleScreen extends StatelessWidget {
  const UtilsExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Utils 사용 예시')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('1. DateFormatter 사용'),
          _buildDateFormatterExamples(),
          const Divider(),
          _buildSection('2. CurrencyFormatter 사용'),
          _buildCurrencyFormatterExamples(),
          const Divider(),
          _buildSection('3. Validators 사용'),
          _buildValidatorsExamples(context),
          const Divider(),
          _buildSection('4. DialogUtils 사용'),
          _buildDialogUtilsExamples(context),
          const Divider(),
          _buildSection('5. SnackbarUtils 사용'),
          _buildSnackbarUtilsExamples(context),
          const Divider(),
          _buildSection('6. ColorUtils 사용'),
          _buildColorUtilsExamples(context),
          const Divider(),
          _buildSection('7. Constants 사용'),
          _buildConstantsExamples(),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDateFormatterExamples() {
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

  Widget _buildCurrencyFormatterExamples() {
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

  Widget _buildValidatorsExamples(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('필수 검증: ${Validators.required("테스트", fieldName: "이름") ?? "✓ 유효"}'),
        Text(
          '필수 검증 (빈값): ${Validators.required("", fieldName: "이름") ?? "✓ 유효"}',
        ),
        Text('양수 검증: ${Validators.positiveNumber("1000") ?? "✓ 유효"}'),
        Text('양수 검증 (0): ${Validators.positiveNumber("0") ?? "✓ 유효"}'),
        Text('계정명 검증: ${Validators.accountName("내 계정") ?? "✓ 유효"}'),
        Text('이메일 검증: ${Validators.email("test@example.com") ?? "✓ 유효"}'),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            // Form 예시
            final formKey = GlobalKey<FormState>();
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Form Validator 예시'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: '금액'),
                        validator: (value) =>
                            Validators.positiveNumber(value, fieldName: '금액'),
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: '계정명'),
                        validator: Validators.accountName,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('닫기'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        Navigator.pop(context);
                        SnackbarUtils.showSuccess(context, '유효성 검사 통과!');
                      }
                    },
                    child: const Text('검증'),
                  ),
                ],
              ),
            );
          },
          child: const Text('Form Validator 테스트'),
        ),
      ],
    );
  }

  Widget _buildDialogUtilsExamples(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () async {
            final confirmed = await DialogUtils.showConfirmDialog(
              context,
              title: '확인',
              message: '계속하시겠습니까?',
            );
            if (context.mounted) {
              SnackbarUtils.show(context, confirmed ? '확인됨' : '취소됨');
            }
          },
          child: const Text('확인 다이얼로그'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            final confirmed = await DialogUtils.showDeleteConfirmDialog(
              context,
              itemName: '테스트 항목',
            );
            if (context.mounted) {
              SnackbarUtils.show(context, confirmed ? '삭제됨' : '취소됨');
            }
          },
          child: const Text('삭제 확인 다이얼로그'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            DialogUtils.showInfoDialog(
              context,
              title: '정보',
              message: '이것은 정보 다이얼로그입니다.',
            );
          },
          child: const Text('정보 다이얼로그'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            DialogUtils.showErrorDialog(context, message: '오류가 발생했습니다!');
          },
          child: const Text('에러 다이얼로그'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            final input = await DialogUtils.showTextInputDialog(
              context,
              title: '이름 입력',
              hint: '이름을 입력하세요',
              validator: (value) => Validators.required(value, fieldName: '이름'),
            );
            if (context.mounted && input != null) {
              SnackbarUtils.show(context, '입력값: $input');
            }
          },
          child: const Text('텍스트 입력 다이얼로그'),
        ),
      ],
    );
  }

  Widget _buildSnackbarUtilsExamples(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () => SnackbarUtils.show(context, '기본 스낵바입니다'),
          child: const Text('기본 스낵바'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => SnackbarUtils.showSuccess(context, '성공했습니다!'),
          child: const Text('성공 스낵바'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => SnackbarUtils.showError(context, '오류가 발생했습니다!'),
          child: const Text('에러 스낵바'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => SnackbarUtils.showWarning(context, '주의가 필요합니다!'),
          child: const Text('경고 스낵바'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => SnackbarUtils.showInfo(context, '정보를 확인하세요'),
          child: const Text('정보 스낵바'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            SnackbarUtils.showWithUndo(
              context,
              '항목이 삭제되었습니다',
              onUndo: () => SnackbarUtils.show(context, '삭제가 취소되었습니다'),
            );
          },
          child: const Text('실행 취소 가능한 스낵바'),
        ),
      ],
    );
  }

  Widget _buildColorUtilsExamples(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('양수 색상: '),
            Container(
              width: 50,
              height: 20,
              color: ColorUtils.getAmountColor(1000, context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('음수 색상: '),
            Container(
              width: 50,
              height: 20,
              color: ColorUtils.getAmountColor(-1000, context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('진행률 30% 색상: '),
            Container(
              width: 50,
              height: 20,
              color: ColorUtils.getProgressColor(30, context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('진행률 100% 색상: '),
            Container(
              width: 50,
              height: 20,
              color: ColorUtils.getProgressColor(100, context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('16진수 변환: ${ColorUtils.toHex(Colors.blue)}'),
        const SizedBox(height: 8),
        const Text('차트 색상 팔레트:'),
        Row(
          children: ColorUtils.generateChartColors(5).map((color) {
            return Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 4),
              color: color,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConstantsExamples() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('자동 백업 주기: ${AppConstants.autoBackupIntervalDays}일'),
        Text('최대 즐겨찾기 수: ${AppConstants.maxFavoritesCount}개'),
        Text('기본 통화: ${AppConstants.defaultCurrency}'),
        Text('기본 계정명: ${AppConstants.defaultAccountName}'),
        SizedBox(height: 8),
        Text('에러 메시지 예시:'),
        Text('- ${ErrorMessages.networkError}'),
        Text('- ${ErrorMessages.accountNotFound}'),
        SizedBox(height: 8),
        Text('성공 메시지 예시:'),
        Text('- ${SuccessMessages.saved}'),
        Text('- ${SuccessMessages.backupCompleted}'),
      ],
    );
  }
}
