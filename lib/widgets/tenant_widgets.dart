import 'package:flutter/material.dart';
import '../services/multi_tenant_service.dart';

class TenantSwitcher extends StatelessWidget {
  final VoidCallback? onManage;

  const TenantSwitcher({super.key, this.onManage});

  @override
  Widget build(BuildContext context) {
    final service = MultiTenantService();
    return ValueListenableBuilder<Tenant?>(
      valueListenable: service.tenantNotifier,
      builder: (context, currentTenant, _) {
        if (currentTenant == null) return const SizedBox.shrink();

        return PopupMenuButton<String>(
          tooltip: '테넌트 전환',
          onSelected: (id) {
            if (id == '_manage') {
              onManage?.call();
            } else {
              service.switchTenant(id);
            }
          },
          itemBuilder: (_) => [
            ...service.tenants
                .where((t) => t.isActive)
                .map(
                  (t) => PopupMenuItem(
                    value: t.id,
                    child: Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 18,
                          color: t.id == currentTenant.id
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.name,
                                style: TextStyle(
                                  fontWeight: t.id == currentTenant.id
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              Text(
                                t.organizationName,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        if (t.id == currentTenant.id)
                          Icon(
                            Icons.check,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: '_manage',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 18),
                  SizedBox(width: 8),
                  Text('테넌트 관리'),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: currentTenant.plan.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: currentTenant.plan.color.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business, size: 16, color: currentTenant.plan.color),
                const SizedBox(width: 4),
                Text(
                  currentTenant.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: currentTenant.plan.color,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: currentTenant.plan.color,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 테넌트 사용량 대시보드
class TenantUsageDashboard extends StatelessWidget {
  final TenantUsageStats stats;

  const TenantUsageDashboard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '테넌트 사용량',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: stats.plan.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stats.plan.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: stats.plan.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 멤버 수
            _buildUsageRow(
              context,
              icon: Icons.people,
              label: '멤버',
              current: stats.memberCount,
              max: stats.maxMembers,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            // 저장소
            _buildUsageRow(
              context,
              icon: Icons.cloud,
              label: '저장소 (MB)',
              current: stats.usedStorageMb.round(),
              max: stats.quotaMb,
              color: stats.isOverQuota ? Colors.red : Colors.green,
            ),
            if (stats.isOverQuota) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '저장소 용량을 초과했습니다. 플랜 업그레이드를 권장합니다.',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int current,
    required int max,
    required Color color,
  }) {
    final progress = max > 0 ? current / max : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Text(
              '$current / $max',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

/// 테넌트 관리 다이얼로그
class TenantManageDialog extends StatelessWidget {
  const TenantManageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MultiTenantService();
    final tenants = service.tenants;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.business_center, color: Colors.blue),
          SizedBox(width: 8),
          Text('테넌트 관리'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...tenants.map(
              (t) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: t.plan.color.withValues(alpha: 0.2),
                  child: Icon(Icons.business, color: t.plan.color, size: 20),
                ),
                title: Text(t.name),
                subtitle: Text('${t.organizationName} • ${t.plan.label}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (t.isActive)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (t.id != 'default')
                      IconButton(
                        icon: const Icon(Icons.settings, size: 18),
                        onPressed: () {},
                      ),
                  ],
                ),
                onTap: () {
                  if (t.isActive) {
                    service.switchTenant(t.id);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.add, color: Colors.white, size: 20),
              ),
              title: const Text('새 테넌트 추가'),
              subtitle: const Text('새로운 조직 환경 생성'),
              onTap: () {
                _showCreateDialog(context);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    final orgController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('새 테넌트 생성'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '테넌트 이름',
                hintText: '예: 개발팀 환경',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: orgController,
              decoration: const InputDecoration(
                labelText: '조직명',
                hintText: '예: (주)스마트레저',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  orgController.text.isNotEmpty) {
                await MultiTenantService().createTenant(
                  name: nameController.text,
                  organizationName: orgController.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('생성'),
          ),
        ],
      ),
    );
  }
}
