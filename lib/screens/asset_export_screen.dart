import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/asset_service.dart';
import '../utils/snackbar_utils.dart';

class AssetExportScreen extends StatefulWidget {
  final String accountName;
  const AssetExportScreen({super.key, required this.accountName});

  @override
  State<AssetExportScreen> createState() => _AssetExportScreenState();
}

class _AssetExportScreenState extends State<AssetExportScreen> {
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    // Start export automatically
    WidgetsBinding.instance.addPostFrameCallback((_) => _doExport());
  }

  Future<void> _doExport() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    
    try {
      final assets = AssetService().getAssets(widget.accountName);
      if (assets.isEmpty) {
        if (!mounted) return;
        SnackbarUtils.showInfo(context, '내보낼 자산이 없습니다');
        Navigator.pop(context);
        return;
      }

      final rows = [
        ['자산명', '카테고리', '현재가', '원가', '상세타입'],
        ...assets.map((a) => [
          a.name,
          a.category.toString().split('.').last,
          a.amount.toString(),
          a.costBasis?.toString() ?? '0',
          a.inputType.toString().split('.').last,
        ]),
      ];

      const csvConverter = ListToCsvConverter();
      final csv = csvConverter.convert(rows);

      final dir = await getDownloadsDirectory();
      if (dir == null) throw Exception('다운로드 디렉토리를 찾을 수 없습니다');

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = 'assets_${widget.accountName}_$timestamp.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv);

      if (!mounted) return;
      SnackbarUtils.showSuccess(context, 'CSV 파일이 저장되었습니다: ${file.path}');
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, '내보내기 실패: $e');
    } finally {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자산 내보내기')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('CSV 파일을 생성하는 중입니다...'),
          ],
        ),
      ),
    );
  }
}
