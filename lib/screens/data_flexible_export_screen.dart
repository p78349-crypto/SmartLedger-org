import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/asset.dart';
import '../services/transaction_service.dart';
import '../services/asset_service.dart';
import '../services/account_service.dart';
import '../services/data_export_service.dart';
import '../utils/snackbar_utils.dart';
import '../utils/icon_catalog.dart';

class DataFlexibleExportScreen extends StatefulWidget {
  final String accountName;
  const DataFlexibleExportScreen({super.key, required this.accountName});

  @override
  State<DataFlexibleExportScreen> createState() =>
      _DataFlexibleExportScreenState();
}

class _DataFlexibleExportScreenState extends State<DataFlexibleExportScreen> {
  bool _includeExpenses = true;
  bool _includeIncome = true;
  bool _includeAssets = true;

  DateTimeRange? _dateRange;
  String _selectedAccount = '';
  List<String> _allAccounts = [];

  // Column selection flags
  bool _colType = true;
  bool _colDate = true;
  bool _colCategory = true;
  bool _colTitle = true;
  bool _colAmount = true;
  bool _colPayment = true;
  bool _colMemo = true;

  bool _excludePersonalInfo = false; // 타인 제공용 (개인정보 제외)
  bool _useExcel = true; // Excel vs CSV

  void _applyPreset(String preset) {
    setState(() {
      switch (preset) {
        case 'full':
          _colType = _colDate = _colCategory = _colTitle = _colAmount =
              _colPayment = _colMemo = true;
          _excludePersonalInfo = false;
          break;
        case 'consult': // 전문가 상담용 (프라이버시 중시)
          _colType = _colDate = _colCategory = _colAmount = true;
          _colTitle = _colPayment = _colMemo = true;
          _excludePersonalInfo = true;
          break;
        case 'tax': // 세무 증빙용
          _colType = _colDate = _colCategory = _colAmount = _colPayment = true;
          _colTitle = true;
          _colMemo = false;
          _excludePersonalInfo = false;
          break;
        case 'share': // 커뮤니티 공유용 (통계 중심)
          _colType = _colCategory = _colAmount = true;
          _colDate = _colTitle = _colPayment = _colMemo = false;
          _excludePersonalInfo = true;
          break;
      }
    });
  }

  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.accountName;
    _allAccounts = AccountService().accounts.map((a) => a.name).toList();
    if (!_allAccounts.contains('ROOT')) {
      _allAccounts.add('ROOT');
    }

