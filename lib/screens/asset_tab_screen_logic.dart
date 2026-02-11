part of 'asset_tab_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension AssetTabScreenLogic on _AssetTabScreenState {
  Future<void> _loadAssets({bool showSpinner = false}) async {
    if (showSpinner && mounted) {
      setState(() => _loading = true);
    }
    await AssetService().loadAssets();
    final loaded = AssetService().getAssets(widget.accountName);
    if (!mounted) return;
    setState(() {
      _assets = loaded;
      _loading = false;
    });
  }

  Future<void> _openSimpleInput() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssetSimpleInputScreen(accountName: widget.accountName),
      ),
    );
    await _loadAssets(showSpinner: true);
  }

  Future<void> _openDetailInput() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssetInputScreen(accountName: widget.accountName),
      ),
    );
    await _loadAssets(showSpinner: true);
  }

  Future<void> _exportAssets() async {
    try {
      await AssetService().loadAssets();
      final assets = AssetService().getAssets(widget.accountName);
      if (assets.isEmpty) {
        _showMessage('내보낼 자산 데이터가 없습니다.');
        return;
      }

      final headers = ['자산명', '금액'];
      final rows = <List<dynamic>>[
        headers,
        ...assets.map((a) => [a.name, a.amount]),
      ];

      final excel = Excel.createExcel();
      final sheet = excel['Assets'];
      for (final row in rows) {
        sheet.appendRow(
          row
              .map<CellValue>((value) => TextCellValue(value.toString()))
              .toList(),
        );
      }

      // 열 너비를 좁게 설정하여 사각형 모양으로 표시
      sheet.setColumnWidth(0, 12); // 자산명 열
      sheet.setColumnWidth(1, 12); // 금액 열

      final csvData = const ListToCsvConverter().convert(rows);
      final dir = await getDownloadsDirectory();
      if (dir == null) {
        throw Exception('다운로드 폴더를 찾을 수 없습니다.');
      }
      final now = DateTime.now();
      final stamp = _formatExportStamp(now);
      final excelPath = '${dir.path}/assets_$stamp.xlsx';
      final csvPath = '${dir.path}/assets_$stamp.csv';
      final excelBytes = excel.encode();
      if (excelBytes == null) {
        throw Exception('엑셀 파일 생성 실패');
      }
      await File(excelPath).writeAsBytes(excelBytes);
      await File(csvPath).writeAsString(csvData);

      _showMessage('엑셀/CSV 내보내기 완료\n엑셀: $excelPath\nCSV: $csvPath');
    } catch (e) {
      _showMessage('내보내기 실패: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    if (message.contains('실패')) {
      SnackbarUtils.showError(context, message);
    } else {
      SnackbarUtils.showSuccess(context, message);
    }
  }

  void _toggleExpensesView() => _toggleSubview(_AssetSubview.expenses);
  void _toggleSavingsView() => _toggleSubview(_AssetSubview.savings);

  void _toggleSubview(_AssetSubview target) {
    if (!mounted) return;
    setState(() {
      _activeSubview = _activeSubview == target ? _AssetSubview.none : target;
    });
  }

  Widget _buildSavingsView(ThemeData theme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _toggleSavingsView,
                icon: const Icon(IconCatalog.close),
                label: const Text('예금 닫기'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '예금 데이터 출력 기능이 일시 중단되었습니다.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseView(ThemeData theme) {
    final expenses = _assets.where((asset) => asset.amount < 0).toList()
      ..sort((a, b) => a.amount.compareTo(b.amount));
    final expenseTotal = expenses.fold<double>(
      0,
      (sum, asset) => sum + asset.amount,
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _toggleExpensesView,
                icon: const Icon(IconCatalog.close),
                label: const Text('통계 > 지출 닫기'),
              ),
            ),
            const SizedBox(height: 12),
            if (expenses.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '지출 내역',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('기록된 지출이 없습니다.', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              )
            else ...[
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '지출 합계',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(expenseTotal),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...expenses.map(
                (asset) => Card(
                  child: ListTile(
                    leading: const Icon(
                      IconCatalog.paymentsOutlined,
                      color: Colors.redAccent,
                    ),
                    title: Text(asset.name),
                    trailing: Text(
                      CurrencyFormatter.format(asset.amount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
