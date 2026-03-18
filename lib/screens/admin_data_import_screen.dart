import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../services/product_data_importer.dart';
import '../services/us_product_importer.dart';
import '../services/japan_product_importer.dart';
import '../migrations/migration_global_product_db.dart';

class AdminDataImportScreen extends StatefulWidget {
  const AdminDataImportScreen({super.key});

  @override
  State<AdminDataImportScreen> createState() => _AdminDataImportScreenState();
}

class _AdminDataImportScreenState extends State<AdminDataImportScreen> {
  bool _isImporting = false;
  String _status = '';
  int _progress = 0;
  int _total = 0;

  Future<Database> _openGlobalProductDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'global_products.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await migrationGlobalProductDatabase(db);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('데이터 임포트 관리자'),
        backgroundColor: Colors.purple.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '임포트 상태',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_isImporting) ...[
                    LinearProgressIndicator(
                      value: _total > 0 ? _progress / _total : 0,
                      backgroundColor: Colors.grey.shade300,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text('$_progress / $_total'),
                  ] else ...[
                    Text(_status.isEmpty ? '준비 완료' : _status),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Korean data section
            _buildDataSection(
              title: '🇰🇷 한국 데이터',
              description: '한국 식료품 DB (3,088개 상품)',
              onImport: _importKoreanData,
              isLoading: _isImporting,
            ),
            const SizedBox(height: 16),

            // US data section
            _buildDataSection(
              title: '🇺🇸 미국 데이터',
              description: 'USDA FoodData Central (70,000+ 상품)',
              onImport: _importUsData,
              isLoading: _isImporting,
            ),
            const SizedBox(height: 16),

            // Japan data section
            _buildDataSection(
              title: '🇯🇵 일본 데이터',
              description: 'MEXT Kagsei (10,000+ 상품)',
              onImport: _importJapanData,
              isLoading: _isImporting,
            ),
            const SizedBox(height: 24),

            // Import all button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isImporting ? null : _importAllData,
                icon: const Icon(Icons.cloud_download),
                label: const Text('모든 데이터 임포트'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection({
    required String title,
    required String description,
    required Function() onImport,
    required bool isLoading,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: Text(isLoading ? '임포트 중...' : '파일 선택 및 임포트'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importKoreanData() async {
    const title = '한국 데이터';
    try {
      setState(() {
        _isImporting = true;
        _status = '$title 파일 선택 중...';
        _progress = 0;
        _total = 0;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
      );

      if (result == null || result.files.isEmpty) {
        _showMessage('파일을 선택하지 않았습니다.');
        return;
      }

      final filePath = result.files.first.path;
      if (filePath == null) return;

      setState(() => _status = '$title 임포트 중...');

      // Parse and import Korean data
      final db = await _openGlobalProductDb();
      final importer = ProductDataImporter(db: db);
      final importResult = await importer.importKoreanProductsFromCsv(
        filePath,
        onProgress: (current, total) {
          setState(() {
            _progress = current;
            _total = total;
          });
        },
      );

      if (importResult.success) {
        _showMessage(
          '✓ $title 임포트 완료\n'
          '추가됨: ${importResult.inserted}\n'
          '스킵됨: ${importResult.skipped}',
        );
      } else {
        final error = importResult.errors.isNotEmpty
            ? importResult.errors.first
            : '알 수 없는 오류';
        _showMessage('✗ $title 임포트 실패: $error', isError: true);
      }
    } catch (e) {
      _showMessage('오류: $e', isError: true);
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _importUsData() async {
    const title = 'US 데이터';
    try {
      setState(() {
        _isImporting = true;
        _status = '$title 파일 선택 중...';
        _progress = 0;
        _total = 0;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        _showMessage('파일을 선택하지 않았습니다.');
        return;
      }

      final filePath = result.files.first.path;
      if (filePath == null) return;

      setState(() => _status = '$title 임포트 중... (대용량 파일 처리)');

      // Parse and import US data
      final db = await _openGlobalProductDb();
      final importer = UsProductImporter(db: db);
      final importResult = await importer.importUsProductsFromJson(filePath);

      if (importResult.success) {
        _showMessage(
          '✓ $title 임포트 완료\n'
          '추가됨: ${importResult.inserted}\n'
          '스킵됨: ${importResult.skipped}',
        );
      } else {
        final error = importResult.errors.isNotEmpty
            ? importResult.errors.first
            : '알 수 없는 오류';
        _showMessage('✗ $title 임포트 실패: $error', isError: true);
      }
    } catch (e) {
      _showMessage('오류: $e', isError: true);
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _importJapanData() async {
    const title = '일본 데이터';
    try {
      setState(() {
        _isImporting = true;
        _status = '$title 파일 선택 중... (CSV 형식)';
        _progress = 0;
        _total = 0;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        _showMessage(
          '파일을 선택하지 않았습니다.\n\n'
          '주의: Excel 파일을 CSV로 먼저 변환하세요.',
        );
        return;
      }

      final filePath = result.files.first.path;
      if (filePath == null) return;

      setState(() => _status = '$title 임포트 중...');

      // Parse and import Japan data
      final db = await _openGlobalProductDb();
      final importer = JapanProductImporter(db: db);
      final importResult = await importer.importJapaneseProductsFromCsv(
        filePath,
      );

      if (importResult.success) {
        _showMessage(
          '✓ $title 임포트 완료\n'
          '추가됨: ${importResult.inserted}\n'
          '스킵됨: ${importResult.skipped}',
        );
      } else {
        final error = importResult.errors.isNotEmpty
            ? importResult.errors.first
            : '알 수 없는 오류';
        _showMessage('✗ $title 임포트 실패: $error', isError: true);
      }
    } catch (e) {
      _showMessage('오류: $e', isError: true);
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _importAllData() async {
    // Sequential import: Korean → US → Japan
    await _importKoreanData();
    if (!mounted) return;

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    await _importUsData();
    if (!mounted) return;

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    await _importJapanData();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
