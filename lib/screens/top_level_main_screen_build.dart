part of 'top_level_main_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension TopLevelMainScreenBuild on _TopLevelMainScreenState {
  Widget _buildMain(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(IconCatalog.adminPanelSettings, color: Colors.amber),
              SizedBox(width: 8),
              Text('ROOT 관리자(전체 계정)'),
            ],
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final dashboard = TopLevelStatsUtils.buildDashboardContext();
    final currencyFormat = NumberFormats.currency;

    void doSearch(String query) {
      final allTx = dashboard.allTransactions;
      setState(() {
        if (isSearchFocused) {
          searchResults = List<Transaction>.from(allTx);
          return;
        }
        if (query.isEmpty) {
          searchResults = [];
          return;
        }

        final q = query;
        searchResults = allTx.where((t) {
          final memo = t.memo;
          final method = t.paymentMethod;
          return t.description.contains(q) ||
              (memo.isNotEmpty && memo.contains(q)) ||
              (method.isNotEmpty && method.contains(q)) ||
              t.amount.toString().contains(q);
        }).toList();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(IconCatalog.adminPanelSettings, color: Colors.amber),
            SizedBox(width: 8),
            Text('ROOT 관리자(전체 계정)'),
          ],
        ),
        actions: const [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RootSummaryCard(
              data: dashboard.summaryData,
              onViewDetail: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        TopLevelStatsDetailScreen(dashboard: dashboard),
                  ),
                );
              },
            ),
            if (dashboard.orphanAccountNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '삭제된 계정에서 남아있는 거래·고정비 데이터가 발견되었습니다: '
                      '${dashboard.orphanAccountNames.join(', ')}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    decoration: const InputDecoration(
                      labelText: '거래 검색 (설명, 메모, 금액, 지불수단)',
                      prefixIcon: Icon(IconCatalog.search, size: 26),
                    ),
                    onChanged: (value) {
                      _rootSearchDebouncer.run(() {
                        if (!mounted) return;
                        doSearch(value);
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(IconCatalog.clear),
                  onPressed: () {
                    searchController.clear();
                    doSearch('');
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (isSearchFocused) {
                    return RootTransactionList(
                      transactions: searchResults,
                      transactionAccountMap: dashboard.transactionAccountMap,
                      isFocused: true,
                      currencyFormat: currencyFormat,
                    );
                  }
                  if (searchController.text.isEmpty) {
                    return const Center(child: Text('검색어를 입력하세요.'));
                  }
                  return RootTransactionList(
                    transactions: searchResults,
                    transactionAccountMap: dashboard.transactionAccountMap,
                    isFocused: false,
                    currencyFormat: currencyFormat,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [_buildAccountControlButtons()],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountControlButtons() {
    final accounts = AccountService().accounts;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final result = await navigator.push<String>(
              MaterialPageRoute(
                builder: (context) => const AccountCreateScreen(),
              ),
            );
            if (result != null && result.isNotEmpty) {
              await UserPrefService.setLastAccountName(result);
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => AccountMainScreen(accountName: result),
                ),
                (route) => false,
              );
            }
          },
          child: const Text('새 계정'),
        ),
        ElevatedButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final accs = accounts.map((a) => a.name).toList();
            final selected = await navigator.push<String>(
              MaterialPageRoute(
                builder: (context) => AccountSelectScreen(accounts: accs),
              ),
            );
            if (selected != null && selected.isNotEmpty) {
              if (!mounted) return;
              await BackupPasswordBootstrapper.ensureBackupPasswordConfiguredOnEntry(
                context,
              );
              await BackupService().autoBackupIfNeeded(selected);
              if (!mounted) return;
              await UserPrefService.setLastAccountName(selected);
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) =>
                      AccountMainScreen(accountName: selected),
                ),
                (route) => false,
              );
            }
          },
          child: const Text('선택'),
        ),
        ElevatedButton(
          onPressed: _showMonthEndDialogForAllAccounts,
          child: const Text('월말 정산'),
        ),
        // Account management button removed to avoid UI obstruction.
      ],
    );
  }
}
