import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/page1_bottom_quick_icons.dart';

void main() {
  group('Page1BottomQuickIcons', () {
    test('normalizeSlots pads to 24 slots with empty strings', () {
      final normalized = Page1BottomQuickIcons.normalizeSlots(['a', 'b']);
      expect(normalized.length, Page1BottomQuickIcons.slotCount);
      expect(normalized.take(2).toList(), ['a', 'b']);
      expect(normalized.skip(2).every((e) => e.isEmpty), isTrue);
    });

    test('normalizeSlots truncates to 24 slots', () {
      final input = List<String>.generate(30, (i) => 'v$i');
      final normalized = Page1BottomQuickIcons.normalizeSlots(input);
      expect(normalized.length, Page1BottomQuickIcons.slotCount);
      expect(normalized.last, 'v23');
    });

    test('normalizeSlots returns a new list (does not mutate input)', () {
      final input = ['x'];
      final normalized = Page1BottomQuickIcons.normalizeSlots(input);
      expect(identical(input, normalized), isFalse);
      expect(input, ['x']);
    });
  });
}
