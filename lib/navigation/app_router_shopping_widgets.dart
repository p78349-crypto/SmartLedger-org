part of 'app_router.dart';

/// 소비재 재고 리디렉트 화면
/// 계정이 하나이면 바로 이동, 여러 개면 선택 화면 표시
class _ConsumableInventoryRedirectScreen extends StatefulWidget {
  const _ConsumableInventoryRedirectScreen();

  @override
  State<_ConsumableInventoryRedirectScreen> createState() =>
      _ConsumableInventoryRedirectScreenState();
}

class _ConsumableInventoryRedirectScreenState
    extends State<_ConsumableInventoryRedirectScreen> {
  bool _loading = true;
  String? _errorMessage;
  String? _selectedAccount;
  List<String> _accounts = const [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accountService = AccountService();
      await accountService.loadAccounts();
      final accounts = accountService.accounts.map((e) => e.name).toList();
      final lastAccount = await UserPrefService.getLastAccountName();

      String? selected;
      if (lastAccount != null && accounts.contains(lastAccount)) {
        selected = lastAccount;
      } else if (accounts.length == 1) {
        selected = accounts.first;
      }

      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _selectedAccount = selected;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_selectedAccount != null) {
      return ConsumableInventoryScreen(accountName: _selectedAccount!);
    }

    if (_accounts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('식료품/생활용품 관리')),
        body: Center(
          child: Text(
            _errorMessage ?? '계정이 없습니다. 먼저 계정을 추가하세요.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('계정 선택')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _accounts.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final name = _accounts[index];
          return ListTile(
            title: Text(name),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ConsumableInventoryScreen(
                    accountName: name,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 식재료 검색 입력 화면 (요리 필요 재료 검색)
class _IngredientSearchInputScreen extends StatefulWidget {
  const _IngredientSearchInputScreen();

  @override
  State<_IngredientSearchInputScreen> createState() =>
      _IngredientSearchInputScreenState();
}

class _IngredientSearchInputScreenState
    extends State<_IngredientSearchInputScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('검색어를 입력하세요.')));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IngredientSearchListScreen(searchQuery: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('요리 필요 재료 검색'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '요리 이름을 입력하세요',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '예: 닭고기, 돼지고기, 생선 등',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '요리 이름 입력',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: _search,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _search(_controller.text),
              icon: const Icon(Icons.search),
              label: const Text('검색'),
            ),
          ],
        ),
      ),
    );
  }
}
