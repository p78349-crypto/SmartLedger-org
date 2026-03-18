import 'dart:async';

import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../services/subscription_billing_service.dart';
import '../services/subscription_purchase_sync_service.dart';

class SubscriptionManageScreen extends StatefulWidget {
  const SubscriptionManageScreen({super.key, this.userId});

  final String? userId;

  @override
  State<SubscriptionManageScreen> createState() =>
      _SubscriptionManageScreenState();
}

class _SubscriptionManageScreenState extends State<SubscriptionManageScreen> {
  final SubscriptionBillingService _billingService =
      SubscriptionBillingService();
  final SubscriptionPurchaseSyncService _purchaseSyncService =
      SubscriptionPurchaseSyncService();
  bool _busy = false;

  String get _effectiveUserId {
    final value = widget.userId?.trim();
    if (value == null || value.isEmpty) {
      return 'local_default_user';
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_purchaseSyncService.start(userId: _effectiveUserId));
  }

  Future<void> _runAction(
    Future<SubscriptionBillingResult> Function(String userId) action,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await action(_effectiveUserId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('구독 관리')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '프리미엄 기능 접근을 위해 구독 상태를 확인하거나 결제를 진행하세요.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('현재 상태 확인'),
              subtitle: const Text('만료/유예/활성 상태를 확인합니다.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy
                  ? null
                  : () => _runAction(
                      (userId) => _billingService.checkSubscriptionStatus(
                        userId: userId,
                      ),
                    ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_cart_checkout),
              title: const Text('구독 결제 진행'),
              subtitle: const Text('스토어 결제 흐름을 시작합니다.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy
                  ? null
                  : () => _runAction(
                      (userId) =>
                          _billingService.startPurchaseFlow(userId: userId),
                    ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('구매 복구'),
              subtitle: const Text('기존 구독 구매를 복구합니다.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _busy
                  ? null
                  : () => _runAction(
                      (userId) =>
                          _billingService.restorePurchases(userId: userId),
                    ),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settings);
            },
            icon: const Icon(Icons.settings),
            label: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }
}
