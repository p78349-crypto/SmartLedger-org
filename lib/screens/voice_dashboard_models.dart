/// 음성 대시보드 데이터 모델.
library;

/// 음성 명령의 유형.
enum VoiceCommandType {
  expense,
  navigation,
  query,
  recommend,
  shopping,
  unknown,
}

/// 음성 명령 처리 결과.
class VoiceCommandResult {
  final String command;
  final bool success;
  final String message;
  final VoiceCommandType type;
  final Map<String, dynamic>? data;

  VoiceCommandResult({
    required this.command,
    required this.success,
    required this.message,
    required this.type,
    this.data,
  });
}

/// 보이스 가이드 아이템 (개별 명령어 예시).
class VoiceGuideItem {
  final String command;
  final String description;
  final String category;

  const VoiceGuideItem({
    required this.command,
    required this.description,
    required this.category,
  });
}

/// 보이스 가이드 페이지 데이터.
class VoiceGuideData {
  final String level;
  final String levelEmoji;
  final int levelColorValue;
  final String title;
  final String description;
  final List<String> examples;
  final String tip;

  const VoiceGuideData({
    required this.level,
    required this.levelEmoji,
    required this.levelColorValue,
    required this.title,
    required this.description,
    required this.examples,
    required this.tip,
  });
}
