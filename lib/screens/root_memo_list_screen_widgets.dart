part of 'root_memo_list_screen.dart';

class _MemoCard extends StatelessWidget {
  final RootMemo memo;
  final Color? color;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _MemoCard({
    required this.memo,
    this.color,
    required this.searchQuery,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Card(
      color: color,
      elevation: memo.isPinned ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 (제목 + 메뉴)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (memo.isPinned)
                    Container(
                      margin: const EdgeInsets.only(right: 8, top: 2),
                      child: const Icon(
                        Icons.push_pin,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      memo.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: memo.isPinned
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(
                              memo.isPinned
                                  ? Icons.push_pin_outlined
                                  : Icons.push_pin,
                            ),
                            const SizedBox(width: 8),
                            Text(memo.isPinned ? '고정 해제' : '상단 고정'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('수정'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('삭제', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'pin':
                          onPin();
                          break;
                        case 'edit':
                          onTap();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 내용
              Text(
                memo.content,
                style: theme.textTheme.bodyMedium,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // 하단 정보
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '수정: ${dateFormat.format(memo.updatedAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (memo.createdAt != memo.updatedAt)
                    Icon(Icons.edit, size: 14, color: Colors.grey.shade600),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _ColorChip extends StatelessWidget {
  final Color? color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorChip({
    this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color ?? Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.blue, width: 2)
              : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
