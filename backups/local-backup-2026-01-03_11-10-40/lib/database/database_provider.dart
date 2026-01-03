import 'package:smart_ledger/database/app_database.dart';

class DatabaseProvider {
  DatabaseProvider._();

  static final DatabaseProvider instance = DatabaseProvider._();

  AppDatabase? _database;

  AppDatabase get database => _database ??= AppDatabase();

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
