import 'package:flutter/material.dart';
import '../services/offline_ai_service.dart';

class VoiceInputButton extends StatefulWidget {
  final OfflineAiService aiService;
  final void Function(Map<String, dynamic> parsed) onConfirmed;

  const VoiceInputButton({
    super.key,
    required this.aiService,
    required this.onConfirmed,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  bool _loading = false;

  // In a real integration this would trigger native STT and return text
  Future<void> _onTapSimulate() async {
    // For prototype: ask user for text via dialog
    final t = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('음성 입력 시뮬레이션'),
        content: const TextField(
          decoration: InputDecoration(hintText: '예: 점심 12000원'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('취소'),
          ),
        ],
      ),
    );
    if (!mounted || t == null || t.isEmpty) return;

    setState(() => _loading = true);
    try {
      final r = await widget.aiService.analyzeText(t);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('검증'),
          content: Text('인식결과: ${r.intent}\n${r.entities}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('저장'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (confirmed == true) {
        widget.onConfirmed(r.entities);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI 분석 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(_loading ? Icons.mic : Icons.mic_none),
      label: Text(_loading ? '분석중...' : '음성 입력'),
      onPressed: _loading ? null : _onTapSimulate,
    );
  }
}
