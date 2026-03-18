import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 2 개선: 간단 모드 vs 고급 모드 토글 시스템
/// 비기술 사용자를 위한 UI 단순화
class SimpleModeManger {
  static const String _simpleModePrefKey = 'app_simple_mode_enabled';
  static final ValueNotifier<bool> _isSimpleModeNotifier = ValueNotifier<bool>(
    false,
  );

  /// 간단 모드 상태 감지기
  static ValueListenable<bool> get isSimpleModeNotifier =>
      _isSimpleModeNotifier;

  /// 현재 간단 모드 여부
  static bool get isSimpleMode => _isSimpleModeNotifier.value;

  /// 앱 시작 시 사용자 선호도 로드
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isSimple = prefs.getBool(_simpleModePrefKey) ?? false;
    _isSimpleModeNotifier.value = isSimple;
  }

  /// 간단 모드 토글
  static Future<void> toggleSimpleMode() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !_isSimpleModeNotifier.value;
    await prefs.setBool(_simpleModePrefKey, newValue);
    _isSimpleModeNotifier.value = newValue;
  }

  /// 간단 모드 설정
  static Future<void> setSimpleMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_simpleModePrefKey, enabled);
    _isSimpleModeNotifier.value = enabled;
  }
}

/// 간단/고급 모드 토글 위젯
class SimpleModeToggle extends StatelessWidget {
  final VoidCallback? onChanged;
  final bool showLabel;

  const SimpleModeToggle({super.key, this.onChanged, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: SimpleModeManger.isSimpleModeNotifier,
      builder: (context, isSimple, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLabel) ...[
              Icon(
                isSimple ? Icons.lightbulb : Icons.settings,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                isSimple ? '간단 모드' : '고급 모드',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Switch.adaptive(
              value: isSimple,
              onChanged: (value) async {
                await SimpleModeManger.setSimpleMode(value);
                onChanged?.call();
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        );
      },
    );
  }
}

/// 간단 모드 반응형 빌더 위젯
class SimpleModeBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isSimpleMode) builder;

  const SimpleModeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SimpleModeManger.isSimpleModeNotifier,
      builder: (context, isSimple, _) => builder(context, isSimple),
    );
  }
}

/// 간단 모드 시 컨텐츠를 조건부로 표시/숨김
class ConditionalByMode extends StatelessWidget {
  final Widget? simpleMode;
  final Widget? advancedMode;
  final Widget? bothModes;

  const ConditionalByMode({
    super.key,
    this.simpleMode,
    this.advancedMode,
    this.bothModes,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleModeBuilder(
      builder: (context, isSimple) {
        // 공통 컨텐츠가 있으면 먼저 반환
        if (bothModes != null) return bothModes!;

        // 모드별 컨텐츠 반환
        if (isSimple && simpleMode != null) return simpleMode!;
        if (!isSimple && advancedMode != null) return advancedMode!;

        // 해당하는 컨텐츠가 없으면 빈 위젯
        return const SizedBox.shrink();
      },
    );
  }
}

/// 간단 모드용 핵심 액션 정의
enum CoreAction {
  connect('연결', Icons.play_circle, Colors.green, '시스템에 연결합니다'),
  disconnect('연결 해제', Icons.stop_circle, Colors.red, '시스템에서 연결을 해제합니다'),
  status('상태 확인', Icons.info, Colors.blue, '현재 시스템 상태를 확인합니다'),
  logs('로그 보기', Icons.list_alt, Colors.orange, '최근 활동 로그를 확인합니다'),
  help('도움말', Icons.help, Colors.purple, '사용법과 도움말을 확인합니다');

  const CoreAction(this.label, this.icon, this.color, this.description);

  final String label;
  final IconData icon;
  final Color color;
  final String description;
}

/// 간단 모드용 핵심 액션 버튼
class CoreActionButton extends StatelessWidget {
  final CoreAction action;
  final VoidCallback? onPressed;
  final bool isLoading;

