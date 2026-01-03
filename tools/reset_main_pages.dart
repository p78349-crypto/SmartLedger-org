import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';

Future<void> main(List<String> args) async {
  final prefs = await SharedPreferences.getInstance();
  await AccountService().loadAccounts();
  final accounts = AccountService().accounts.map((a) => a.name).toList();
  if (accounts.isEmpty) {
    stdout.writeln('No accounts found.');
    return;
  }

  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final backupFile = File('tools/main_page_prefs_backup_$timestamp.json');
  final Map<String, Map<String, Object?>> backup = {};

  for (final acc in accounts) {
    final keys = prefs.getKeys().where((k) {
      return k.startsWith('account_${acc}_') ||
          k.contains('_page_') ||
          k.contains('main_page');
    }).toList();

    final Map<String, Object?> data = {};
    for (final k in keys) {
      data[k] = prefs.get(k);
    }

    backup[acc] = data;
  }

  await backupFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(backup),
  );
  stdout.writeln('Backup written to ${backupFile.path}');

  // Reset each account's main pages to a reasonable default page count.
  // Avoid importing Flutter-dependent catalog code in this standalone tool.
  const pageCount = 15;
  for (final acc in accounts) {
    stdout.writeln(
      'Resetting main pages for account: $acc (pageCount=$pageCount)',
    );
    await UserPrefService.resetAccountMainPages(
      accountName: acc,
      pageCount: pageCount,
    );
  }

  stdout.writeln('Done.');
}
