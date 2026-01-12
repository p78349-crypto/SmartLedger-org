import 'package:flutter/material.dart';
import 'utils.dart';

const _vSpace8 = SizedBox(height: 8);

Widget buildValidatorsExamples(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '필수 검증: '
        '${Validators.required("테스트", fieldName: "이름") ?? "✓ 유효"}',
      ),
      Text(
        '필수 검증 (빈값): '
        '${Validators.required("", fieldName: "이름") ?? "✓ 유효"}',
      ),
      Text('양수 검증: ${Validators.positiveNumber("1000") ?? "✓ 유효"}'),
      Text('양수 검증 (0): ${Validators.positiveNumber("0") ?? "✓ 유효"}'),
      Text('계정명 검증: ${Validators.accountName("내 계정") ?? "✓ 유효"}'),
      Text(
        '이메일 검증: ${Validators.email("test@example.com") ?? "✓ 유효"}',
      ),
      _vSpace8,
      ElevatedButton(
        onPressed: () {
          final formKey = GlobalKey<FormState>();
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Form Validator 예시'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: '금액'),
                        validator: (value) {
                          return Validators.positiveNumber(
                            value,
                            fieldName: '금액',
                          );
                        },
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
                      final isValid = formKey.currentState?.validate() ?? false;
                      if (isValid) {
                        Navigator.pop(context);
                        SnackbarUtils.showSuccess(context, '유효성 검사 통과!');
                      }
                    },
                    child: const Text('검증'),
                  ),
                ],
              );
            },
          );
        },
        child: const Text('Form Validator 테스트'),
      ),
    ],
  );
}

Widget buildDialogUtilsExamples(BuildContext context) {
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
      _vSpace8,
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
      _vSpace8,
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
      _vSpace8,
      ElevatedButton(
        onPressed: () {
          DialogUtils.showErrorDialog(context, message: '오류가 발생했습니다!');
        },
        child: const Text('에러 다이얼로그'),
      ),
      _vSpace8,
      ElevatedButton(
        onPressed: () async {
          final input = await DialogUtils.showTextInputDialog(
            context,
            title: '이름 입력',
            hint: '이름을 입력하세요',
            validator: (value) {
              return Validators.required(value, fieldName: '이름');
            },
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

Widget buildSnackbarUtilsExamples(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ElevatedButton(
        onPressed: () => SnackbarUtils.show(context, '기본 스낵바입니다'),
        child: const Text('기본 스낵바'),
      ),
      _vSpace8,
      ElevatedButton(
        onPressed: () => SnackbarUtils.showSuccess(context, '성공했습니다!'),
        child: const Text('성공 스낵바'),
      ),
      _vSpace8,
      ElevatedButton(
        onPressed: () => SnackbarUtils.showError(context, '오류가 발생했습니다!'),
        child: const Text('에러 스낵바'),
      ),
      _vSpace8,
      ElevatedButton(
        onPressed: () => SnackbarUtils.showWarning(context, '주의가 필요합니다!'),
        child: const Text('경고 스낵바'),
      ),
      _vSpace8,
      ElevatedButton(
        onPressed: () => SnackbarUtils.showInfo(context, '정보를 확인하세요'),
        child: const Text('정보 스낵바'),
      ),
      _vSpace8,
      ElevatedButton(
        onPressed: () {
          SnackbarUtils.showWithUndo(
            context,
            '항목이 삭제되었습니다',
            onUndo: () {
              SnackbarUtils.show(context, '삭제가 취소되었습니다');
            },
          );
        },
        child: const Text('실행 취소 가능한 스낵바'),
      ),
    ],
  );
}

Widget buildColorUtilsExamples(BuildContext context) {
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
      _vSpace8,
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
      _vSpace8,
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
      _vSpace8,
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
      _vSpace8,
      Text('16진수 변환: ${ColorUtils.toHex(Colors.blue)}'),
      _vSpace8,
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
