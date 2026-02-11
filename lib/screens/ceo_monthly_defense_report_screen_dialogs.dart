// ignore_for_file: invalid_use_of_protected_member

part of 'ceo_monthly_defense_report_screen.dart';

extension CEOMonthlyDefenseDialogs
    on _CEOMonthlyDefenseReportScreenState {
  Future<void> _openTtsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    var rate = prefs.getDouble(PrefKeys.ttsSpeechRate) ?? 0.5;
    var pitch = prefs.getDouble(PrefKeys.ttsPitch) ?? 1.0;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              title: const Text('TTS 설정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('속도'),
                      Expanded(
                        child: Slider(
                          value: rate,
                          min: 0.1,
                          divisions: 9,
                          label: rate.toStringAsFixed(2),
                          onChanged: (v) => setLocalState(() => rate = v),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('톤'),
                      Expanded(
                        child: Slider(
                          value: pitch,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          label: pitch.toStringAsFixed(2),
                          onChanged: (v) => setLocalState(() => pitch = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await prefs.setDouble(PrefKeys.ttsSpeechRate, rate);
                    await prefs.setDouble(PrefKeys.ttsPitch, pitch);
                    if (!mounted || !ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    messenger?.showSnackBar(
                      const SnackBar(content: Text('TTS 설정 저장')),
                    );
                    await _applyTtsSettings();
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _copyReport(String text) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    messenger?.showSnackBar(const SnackBar(content: Text('보고서를 복사했습니다.')));
  }

  Future<void> _toggleSpeech(String reportText) async {
    if (_isSpeaking) {
      await _tts.stop();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }
    setState(() => _isSpeaking = true);
    await _applyTtsSettings();
    await _tts.speak(reportText);
    if (mounted) setState(() => _isSpeaking = false);
  }

  Future<void> _exportCsv(_ReportData data) async {
    final csvString = _encodeCsv(_buildCsvRows(data, _includeRoots));
    try {
      final file = await _writeTextFile(_fileStem(data.now), 'csv', csvString);
      await SharePlus.instance.share(
        ShareParams(
          text: '[TOP SECRET] 월간 자산 방어 전투 보고서 CSV',
          files: [XFile(file.path)],
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV 저장 및 공유 완료: ${file.path}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV 내보내기 실패: $e')));
    }
  }

  Future<void> _exportPdf(_ReportData data, String reportText) async {
    try {
      final bytes = await _buildPdfBytes(data, _includeRoots, reportText);
      final file = await _writeBinaryFile(_fileStem(data.now), 'pdf', bytes);
      await SharePlus.instance.share(
        ShareParams(
          text: '[TOP SECRET] 월간 자산 방어 전투 보고서 PDF',
          files: [XFile(file.path)],
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 저장 및 공유 완료: ${file.path}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 내보내기 실패: $e')));
    }
  }
}