  const CoreActionButton({
    super.key,
    required this.action,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                CircularProgressIndicator(color: action.color, strokeWidth: 3)
              else
                Icon(action.icon, size: 32, color: action.color),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                action.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 간단 모드용 핵심 액션 그리드
class SimpleModeActionGrid extends StatelessWidget {
  final Map<CoreAction, VoidCallback?> actions;
  final Map<CoreAction, bool> loadingStates;

  const SimpleModeActionGrid({
    super.key,
    required this.actions,
    this.loadingStates = const {},
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions.keys.elementAt(index);
        final onPressed = actions[action];
        final isLoading = loadingStates[action] ?? false;

        return CoreActionButton(
          action: action,
          onPressed: onPressed,
          isLoading: isLoading,
        );
      },
    );
  }
}

/// 모드 전환 확인 다이얼로그
class ModeChangeConfirmDialog extends StatelessWidget {
  final bool toSimpleMode;

  const ModeChangeConfirmDialog({super.key, required this.toSimpleMode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            toSimpleMode ? Icons.lightbulb : Icons.settings,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(toSimpleMode ? '간단 모드로 전환' : '고급 모드로 전환'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            toSimpleMode
                ? '복잡한 기능들을 숨기고 핵심 기능만 표시합니다.'
                : '모든 고급 기능과 설정을 사용할 수 있습니다.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  toSimpleMode ? '간단 모드 특징:' : '고급 모드 특징:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (toSimpleMode) ...[
                  const Text('• 핵심 5개 기능만 표시'),
                  const Text('• 큰 아이콘과 명확한 설명'),
                  const Text('• 복잡한 설정 숨김'),
                  const Text('• 초보자 친화적 인터페이스'),
                ] else ...[
                  const Text('• 모든 기능 접근 가능'),
                  const Text('• 상세 설정 및 고급 옵션'),
                  const Text('• 전문가용 도구들'),
                  const Text('• 커스터마이징 가능'),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(toSimpleMode ? '간단 모드로' : '고급 모드로'),
        ),
      ],
    );
  }

  /// 모드 전환 확인 다이얼로그 표시
  static Future<bool> show(BuildContext context, bool toSimpleMode) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ModeChangeConfirmDialog(toSimpleMode: toSimpleMode),
    );
    return result ?? false;
  }
}

/// 간단 모드 유틸리티
class SimpleModeUtils {
  /// 현재 모드에 따른 메뉴 아이템 필터링
  static List<T> filterByMode<T>(
    List<T> items,
    bool Function(T item) isEssential,
  ) {
    if (SimpleModeManger.isSimpleMode) {
      return items.where(isEssential).toList();
    }
    return items;
  }

  /// 메뉴 아이템의 중요도 판단 (간단 모드 필터링용)
  static bool isEssentialFeature(String featureName) {
    const essentialFeatures = {
      '연결',
      '해제',
      '상태',
      '로그',
      '도움말',
      'connect',
      'disconnect',
      'status',
      'logs',
      'help',
      '대시보드',
      '거래',
      '통계',
      '설정',
    };

    return essentialFeatures.any(
      (essential) =>
          featureName.toLowerCase().contains(essential.toLowerCase()),
    );
  }

  /// 복잡도에 따른 UI 요소 표시 여부
  static bool shouldShowInMode(UIComplexity complexity) {
    if (SimpleModeManger.isSimpleMode) {
      return complexity.index <= UIComplexity.basic.index;
    }
    return true; // 고급 모드에서는 모든 것 표시
  }
}

/// UI 복잡도 레벨
enum UIComplexity {
  essential(0, '필수'), // 간단 모드에서도 반드시 표시
  basic(1, '기본'), // 간단 모드에서 표시
  intermediate(2, '중급'), // 고급 모드에서만
  advanced(3, '고급'), // 고급 모드에서만
  expert(4, '전문가'); // 고급 모드에서만

  const UIComplexity(this.level, this.displayName);
  final int level;
  final String displayName;
}