    // Default range: current month
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: '내보낼 기간 선택',
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _doExport() async {
    if (_exporting) return;
    setState(() => _exporting = true);

    try {
      // 1. Collect Data
      final List<Transaction> allTx = _selectedAccount == 'ROOT'
          ? TransactionService().getAllTransactions()
          : TransactionService().getTransactions(_selectedAccount);

      final List<Asset> allAssets = _includeAssets
          ? (_selectedAccount == 'ROOT'
                ? _allAccounts
                      .where((n) => n != 'ROOT')
                      .expand((n) => AssetService().getAssets(n))
                      .toList()
                : AssetService().getAssets(_selectedAccount))
          : [];

      // 2. Build Column List
      final List<String> columns = [];
      if (_colType) columns.add('구분');
      if (_colDate) columns.add('날짜');
      if (_colCategory) columns.add('카테고리');
      if (_colTitle) columns.add('항목/매장명');
      if (_colAmount) columns.add('금액');
      if (_colPayment) columns.add('결제수단/기관');
      if (_colMemo) columns.add('메모');

      // 3. Configure Options
      final options = ExportOptions(
        includeExpenses: _includeExpenses,
        includeIncome: _includeIncome,
        includeAssets: _includeAssets,
        excludePersonalInfo: _excludePersonalInfo,
        selectedColumns: columns,
        accountName: _selectedAccount,
        startDate: _dateRange!.start,
        endDate: _dateRange!.end,
      );

      // 4. Invoke Service
      final exportService = DataExportService();
      final File? resultFile;

      if (_useExcel) {
        resultFile = await exportService.exportToExcel(
          options: options,
          transactions: allTx,
          assets: allAssets,
        );
      } else {
        resultFile = await exportService.exportToCsv(
          options: options,
          transactions: allTx,
          assets: allAssets,
        );
      }

      if (!mounted) return;
      if (resultFile != null) {
        SnackbarUtils.showSuccess(
          context,
          '${_useExcel ? '엑셀' : 'CSV'} 파일 저장 완료: ${resultFile.path}',
        );
      } else {
        SnackbarUtils.showInfo(context, '데이터 추출에 실패했거나 대상이 없습니다');
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, '내보내기 실패: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('유연한 데이터 추출'),
        actions: [
          if (_exporting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(IconCatalog.download),
              onPressed: _doExport,
              tooltip: 'CSV 내보내기',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(theme, '용도별 빠른 설정 (Presets)'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip('전체 백업', 'full', Icons.backup),
                  _buildPresetChip('전문가 상담', 'consult', Icons.psychology),
                  _buildPresetChip('세무 증빙', 'tax', Icons.receipt_long),
                  _buildPresetChip('통계 공유', 'share', Icons.share),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(theme, '1. 대상 계정 선택'),
            Card(
              child: ListTile(
                leading: const Icon(IconCatalog.accountBalance),
                title: Text(
                  _selectedAccount == 'ROOT'
                      ? '전체 계정 (ROOT)'
                      : _selectedAccount,
                ),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: _showAccountPicker,
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(theme, '2. 추출 기간 설정'),
            Card(
              child: ListTile(
                leading: const Icon(IconCatalog.calendarToday),
                title: Text(
                  '${DateFormat('yyyy-MM-dd').format(_dateRange!.start)} ~ ${DateFormat('yyyy-MM-dd').format(_dateRange!.end)}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: _selectDateRange,
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(theme, '3. 내보낼 항목 선택'),
            Card(
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('지출 내역'),
                    subtitle: const Text('식비, 교통비 등 소비 데이터'),
                    value: _includeExpenses,
                    onChanged: (v) =>
                        setState(() => _includeExpenses = v ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('수입 내역'),
                    subtitle: const Text('급여, 보너스 등 수입 데이터'),
                    value: _includeIncome,
                    onChanged: (v) =>
                        setState(() => _includeIncome = v ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('자산 현황'),
                    subtitle: const Text('현금, 예금, 주식 등 자산 데이터'),
                    value: _includeAssets,
                    onChanged: (v) =>
                        setState(() => _includeAssets = v ?? false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(theme, '4. 포함할 열(Column) 선택'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  children: [
                    _buildFilterChip('구분', _colType, (v) => _colType = v),
                    _buildFilterChip('날짜', _colDate, (v) => _colDate = v),
                    _buildFilterChip(
                      '카테고리',
                      _colCategory,
                      (v) => _colCategory = v,
                    ),
                    _buildFilterChip('항목명', _colTitle, (v) => _colTitle = v),
                    _buildFilterChip('금액', _colAmount, (v) => _colAmount = v),
                    _buildFilterChip(
                      '지불/보관기관',
                      _colPayment,
                      (v) => _colPayment = v,
                    ),
                    _buildFilterChip('메모', _colMemo, (v) => _colMemo = v),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(theme, '5. 개인정보 보호 옵션'),
            Card(
              color: _excludePersonalInfo
                  ? scheme.secondaryContainer.withValues(alpha: 0.3)
                  : null,
              child: SwitchListTile(
                title: const Text('타인 제공용 (개인정보 마스킹)'),
                subtitle: const Text('장소명, 기관명, 메모 등을 별표(*) 처리합니다'),
                secondary: Icon(
                  _excludePersonalInfo
                      ? Icons.privacy_tip
                      : Icons.privacy_tip_outlined,
                  color: _excludePersonalInfo ? scheme.primary : null,
                ),
                value: _excludePersonalInfo,
                onChanged: (v) => setState(() => _excludePersonalInfo = v),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(theme, '6. 저장 형식 선택'),
            Card(
              child: RadioGroup<bool>(
                groupValue: _useExcel,
                onChanged: (v) => setState(() => _useExcel = v ?? true),
                child: const Column(
                  children: [
                    RadioListTile<bool>(
                      title: Text('Excel (.xlsx)'),
                      subtitle: Text('멀티 시트 지원 (요약 리포트 포함)'),
                      value: true,
                    ),
                    RadioListTile<bool>(
                      title: Text('CSV (.csv)'),
                      subtitle: Text('범용 텍스트 형식'),
                      value: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: _exporting ? null : _doExport,
              icon: Icon(_useExcel ? Icons.table_chart : IconCatalog.download),
              label: Text(_useExcel ? 'Excel 파일로 추출하기' : 'CSV 파일로 추출하기'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '※ 추출된 파일은 기기의 "다운로드" 폴더에 저장됩니다.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String preset, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        onPressed: () => _applyPreset(preset),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool selected,
    ValueChanged<bool> onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: onSelected,
        showCheckmark: false,
      ),
    );
  }

  void _showAccountPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: _allAccounts
            .map(
              (name) => ListTile(
                title: Text(name),
                onTap: () {
                  setState(() => _selectedAccount = name);
                  Navigator.pop(context);
                },
                selected: _selectedAccount == name,
              ),
            )
            .toList(),
      ),
    );
  }
}
