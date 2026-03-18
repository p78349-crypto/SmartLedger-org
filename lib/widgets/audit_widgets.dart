import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/audit_log_service.dart';

class AuditLogSummaryCard extends StatelessWidget {
  final int maxItems;
  final VoidCallback? onViewAll;

  const AuditLogSummaryCard({super.key, this.maxItems = 5, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AuditLogEntry>>(
      future: AuditLogService.getRecentLogs(limit: maxItems),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final logs = snapshot.data!;
        final theme = Theme.of(context);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '최근 감사 로그',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (onViewAll != null)
                      TextButton(
                        onPressed: onViewAll,
                        child: const Text('전체 보기'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (logs.isEmpty)
                  const Text('감사 로그가 없습니다.')
                else
                  ...logs.map(
                    (log) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: log.logLevel.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              log.displaySummary,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Text(
                            DateFormat('MM-dd HH:mm').format(log.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 실패 작업 알림 카드
class FailedActionsCard extends StatelessWidget {
  const FailedActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AuditLogEntry>>(
      future: AuditLogService.getFailedActions(limit: 3),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final failedLogs = snapshot.data!;
        final theme = Theme.of(context);

        return Card(
          color: theme.colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Text(
                      '최근 실패 작업 (${failedLogs.length}건)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...failedLogs.map(
                  (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${log.displaySummary}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
