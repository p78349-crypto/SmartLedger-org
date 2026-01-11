import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';

void main() {
  group('IconCatalog', () {
    test('addCircle is correct icon', () {
      expect(IconCatalog.addCircle, Icons.add_circle);
    });

    test('receiptLongOutlined is correct icon', () {
      expect(IconCatalog.receiptLongOutlined, Icons.receipt_long_outlined);
    });

    test('dashboard is correct icon', () {
      expect(IconCatalog.dashboard, Icons.dashboard);
    });

    test('trendingUp is correct icon', () {
      expect(IconCatalog.trendingUp, Icons.trending_up);
    });

    test('settings is correct icon', () {
      expect(IconCatalog.settings, Icons.settings);
    });

    test('attachMoney is correct icon', () {
      expect(IconCatalog.attachMoney, Icons.attach_money);
    });

    test('savings is correct icon', () {
      expect(IconCatalog.savings, Icons.savings);
    });

    test('restaurant is correct icon', () {
      expect(IconCatalog.restaurant, Icons.restaurant);
    });

    test('shoppingCart is correct icon', () {
      expect(IconCatalog.shoppingCart, Icons.shopping_cart);
    });

    test('categoryOutlined is correct icon', () {
      expect(IconCatalog.categoryOutlined, Icons.category_outlined);
    });

    test('errorOutline is correct icon', () {
      expect(IconCatalog.errorOutline, Icons.error_outline);
    });

    test('checkCircle is correct icon', () {
      expect(IconCatalog.checkCircle, Icons.check_circle);
    });

    test('edit is correct icon', () {
      expect(IconCatalog.edit, Icons.edit);
    });

    test('delete is correct icon', () {
      expect(IconCatalog.delete, Icons.delete);
    });

    test('lock and lockOpen icons are correct', () {
      expect(IconCatalog.lock, Icons.lock);
      expect(IconCatalog.lockOpen, Icons.lock_open);
    });

    test('payment icons are correct', () {
      expect(IconCatalog.payment, Icons.payment);
      expect(IconCatalog.payments, Icons.payments);
      expect(IconCatalog.paymentsOutlined, Icons.payments_outlined);
    });

    test('chart icons are correct', () {
      expect(IconCatalog.barChart, Icons.bar_chart);
      expect(IconCatalog.showChart, Icons.show_chart);
      expect(IconCatalog.pieChart, Icons.pie_chart);
    });

    test('navigation icons are correct', () {
      expect(IconCatalog.chevronRight, Icons.chevron_right);
      expect(IconCatalog.chevronLeft, Icons.chevron_left);
      expect(IconCatalog.arrowBack, Icons.arrow_back);
      expect(IconCatalog.arrowForward, Icons.arrow_forward);
    });

    test('weather icons are correct', () {
      expect(IconCatalog.wbSunny, Icons.wb_sunny);
      expect(IconCatalog.wbCloudy, Icons.wb_cloudy);
      expect(IconCatalog.acUnit, Icons.ac_unit);
    });

    test('calendar icons are correct', () {
      expect(IconCatalog.calendarToday, Icons.calendar_today);
      expect(IconCatalog.dateRange, Icons.date_range);
      expect(IconCatalog.schedule, Icons.schedule);
    });
  });
}
