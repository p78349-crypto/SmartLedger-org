import 'package:flutter/foundation.dart';

/// Page 1 slot configuration - simplified to 24 slots only.
@immutable
class Page1BottomQuickIcons {
  const Page1BottomQuickIcons._();

  static const int pageIndex = 0;
  static const int slotCount = 24;

  static List<String> normalizeSlots(List<String> slots) {
    final next = List<String>.from(slots);

    if (next.length < slotCount) {
      next.addAll(List<String>.filled(slotCount - next.length, ''));
    } else if (next.length > slotCount) {
      next.removeRange(slotCount, next.length);
    }

    return next;
  }
}

