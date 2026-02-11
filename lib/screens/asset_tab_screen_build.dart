part of 'asset_tab_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension AssetTabScreenBuild on _AssetTabScreenState {
  Widget _buildMain(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 보안이 활성화되어 있고 인증되지 않았으면 인증 화면 표시
    // (생체가 없어도 기기 암호(PIN/패턴/비밀번호)로 인증 가능)
    if (_biometricAuthEnabled && !_isAuthenticated) {
      return _buildAuthLockScreen(theme);
    }

    if (_activeSubview == _AssetSubview.savings) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _resetAutoLockTimer(),
        onPointerMove: (_) => _resetAutoLockTimer(),
        onPointerUp: (_) => _resetAutoLockTimer(),
        child: _buildSavingsView(theme),
      );
    }
    if (_activeSubview == _AssetSubview.expenses) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _resetAutoLockTimer(),
        onPointerMove: (_) => _resetAutoLockTimer(),
        onPointerUp: (_) => _resetAutoLockTimer(),
        child: _buildExpenseView(theme),
      );
    }

    final simpleTotal = _assets
        .where((asset) => asset.inputType == AssetInputType.simple)
        .fold<double>(0, (sum, asset) => sum + asset.amount);
    final detailTotal = _assets
        .where((asset) => asset.inputType == AssetInputType.detail)
        .fold<double>(0, (sum, asset) => sum + asset.amount);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetAutoLockTimer(),
      onPointerMove: (_) => _resetAutoLockTimer(),
      onPointerUp: (_) => _resetAutoLockTimer(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🎯 **대시보드 요약** (총 자산, 총 손익, 자산별 카드 뷰)
            AssetDashboardScreen(
              accountName: widget.accountName,
              assets: _assets,
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 2),
            const SizedBox(height: 8),
            // 📌 **기존 자산 입력/관리 메뉴**
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSecurityToggleRow(theme),
                  if (_isDeviceSupported) ...[
                    const SizedBox(height: 8),
                    _buildRootSecurityCard(theme),
                  ],
                  const SizedBox(height: 12),
                  _buildSimpleInputCard(theme, simpleTotal),
                  const SizedBox(height: 8),
                  _buildDetailInputCard(theme, detailTotal),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AssetAllocationScreen(
                            accountName: widget.accountName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(IconCatalog.pieChart),
                    label: const Text('📊 자산 배분 분석'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _exportAssets,
                    icon: const Icon(IconCatalog.download),
                    label: const Text('엑셀/CSV 내보내기'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthLockScreen(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconCatalog.lockOutline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 24),
            Text(
              '자산 정보 보호',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '개인 자산 정보는 비밀번호/PIN/지문(기기 인증)으로 보호됩니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _authenticateForAssetProtection,
              icon: Icon(
                _canCheckBiometrics
                    ? IconCatalog.fingerprint
                    : IconCatalog.password,
              ),
              label: const Text('인증하기'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _toggleBiometricAuth(false),
              child: const Text('인증 없이 사용하기'),
            ),
          ],
        ),
      ),
    );
  }
}
