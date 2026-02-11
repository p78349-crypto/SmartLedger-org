part of 'asset_tab_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension AssetTabScreenBuildWidgets on _AssetTabScreenState {
  Widget _buildSecurityToggleRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 보안 토글 (기기 인증이 가능한 경우만)
        if (_isDeviceSupported)
          Row(
            children: [
              Icon(
                _biometricAuthEnabled
                    ? IconCatalog.lock
                    : IconCatalog.lockOpen,
                size: 20,
                color: _biometricAuthEnabled
                    ? Colors.green
                    : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                '보안',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Switch(
                value: _biometricAuthEnabled,
                onChanged: _toggleBiometricAuth,
                activeTrackColor: Colors.green[200],
                activeThumbColor: Colors.green,
              ),
            ],
          )
        else
          const SizedBox.shrink(),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _toggleExpensesView,
              icon: const Icon(IconCatalog.receiptLongOutlined),
              label: const Text('통계 > 지출'),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }

  Widget _buildRootSecurityCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ROOT 보안', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ROOT 잠금',
                  style: theme.textTheme.bodyMedium,
                ),
                Switch(
                  value: _rootAuthEnabled,
                  onChanged: _setRootAuthEnabled,
                ),
              ],
            ),
            if (!_rootAuthEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'OFF 상태에서는 ROOT 인증 없이 접근 가능합니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (_rootAuthEnabled)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RadioGroup<String>(
                    groupValue: _rootAuthMode,
                    onChanged: (value) {
                      if (value == null) return;
                      _setRootAuthMode(value);
                    },
                    child: const Column(
                      children: [
                        RadioListTile<String>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '통합 사용 (자산 인증으로 ROOT 통과)',
                          ),
                          value: 'integrated',
                        ),
                        RadioListTile<String>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('별도 사용 (ROOT 추가 인증)'),
                          value: 'separate',
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ROOT PIN 사용',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Switch(
                        value: _rootPinEnabled,
                        onChanged: _setRootPinEnabled,
                      ),
                    ],
                  ),
                  if (_rootPinEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '별도 사용 모드에서는 2단계가 PIN으로 진행됩니다.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                              color: theme
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _showSetRootPinDialog,
                      child: Text(
                        _rootPinConfigured
                            ? 'ROOT PIN 변경'
                            : 'ROOT PIN 설정',
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleInputCard(ThemeData theme, double simpleTotal) {
    return Card(
      child: InkWell(
        onTap: _openSimpleInput,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                IconCatalog.accountBalanceWallet,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '간단 입력',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      CurrencyFormatter.format(simpleTotal),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                IconCatalog.chevronRight,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailInputCard(ThemeData theme, double detailTotal) {
    return Card(
      child: InkWell(
        onTap: _openDetailInput,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                IconCatalog.inventory2,
                color: theme.colorScheme.secondary,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '상세 입력',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      CurrencyFormatter.format(detailTotal),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                IconCatalog.chevronRight,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
