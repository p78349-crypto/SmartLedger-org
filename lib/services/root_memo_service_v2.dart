import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_provider.dart';
import '../database/app_database.dart';

/// ROOT 전용 메모 모델 (개선된 버전)
class RootMemo {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final String? color;
  final int sortOrder;

  const RootMemo({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.color,
    this.sortOrder = 0,
  });

  factory RootMemo.fromDbRow(DbRootMemo dbMemo) {
    return RootMemo(
      id: dbMemo.id,
      title: dbMemo.title,
      content: dbMemo.content,
      createdAt: dbMemo.createdAt,
      updatedAt: dbMemo.updatedAt,
      isPinned: dbMemo.isPinned,
      color: dbMemo.color,
      sortOrder: dbMemo.sortOrder,
    );
  }

  DbRootMemosCompanion toDbCompanion() {
    return DbRootMemosCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isPinned: Value(isPinned),
      color: Value(color),
      sortOrder: Value(sortOrder),
    );
  }

  RootMemo copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    String? color,
    int? sortOrder,
  }) {
    return RootMemo(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// ROOT 전용 메모 서비스 (SQLite 기반)
class RootMemoServiceV2 {
  static RootMemoServiceV2? _instance;

  RootMemoServiceV2._();

  static RootMemoServiceV2 getInstance() {
    _instance ??= RootMemoServiceV2._();
    return _instance!;
  }

  AppDatabase get _db => DatabaseProvider.instance.database;

  /// 모든 메모 조회 (고정된 것부터, 업데이트 순)
  Future<List<RootMemo>> getAllMemos() async {
    try {
      final query = _db.select(_db.dbRootMemos)
        ..orderBy([
          // 고정된 메모 먼저
          (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
          // 정렬 순서 오름차순
          (t) => OrderingTerm(expression: t.sortOrder, mode: OrderingMode.asc),
          // 최신 업데이트 순
          (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        ]);

      final rows = await query.get();
      return rows.map((row) => RootMemo.fromDbRow(row)).toList();
    } catch (e) {
      print('메모 조회 오류: $e');
      return [];
    }
  }

  /// 메모 추가
  Future<String?> addMemo({
    required String title,
    required String content,
    bool isPinned = false,
    String? color,
    int? sortOrder,
  }) async {
    try {
      final now = DateTime.now();
      final id = _generateId();

      final companion = DbRootMemosCompanion(
        id: Value(id),
        title: Value(title.trim()),
        content: Value(content.trim()),
        createdAt: Value(now),
        updatedAt: Value(now),
        isPinned: Value(isPinned),
        color: Value(color),
        sortOrder: Value(sortOrder ?? await _getNextSortOrder()),
      );

      await _db.into(_db.dbRootMemos).insert(companion);
      return id;
    } catch (e) {
      print('메모 추가 오류: $e');
      return null;
    }
  }

  /// 메모 수정
  Future<bool> updateMemo({
    required String id,
    String? title,
    String? content,
    bool? isPinned,
    String? color,
    int? sortOrder,
  }) async {
    try {
      final companion = DbRootMemosCompanion(
        title: title != null ? Value(title.trim()) : const Value.absent(),
        content: content != null ? Value(content.trim()) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
        isPinned: isPinned != null ? Value(isPinned) : const Value.absent(),
        color: color != null ? Value(color) : const Value.absent(),
        sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
      );

      final rowsUpdated = await (_db.update(
        _db.dbRootMemos,
      )..where((t) => t.id.equals(id))).write(companion);

      return rowsUpdated > 0;
    } catch (e) {
      print('메모 수정 오류: $e');
      return false;
    }
  }

  /// 메모 삭제
  Future<bool> deleteMemo(String id) async {
    try {
      final rowsDeleted = await (_db.delete(
        _db.dbRootMemos,
      )..where((t) => t.id.equals(id))).go();

      return rowsDeleted > 0;
    } catch (e) {
      print('메모 삭제 오류: $e');
      return false;
    }
  }

  /// 메모 고정/해제
  Future<bool> togglePin(String id) async {
    try {
      // 현재 상태 조회
      final memo = await (_db.select(
        _db.dbRootMemos,
      )..where((t) => t.id.equals(id))).getSingleOrNull();

      if (memo == null) return false;

      return await updateMemo(id: id, isPinned: !memo.isPinned);
    } catch (e) {
      print('메모 고정 토글 오류: $e');
      return false;
    }
  }

  /// 메모 검색 (제목 + 내용)
  Future<List<RootMemo>> searchMemos(String query) async {
    if (query.trim().isEmpty) return await getAllMemos();

    try {
      final searchQuery = '%${query.trim()}%';
      final dbQuery = _db.select(_db.dbRootMemos)
        ..where((t) => t.title.like(searchQuery) | t.content.like(searchQuery))
        ..orderBy([
          (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
          (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        ]);

      final rows = await dbQuery.get();
      return rows.map((row) => RootMemo.fromDbRow(row)).toList();
    } catch (e) {
      print('메모 검색 오류: $e');
      return [];
    }
  }

  /// 통계 조회
  Future<Map<String, int>> getStats() async {
    try {
      final totalQuery = _db.selectOnly(_db.dbRootMemos)
        ..addColumns([_db.dbRootMemos.id.count()]);

      final pinnedQuery = _db.selectOnly(_db.dbRootMemos)
        ..addColumns([_db.dbRootMemos.id.count()])
        ..where(_db.dbRootMemos.isPinned.equals(true));

      final recentDate = DateTime.now().subtract(const Duration(days: 7));
      final recentQuery = _db.selectOnly(_db.dbRootMemos)
        ..addColumns([_db.dbRootMemos.id.count()])
        ..where(_db.dbRootMemos.updatedAt.isBiggerThanValue(recentDate));

      final totalResult = await totalQuery.getSingle();
      final pinnedResult = await pinnedQuery.getSingle();
      final recentResult = await recentQuery.getSingle();

      return {
        'total': totalResult.read(_db.dbRootMemos.id.count()) ?? 0,
        'pinned': pinnedResult.read(_db.dbRootMemos.id.count()) ?? 0,
        'recent': recentResult.read(_db.dbRootMemos.id.count()) ?? 0,
      };
    } catch (e) {
      print('통계 조회 오류: $e');
      return {'total': 0, 'pinned': 0, 'recent': 0};
    }
  }

  /// 색상별 메모 조회
  Future<List<RootMemo>> getMemosByColor(String? color) async {
    try {
      final query = _db.select(_db.dbRootMemos);

      if (color == null) {
        query.where((t) => t.color.isNull());
      } else {
        query.where((t) => t.color.equals(color));
      }

      query.orderBy([
        (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);

      final rows = await query.get();
      return rows.map((row) => RootMemo.fromDbRow(row)).toList();
    } catch (e) {
      print('색상별 메모 조회 오류: $e');
      return [];
    }
  }

  /// 메모 순서 재정렬
  Future<bool> reorderMemos(List<String> orderedIds) async {
    try {
      await _db.transaction(() async {
        for (int i = 0; i < orderedIds.length; i++) {
          final companion = DbRootMemosCompanion(
            sortOrder: Value(i),
            updatedAt: Value(DateTime.now()),
          );

          await (_db.update(
            _db.dbRootMemos,
          )..where((t) => t.id.equals(orderedIds[i]))).write(companion);
        }
      });

      return true;
    } catch (e) {
      print('메모 순서 재정렬 오류: $e');
      return false;
    }
  }

  /// 전체 메모 삭제 (ROOT 전용)
  Future<bool> clearAllMemos() async {
    try {
      await _db.delete(_db.dbRootMemos).go();
      return true;
    } catch (e) {
      print('전체 메모 삭제 오류: $e');
      return false;
    }
  }

  /// 백업 데이터 생성 (JSON 형태)
  Future<String?> exportToJson() async {
    try {
      final memos = await getAllMemos();
      final jsonData = {
        'version': '2.0',
        'exportDate': DateTime.now().toIso8601String(),
        'memos': memos
            .map(
              (memo) => {
                'id': memo.id,
                'title': memo.title,
                'content': memo.content,
                'createdAt': memo.createdAt.toIso8601String(),
                'updatedAt': memo.updatedAt.toIso8601String(),
                'isPinned': memo.isPinned,
                'color': memo.color,
                'sortOrder': memo.sortOrder,
              },
            )
            .toList(),
      };

      return jsonEncode(jsonData);
    } catch (e) {
      print('백업 생성 오류: $e');
      return null;
    }
  }

  /// 백업 데이터 복원 (JSON에서)
  Future<bool> importFromJson(String jsonData) async {
    try {
      final data = jsonDecode(jsonData);
      final memos = data['memos'] as List;

      await _db.transaction(() async {
        for (final memoData in memos) {
          final companion = DbRootMemosCompanion(
            id: Value(memoData['id']),
            title: Value(memoData['title']),
            content: Value(memoData['content']),
            createdAt: Value(DateTime.parse(memoData['createdAt'])),
            updatedAt: Value(DateTime.parse(memoData['updatedAt'])),
            isPinned: Value(memoData['isPinned'] ?? false),
            color: Value(memoData['color']),
            sortOrder: Value(memoData['sortOrder'] ?? 0),
          );

          await _db.into(_db.dbRootMemos).insertOnConflictUpdate(companion);
        }
      });

      return true;
    } catch (e) {
      print('백업 복원 오류: $e');
      return false;
    }
  }

  /// 고유 ID 생성 (UUID 스타일)
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + DateTime.now().microsecond) % 1000000;
    return 'root_memo_${timestamp}_$random';
  }

  /// 다음 정렬 순서 번호 가져오기
  Future<int> _getNextSortOrder() async {
    try {
      final query = _db.selectOnly(_db.dbRootMemos)
        ..addColumns([_db.dbRootMemos.sortOrder.max()]);

      final result = await query.getSingle();
      final maxOrder = result.read(_db.dbRootMemos.sortOrder.max());

      return (maxOrder ?? 0) + 1;
    } catch (e) {
      return 0;
    }
  }

  /// SharedPreferences에서 기존 메모 마이그레이션
  Future<bool> migrateFromSharedPreferences() async {
    try {
      // 기존 서비스 인스턴스를 사용해서 데이터 가져오기
      final oldService = RootMemoService.getInstance();
      await oldService.loadMemos();
      final oldMemos = oldService.getAllMemos();

      if (oldMemos.isNotEmpty) {
        print('기존 메모 ${oldMemos.length}개 마이그레이션 시작...');

        await _db.transaction(() async {
          for (final oldMemo in oldMemos) {
            final companion = DbRootMemosCompanion(
              id: Value(oldMemo.id),
              title: Value(oldMemo.title),
              content: Value(oldMemo.content),
              createdAt: Value(oldMemo.createdAt),
              updatedAt: Value(oldMemo.updatedAt),
              isPinned: Value(oldMemo.isPinned),
              color: Value(oldMemo.color),
              sortOrder: Value(0), // 기존에는 정렬 순서가 없었으므로 0으로 설정
            );

            await _db.into(_db.dbRootMemos).insertOnConflictUpdate(companion);
          }
        });

        print('마이그레이션 완료: ${oldMemos.length}개 메모');
        return true;
      }

      return false;
    } catch (e) {
      print('마이그레이션 오류: $e');
      return false;
    }
  }
}

/// 기존 SharedPreferences 기반 서비스 (하위 호환성용)
class RootMemoService {
  static const String _storageKey = 'root_memos';
  static RootMemoService? _instance;

  RootMemoService._();

  static RootMemoService getInstance() {
    _instance ??= RootMemoService._();
    return _instance!;
  }

  List<RootMemo> _memos = [];

  List<RootMemo> getAllMemos() => List.unmodifiable(_memos);

  Future<void> loadMemos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _memos = jsonList
            .map(
              (json) => RootMemo(
                id: json['id'],
                title: json['title'],
                content: json['content'],
                createdAt: DateTime.parse(json['createdAt']),
                updatedAt: DateTime.parse(json['updatedAt']),
                isPinned: json['isPinned'] ?? false,
                color: json['color'],
                sortOrder: json['sortOrder'] ?? 0,
              ),
            )
            .toList();
      }
    } catch (e) {
      _memos = [];
    }
  }
}
