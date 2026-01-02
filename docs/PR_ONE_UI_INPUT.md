PR draft: "One UI input fields prototype and transaction screen updates"

Summary
-------
This PR introduces a One UI style input field prototype and applies it to the `TransactionAddScreen` inputs.

Changes
-------
- `lib/widgets/one_ui_input_field.dart` (new) — One UI input field wrapper around `TextFormField` with label, hint, suffix/prefix icons, focus handling and light animation.
- `lib/screens/transaction_add_screen.dart` — replaced key `TextFormField` usages with `OneUiInputField` (description, unit price, qty, amount, payment, memo, store).
- `docs/ONE_UI_FORM_TOKENS.md` — design tokens for One UI inputs.
- `test/widgets/one_ui_input_field_test.dart` — basic test verifying rendering of label/hint.
- `CHANGELOG.md` entry added.

Testing
-------
- `flutter test` (unit/widget tests) — pass locally.
- Visual check: run app and open transaction add screen to verify styles and interactions.

Designer checklist
------------------
- [ ] Verify iconography and sizes
- [ ] Confirm field heights, padding, and corner radius
- [ ] Approve focus/hover states and colors
- [ ] Accessibility check: labels/semantics and contrast

Notes
-----
- This is a visual/UX change. The behavior and validation logic were kept unchanged. Additional visual polish and golden tests will follow after design approval.
