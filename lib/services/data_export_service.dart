import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../models/asset.dart';

/// Configuration for data export
class ExportOptions {
  final bool includeExpenses;
  final bool includeIncome;
  final bool includeAssets;
  final bool excludePersonalInfo;
  final List<String>
  selectedColumns; // ['구분', '날짜', '카테고리', '항목/매장명', '금액', '결제수단/기관', '메모']
  final String accountName;
  final DateTime startDate;
  final DateTime endDate;

  const ExportOptions({
    required this.includeExpenses,
    required this.includeIncome,
    required this.includeAssets,
    required this.excludePersonalInfo,
    required this.selectedColumns,
    required this.accountName,
    required this.startDate,
    required this.endDate,
  });
}

/// Service to handle multi-format data exports with privacy masking
class DataExportService {
  static final DataExportService _instance = DataExportService._internal();
  factory DataExportService() => _instance;
  DataExportService._internal();

  /// Generates an Excel file with multiple sheets and a summary report
  Future<File?> exportToExcel({
    required ExportOptions options,
    required List<Transaction> transactions,
    required List<Asset> assets,
  }) async {
    final excel = Excel.createExcel();
    final header = options.selectedColumns;

    final List<List<dynamic>> totalRows = [header];
    final List<List<dynamic>> expenseRows = [header];
    final List<List<dynamic>> incomeRows = [header];
    final List<List<dynamic>> assetRows = [header];

    // 1. Process Transactions
    final filteredTx = transactions.where((tx) {
      final start = options.startDate.subtract(const Duration(seconds: 1));
      final end = options.endDate.add(const Duration(days: 1));
      final inDate = tx.date.isAfter(start) && tx.date.isBefore(end);
      if (!inDate) return false;
      if (tx.type == TransactionType.expense && options.includeExpenses) {
        return true;
      }
      if (tx.type == TransactionType.income && options.includeIncome) {
        return true;
      }
      return false;
    }).toList();

    filteredTx.sort((a, b) => a.date.compareTo(b.date));

    for (final tx in filteredTx) {
      final row = _buildTransactionRow(tx, options);
      totalRows.add(row);
      if (tx.type == TransactionType.expense) expenseRows.add(row);
      if (tx.type == TransactionType.income) incomeRows.add(row);
    }

    // 2. Process Assets
    if (options.includeAssets) {
      for (final asset in assets) {
        final row = _buildAssetRow(asset, options);
        totalRows.add(row);
        assetRows.add(row);
      }
    }

    // 3. Create Sheets
    _createSummarySheet(excel, options, expenseRows, incomeRows);
    _populateSheet(excel, '통합 데이터', totalRows);
    _populateSheet(excel, '지출 내역', expenseRows);
    _populateSheet(excel, '수입 내역', incomeRows);
    _populateSheet(excel, '자산 현황', assetRows);

    excel.delete('Sheet1');

    return _saveFile(
      bytes: excel.save(),
      extension: 'xlsx',
      accountName: options.accountName,
    );
  }

