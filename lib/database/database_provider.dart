import 'app_database.dart';

class DatabaseProvider {
  DatabaseProvider._();

  static final DatabaseProvider instance = DatabaseProvider._();

  AppDatabase? _database;

  AppDatabase get database => _database ??= AppDatabase();

  /// Override the database instance (intended for tests).
  ///
  /// Note: Call [close] after the test suite if you need to release resources.
  void overrideForTesting(AppDatabase db) {
    _database = db;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
