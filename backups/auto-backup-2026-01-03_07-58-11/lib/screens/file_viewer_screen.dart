import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileViewerScreen extends StatefulWidget {
  const FileViewerScreen({super.key});

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  String? _filePath;
  String? _fileName;

  bool _isLoading = false;
  String? _error;
  String? _content;
  bool _isPrettyJson = false;

  Future<void> _pickAndOpenFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _content = null;
      _isPrettyJson = false;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json', 'txt'],
        withData: false,
      );

      if (!mounted) return;

      final file = result?.files.single;
      final path = file?.path;
      if (path == null || path.trim().isEmpty) {
        setState(() {
          _isLoading = false;
          _error = '파일을 선택하지 않았습니다.';
        });
        return;
      }

      final raw = await File(path).readAsString();
      if (!mounted) return;

      String content = raw;
      bool pretty = false;
      if (path.toLowerCase().endsWith('.json')) {
        try {
          final decoded = jsonDecode(raw);
          content = const JsonEncoder.withIndent('  ').convert(decoded);
          pretty = true;
        } catch (_) {
          // Keep raw.
        }
      }

      setState(() {
        _isLoading = false;
        _filePath = path;
        _fileName = file?.name ?? path.split(Platform.pathSeparator).last;
        _content = content;
        _isPrettyJson = pretty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '파일을 여는 중 오류가 발생했습니다: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('파일 문서 열람'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: '파일 선택',
            onPressed: _isLoading ? null : _pickAndOpenFile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : _content == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '백업 파일(.json) 같은 문서를 앱에서 열람할 수 있습니다.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _pickAndOpenFile,
                    child: const Text('파일 선택'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '지원: .json / .txt',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fileName ?? '선택된 파일',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (_filePath != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _filePath!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (_isPrettyJson) ...[
                    const SizedBox(height: 6),
                    Text(
                      'JSON 보기 좋게 정리됨',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          _content!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

