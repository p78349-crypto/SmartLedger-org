part of theme_settings_screen;

class _AppIconSyncSection extends StatefulWidget {
  const _AppIconSyncSection();

  @override
  State<_AppIconSyncSection> createState() => _AppIconSyncSectionState();
}

class _AppIconSyncSectionState extends State<_AppIconSyncSection> {
  bool _isSyncing = false;
  String _iconStyle = 'standard';

  Future<void> _syncIcon() async {
    final presetId = AppThemeSeedController.instance.presetId.value;
    final isFemale = ThemePresets.female.any((p) => p.id == presetId);

    final String targetIconTheme;
    if (_iconStyle == 'intense') {
      targetIconTheme = isFemale ? 'light_intense' : 'dark_intense';
    } else {
      targetIconTheme = isFemale ? 'light' : 'dark';
    }

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('앱 아이콘 적용'),
          content: Text(
            '현재 선택된 테마(${isFemale ? "여성향" : "남성향"})와 '
            '스타일(${_iconStyle == "intense" ? "진하게" : "기본"})에 맞춰 '
            '앱 아이콘을 변경합니다.\n\n'
            '⚠️ 적용 시 안드로이드 시스템 정책에 의해 앱이 즉시 종료됩니다. '
            '다시 실행해 주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('적용 및 종료'),
            ),
          ],
        );
      },
    );

    if (proceed != true) {
      return;
    }

    setState(() => _isSyncing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_icon_theme_id', targetIconTheme);
      await AppIconService.setLauncherIconTheme(targetIconTheme);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('앱 아이콘 관리', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('기본 색상')),
                selected: _iconStyle == 'standard',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _iconStyle = 'standard');
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('진한 색상')),
                selected: _iconStyle == 'intense',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _iconStyle = 'intense');
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.phonelink_setup_rounded),
            title: const Text('테마와 아이콘 동기화'),
            subtitle: const Text(
              '선택한 테마 색상에 맞춰 홈 화면 아이콘을 변경합니다.',
            ),
            trailing: _isSyncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onTap: _isSyncing ? null : _syncIcon,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '※ 아이콘 변경은 안드로이드 시스템에 의해 앱 재시작이 필요하므로, '
            '모든 설정을 마친 후 수동으로 적용하는 것을 권장합니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
