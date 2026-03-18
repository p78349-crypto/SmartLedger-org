import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/errors.dart';
import '../shared/result.dart';

/// ROOT 전용 메모 모델
class RootMemo {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final String? color; // 메모 색상 (선택사항)

  const RootMemo({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.color,
  });

  factory RootMemo.fromJson(Map<String, dynamic> json) {
    return RootMemo(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'color': color,
    };
  }

  RootMemo copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    String? color,
  }) {
    return RootMemo(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RootMemo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// ROOT 전용 메모 관리 서비스
class RootMemoService {
  static const String _storageKey = 'root_memos_data';
  static RootMemoService? _instance;

  RootMemoService._();

  static RootMemoService getInstance() {
    _instance ??= RootMemoService._();
    return _instance!;
  }

  List<RootMemo> _memos = [];

  /// 모든 메모 조회 (고정된 것부터)
  List<RootMemo> getAllMemos() {
    _memos.sort((a, b) {
      // 고정된 메모가 먼저
      if (a.isPinned != b.isPinned) {
        return b.isPinned ? 1 : -1;
      }
      // 그 다음은 업데이트 시간 순
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return List.unmodifiable(_memos);
  }

  /// 메모 추가
  Future<void> addMemo({
    required String title,
    required String content,
    bool isPinned = false,
    String? color,
  }) async {
    final now = DateTime.now();
    final memo = RootMemo(
      id: _generateId(),
      title: title.trim(),
      content: content.trim(),
      createdAt: now,
      updatedAt: now,
      isPinned: isPinned,
      color: color,
    );

    _memos.add(memo);
    await _saveMemos();
  }

  /// 메모 업데이트
  Future<void> updateMemo({
    required String id,
    String? title,
    String? content,
    bool? isPinned,
    String? color,
  }) async {
    final index = _memos.indexWhere((m) => m.id == id);
    if (index == -1) return;

    final updated = _memos[index].copyWith(
      title: title?.trim(),
      content: content?.trim(),
      updatedAt: DateTime.now(),
      isPinned: isPinned,
      color: color,
    );

    _memos[index] = updated;
    await _saveMemos();
  }

  /// 메모 삭제
  Future<void> deleteMemo(String id) async {
    _memos.removeWhere((m) => m.id == id);
    await _saveMemos();
  }

  /// 메모 고정/해제
  Future<void> togglePin(String id) async {
    final index = _memos.indexWhere((m) => m.id == id);
    if (index == -1) return;

    _memos[index] = _memos[index].copyWith(
      isPinned: !_memos[index].isPinned,
      updatedAt: DateTime.now(),
    );
    await _saveMemos();
  }

  /// 특정 메모 조회
  RootMemo? getMemo(String id) {
    try {
      return _memos.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 검색
  List<RootMemo> searchMemos(String query) {
    if (query.trim().isEmpty) return getAllMemos();

    final lowerQuery = query.toLowerCase();
    return _memos
        .where(
          (m) =>
              m.title.toLowerCase().contains(lowerQuery) ||
              m.content.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  /// 통계
  Map<String, int> getStats() {
    return {
      'total': _memos.length,
      'pinned': _memos.where((m) => m.isPinned).length,
      'recent': _memos
          .where((m) => DateTime.now().difference(m.updatedAt).inDays < 7)
          .length,
    };
  }

  /// 데이터 로드
  Future<Result<void>> loadMemos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _memos = jsonList.map((json) => RootMemo.fromJson(json)).toList();
      }
      return const Success(null);
    } catch (e) {
      _memos = [];
      return Failure(StorageError('메모 데이터 로드 실패: $e'));
    }
  }

  /// 데이터 저장
  Future<Result<void>> _saveMemos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_memos.map((m) => m.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
      return const Success(null);
    } catch (e) {
      return Failure(StorageError('메모 저장 실패: $e'));
    }
  }

  /// 고유 ID 생성
  String _generateId() {
    return 'root_memo_${DateTime.now().millisecondsSinceEpoch}_${_memos.length}';
  }

  /// 전체 데이터 정리 (ROOT 전용)
  Future<void> clearAllMemos() async {
    _memos.clear();
    await _saveMemos();
  }

  /// 백업 데이터 생성
  Map<String, dynamic> exportData() {
    return {
      'memos': _memos.map((m) => m.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  /// 백업 데이터 복원
  Future<Result<void>> importData(Map<String, dynamic> data) async {
    try {
      final List<dynamic> memosList = data['memos'] as List<dynamic>;
      _memos = memosList.map((json) => RootMemo.fromJson(json)).toList();
      await _saveMemos();
      return const Success(null);
    } catch (e) {
      return Failure(StorageError('메모 데이터 복원 실패: $e'));
    }
  }
}