  /// Generates a CSV file
  Future<File?> exportToCsv({
    required ExportOptions options,
    required List<Transaction> transactions,
    required List<Asset> assets,
  }) async {
    final List<List<dynamic>> totalRows = [options.selectedColumns];

    // Transaction logic (duplicated for now or extract common filtering)
    final filteredTx = transactions.where((tx) {
      final start = options.startDate.subtract(const Duration(seconds: 1));
      final end = options.endDate.add(const Duration(days: 1));
      final inDate = tx.date.isAfter(start) && tx.date.isBefore(end);
      if (!inDate) return false;
      if (tx.type == TransactionType.expense && options.includeExpenses) {
        return true;
      }
      if (tx.type == TransactionType.income && options.includeIncome) {
        return true;
      }
      return false;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    for (final tx in filteredTx) {
      totalRows.add(_buildTransactionRow(tx, options));
    }

    if (options.includeAssets) {
      for (final asset in assets) {
        totalRows.add(_buildAssetRow(asset, options));
      }
    }

    final csv = const ListToCsvConverter().convert(totalRows);
    return _saveFile(
      content: csv,
      extension: 'csv',
      accountName: options.accountName,
    );
  }

  // --- Private Helpers ---

  List<dynamic> _buildTransactionRow(Transaction tx, ExportOptions options) {
    final row = <dynamic>[];
    for (final col in options.selectedColumns) {
      switch (col) {
        case '구분':
          row.add(tx.type == TransactionType.expense ? '지출' : '수입');
          break;
        case '날짜':
          row.add(DateFormat('yyyy-MM-dd').format(tx.date));
          break;
        case '카테고리':
          row.add(tx.mainCategory);
          break;
        case '항목/매장명':
          row.add(_mask(tx.description, options.excludePersonalInfo));
          break;
        case '금액':
          row.add(tx.amount);
          break;
        case '결제수단/기관':
          row.add(_mask(tx.paymentMethod, options.excludePersonalInfo));
          break;
        case '메모':
          row.add(_mask(tx.memo, options.excludePersonalInfo, isMemo: true));
          break;
      }
    }
    return row;
  }

  List<dynamic> _buildAssetRow(Asset asset, ExportOptions options) {
    final row = <dynamic>[];
    for (final col in options.selectedColumns) {
      switch (col) {
        case '구분':
          row.add('자산');
          break;
        case '날짜':
          row.add(DateFormat('yyyy-MM-dd').format(asset.date));
          break;
        case '카테고리':
          row.add(asset.category.toString().split('.').last);
          break;
        case '항목/매장명':
          row.add(_mask(asset.name, options.excludePersonalInfo));
          break;
        case '금액':
          row.add(asset.amount);
          break;
        case '결제수단/기관':
          row.add(_mask(asset.institution ?? '', options.excludePersonalInfo));
          break;
        case '메모':
          row.add(options.excludePersonalInfo ? '[비공개]' : asset.memo);
          break;
      }
    }
    return row;
  }

  String _mask(String val, bool active, {bool isMemo = false}) {
    if (!active) return val;
    if (val.isEmpty) return '';
    if (isMemo) return '[비공개]';
    if (val.length <= 1) return '*';
    return '${val[0]}${'*' * (val.length - 1)}';
  }

  void _populateSheet(Excel excel, String sheetName, List<List<dynamic>> rows) {
    if (rows.length <= 1) return;
    final sheet = excel[sheetName];
    for (final row in rows) {
      sheet.appendRow(row.map((e) => TextCellValue(e.toString())).toList());
    }
  }

  void _createSummarySheet(
    Excel excel,
    ExportOptions options,
    List<List<dynamic>> exp,
    List<List<dynamic>> inc,
  ) {
    final summarySheet = excel['요약 리포트'];
    final amountIdx = options.selectedColumns.indexOf('금액');
    double totalExp = 0;
    double totalInc = 0;

    if (amountIdx != -1) {
      for (final r in exp.skip(1)) {
        totalExp += double.tryParse(r[amountIdx].toString()) ?? 0;
      }
      for (final r in inc.skip(1)) {
        totalInc += double.tryParse(r[amountIdx].toString()) ?? 0;
      }
    }

    final df = DateFormat('yyyy-MM-dd');
    summarySheet.appendRow([
      TextCellValue('📊 SmartLedger 요약 리포트'),
      TextCellValue(''),
    ]);
    summarySheet.appendRow([
      TextCellValue('기간'),
      TextCellValue(
        '${df.format(options.startDate)} ~ ${df.format(options.endDate)}',
      ),
    ]);
    summarySheet.appendRow([TextCellValue(''), TextCellValue('')]);
    summarySheet.appendRow([TextCellValue('항목'), TextCellValue('금액')]);
    summarySheet.appendRow([
      TextCellValue('총 수입 (+)'),
      TextCellValue(totalInc.toStringAsFixed(0)),
    ]);
    summarySheet.appendRow([
      TextCellValue('총 지출 (-)'),
      TextCellValue(totalExp.toStringAsFixed(0)),
    ]);
    summarySheet.appendRow([
      TextCellValue('순수익 (잔액)'),
      TextCellValue((totalInc - totalExp).toStringAsFixed(0)),
    ]);
  }

  Future<File?> _saveFile({
    List<int>? bytes,
    String? content,
    required String extension,
    required String accountName,
  }) async {
    final dir = await getDownloadsDirectory();
    if (dir == null) return null;
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = 'SmartLedger_${accountName}_$timestamp.$extension';
    final file = File('${dir.path}/$fileName');

    if (bytes != null) {
      await file.writeAsBytes(bytes);
    } else if (content != null) {
      await file.writeAsString(content);
    }
    return file;
  }
}
