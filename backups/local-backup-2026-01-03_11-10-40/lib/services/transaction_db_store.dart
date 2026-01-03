import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:smart_ledger/database/app_database.dart';
import 'package:smart_ledger/database/database_provider.dart';
import 'package:smart_ledger/models/transaction.dart' as model;
import 'package:smart_ledger/models/weather_snapshot.dart';

class TransactionDbStore {
  TransactionDbStore();

  final _db = DatabaseProvider.instance.database;

  Future<int?> ensureAccountId(String accountName) async {
    final trimmed = accountName.trim();
    if (trimmed.isEmpty) return null;

    final existing = await _db.getAccountByName(trimmed);
    if (existing != null) return existing.id;

    await _db.insertAccount(DbAccountsCompanion.insert(name: trimmed));

    final after = await _db.getAccountByName(trimmed);
    return after?.id;
  }

  Future<void> upsertTransaction(
    String accountName,
    model.Transaction tx,
  ) async {
    final accountId = await ensureAccountId(accountName);
    if (accountId == null) return;

    final weatherJson = tx.weather == null
        ? null
        : jsonEncode(tx.weather!.toJson());

    final companion = DbTransactionsCompanion.insert(
      id: tx.id,
      accountId: accountId,
      type: tx.type.name,
      description: Value(tx.description),
      amount: tx.amount,
      cardChargedAmount: Value(tx.cardChargedAmount),
      date: tx.date,
      quantity: Value(tx.quantity),
      unitPrice: Value(tx.unitPrice),
      paymentMethod: Value(tx.paymentMethod),
      memo: Value(tx.memo),
      store: Value(tx.store?.trim().isEmpty ?? true ? null : tx.store!.trim()),
      mainCategory: Value(tx.mainCategory),
      subCategory: Value(tx.subCategory),
      savingsAllocation: Value(tx.savingsAllocation?.name),
      isRefund: Value(tx.isRefund ? 1 : 0),
      originalTransactionId: Value(tx.originalTransactionId),
      weatherJson: Value(weatherJson),
      benefitJson: Value(
        tx.benefitJson?.trim().isEmpty ?? true ? null : tx.benefitJson!.trim(),
      ),
    );

    await _db.into(_db.dbTransactions).insertOnConflictUpdate(companion);
  }

  Future<void> upsertMany(
    String accountName,
    List<model.Transaction> transactions,
  ) async {
    if (transactions.isEmpty) return;
    final accountId = await ensureAccountId(accountName);
    if (accountId == null) return;

    DbTransactionsCompanion mapTx(model.Transaction tx) {
      final weatherJson = tx.weather == null
          ? null
          : jsonEncode(tx.weather!.toJson());
      final trimmedStore = tx.store?.trim() ?? '';
      return DbTransactionsCompanion.insert(
        id: tx.id,
        accountId: accountId,
        type: tx.type.name,
        description: Value(tx.description),
        amount: tx.amount,
        cardChargedAmount: Value(tx.cardChargedAmount),
        date: tx.date,
        quantity: Value(tx.quantity),
        unitPrice: Value(tx.unitPrice),
        paymentMethod: Value(tx.paymentMethod),
        memo: Value(tx.memo),
        store: Value(trimmedStore.isEmpty ? null : trimmedStore),
        mainCategory: Value(tx.mainCategory),
        subCategory: Value(tx.subCategory),
        savingsAllocation: Value(tx.savingsAllocation?.name),
        isRefund: Value(tx.isRefund ? 1 : 0),
        originalTransactionId: Value(tx.originalTransactionId),
        weatherJson: Value(weatherJson),
        benefitJson: Value(
          tx.benefitJson?.trim().isEmpty ?? true
              ? null
              : tx.benefitJson!.trim(),
        ),
      );
    }

    final companions = transactions.map(mapTx).toList();
    await _db.batch((b) {
      b.insertAllOnConflictUpdate(_db.dbTransactions, companions);
    });
  }

  Future<int> countForAccount(String accountName) async {
    final accountId = await ensureAccountId(accountName);
    if (accountId == null) return 0;

    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM db_transactions WHERE account_id = ?',
          variables: <Variable<Object>>[Variable<int>(accountId)],
        )
        .getSingle();
    return row.read<int>('c');
  }

  Future<void> deleteTransaction(
    String accountName,
    String transactionId,
  ) async {
    final accountId = await ensureAccountId(accountName);
    if (accountId == null) return;

    await (_db.delete(_db.dbTransactions)..where(
          (tbl) =>
              tbl.accountId.equals(accountId) & tbl.id.equals(transactionId),
        ))
        .go();
  }

  Future<List<model.Transaction>> getAllTransactionsForAccount(
    String accountName,
  ) async {
    final accountId = await ensureAccountId(accountName);
    if (accountId == null) return const <model.Transaction>[];

    final rows =
        await (_db.select(_db.dbTransactions)
              ..where((tbl) => tbl.accountId.equals(accountId))
              ..orderBy([(tbl) => OrderingTerm(expression: tbl.date)]))
            .get();

    return rows.map(_mapRowToModel).toList();
  }

  model.Transaction _mapRowToModel(DbTransaction row) {
    final parsedType = _parseType(row.type);
    final allocation = _parseSavingsAllocation(row.savingsAllocation);

    WeatherSnapshot? weather;
    final rawWeather = row.weatherJson;
    if (rawWeather != null && rawWeather.trim().isNotEmpty) {
      try {
        final map = jsonDecode(rawWeather);
        if (map is Map) {
          weather = WeatherSnapshot.fromJson(Map<String, dynamic>.from(map));
        }
      } catch (_) {
        // Ignore malformed weather cache.
      }
    }

    return model.Transaction(
      id: row.id,
      type: parsedType,
      description: row.description,
      amount: row.amount,
      cardChargedAmount: row.cardChargedAmount,
      date: row.date,
      quantity: row.quantity,
      unitPrice: row.unitPrice,
      weather: weather,
      paymentMethod: row.paymentMethod,
      memo: row.memo,
      store: row.store,
      benefitJson: row.benefitJson,
      savingsAllocation: allocation,
      isRefund: row.isRefund != 0,
      originalTransactionId: row.originalTransactionId,
      mainCategory: row.mainCategory,
      subCategory: row.subCategory,
    );
  }

  model.TransactionType _parseType(String raw) {
    final normalized = raw.trim().toLowerCase();
    for (final type in model.TransactionType.values) {
      if (type.name == normalized) return type;
    }
    return model.TransactionType.expense;
  }

  model.SavingsAllocation? _parseSavingsAllocation(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'assetincrease':
      case 'asset_increase':
      case 'asset':
      case 'assetincreaseoption':
        return model.SavingsAllocation.assetIncrease;
      case 'expense':
        return model.SavingsAllocation.expense;
    }
    return null;
  }
}
