import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/refund_utils.dart';

void main() {
  group('RefundUtils', () {
    test('exposes stable icon and color', () {
      expect(RefundUtils.icon, IconCatalog.refund);
      expect(RefundUtils.color, Colors.green);
    });
  });
}
