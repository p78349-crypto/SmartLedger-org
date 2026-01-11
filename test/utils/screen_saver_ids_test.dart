import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/screen_saver_ids.dart';

void main() {
  group('ScreenSaverIds', () {
    test('defines stable shortcut id and allowed page index', () {
      expect(ScreenSaverIds.shortcutIconId, 'shortcut_in_app_screen_saver');
      expect(ScreenSaverIds.shortcutAllowedMainPageIndex, 0);
    });
  });
}
