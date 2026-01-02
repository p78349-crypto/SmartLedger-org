// PC 키보드 단축키 구현 참고 코드 (모바일 빌드 시 미사용)
// 사용법:
// 1. transaction_add_screen.dart build()에서 Form을 Shortcuts/Actions로 래핑
// 2. 아래 예제 코드 참고

// ============================================================================
// PC용 키보드 단축키 구현 예제
// ============================================================================

// PC 키보드 단축키 적용 방법:
// ```dart
// @override
// Widget build(BuildContext context) {
//   final theme = Theme.of(context);
//
//   return Shortcuts(
//     shortcuts: {
//       LogicalKeySet(LogicalKeyboardKey.enter):
//           const _SubmitTransactionIntent(),
//       LogicalKeySet(LogicalKeyboardKey.numpadEnter):
//           const _SubmitTransactionIntent(),
//       LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.enter):
//           const _NextTransactionIntent(),
//       LogicalKeySet(
//         LogicalKeyboardKey.shift,
//         LogicalKeyboardKey.numpadEnter,
//       ): const _NextTransactionIntent(),
//     },
//     child: Actions(
//       actions: {
//         _SubmitTransactionIntent: CallbackAction<_SubmitTransactionIntent>(
//           onInvoke: (_) {
//             unawaited(_saveTransaction());
//             return null;
//           },
//         ),
//         _NextTransactionIntent: CallbackAction<_NextTransactionIntent>(
//           onInvoke: (_) {
//             unawaited(_saveAndContinue());
//             return null;
//           },
//         ),
//       },
//       child: Form(
//         key: _formKey,
//         child: ListView(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).padding.bottom + 16,
//           ),
//           children: [
//             _buildInputModeSelector(),
//             const SizedBox(height: 12),
//             DropdownButtonFormField<TransactionType>(
//               // ... 나머지 코드
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }
// ```

// Intent 클래스 정의 (transaction_add_screen.dart 파일 끝에 추가):
// ```dart
// class _SubmitTransactionIntent extends Intent {
//   const _SubmitTransactionIntent();
// }
//
// class _NextTransactionIntent extends Intent {
//   const _NextTransactionIntent();
// }
// ```

// ============================================================================
// 키보드 단축키 정의
// ============================================================================

// PC 키보드 단축키 명령:
// 1. Enter / NumpadEnter → 거래 저장 (_saveTransaction)
// 2. Shift+Enter / Shift+NumpadEnter → 저장 후 계속 입력

// ============================================================================
// 구현 팁
// ============================================================================

// 1. Focus 관리: FocusScope로 필드 포커스 관리
// 2. 모달: Shortcuts는 모달을 건너뛸 수 있음(showDialog 주의)
// 3. 테스트: WidgetTester에서 sendKeyEvent 활용

// ============================================================================
// 마이그레이션 체크리스트 (PC 버전 개발 시)
// ============================================================================

/*
- [ ] Shortcuts/Actions 래퍼 추가
- [ ] _SubmitTransactionIntent 클래스 추가
- [ ] _NextTransactionIntent 클래스 추가
- [ ] build() 메서드 수정
- [ ] 버튼 Tooltip 업데이트 (예: "저장 (Enter)")
- [ ] Focus 관리 개선 (필요시)
- [ ] 단축키 테스트 작성
- [ ] 문서 업데이트
*/

