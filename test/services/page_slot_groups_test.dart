import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/page1_bottom_quick_icons.dart';

void main() {
  test('set and get page slot groups persists and normalizes', () async {
    SharedPreferences.setMockInitialValues({});
    const account = 'acct_test';
    const page = 2;

    final groups = List<List<String>>.filled(
      Page1BottomQuickIcons.slotCount,
      <String>[],
    );
    groups[0] = ['a', 'b', 'c'];
    groups[3] = ['z'];

    await UserPrefService.setPageSlotGroups(
      accountName: account,
      pageIndex: page,
      groups: groups,
    );

    final loaded = await UserPrefService.getPageSlotGroups(
      accountName: account,
      pageIndex: page,
    );

    expect(loaded.length, Page1BottomQuickIcons.slotCount);
    expect(loaded[0], ['a', 'b', 'c']);
    expect(loaded[3], ['z']);
    for (int i = 0; i < Page1BottomQuickIcons.slotCount; i++) {
      if (i == 0 || i == 3) continue;
      expect(loaded[i], []);
    }
  });

  test('trims extra saved entries and fills missing slots', () async {
    SharedPreferences.setMockInitialValues({
      // directly set smaller list
      'acct_test_page_1_slot_groups': ['x,y', 'z'],
    });

    final loaded = await UserPrefService.getPageSlotGroups(
      accountName: 'acct_test',
      pageIndex: 1,
      slotCount: 4,
    );
    expect(loaded.length, 4);
    expect(loaded[0], ['x', 'y']);
    expect(loaded[1], ['z']);
    expect(loaded[2], []);
    expect(loaded[3], []);
  });
}
