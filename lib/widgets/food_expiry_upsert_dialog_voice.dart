part of 'food_expiry_upsert_dialog.dart';
// ignore_for_file: invalid_use_of_protected_member

extension FoodExpiryUpsertVoice on _FoodExpiryUpsertDialogState {
  Future<bool> _ensureSpeechReady() async {
    if (_speechInitAttempted) {
      return _speechAvailable;
    }
    _speechInitAttempted = true;

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('마이크 권한이 필요합니다')));
      }
      _speechAvailable = false;
      return false;
    }

    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            if (_voiceDraft.trim().isNotEmpty) {
              _applyVoiceInput(_voiceDraft);
            }
            setState(() {
              _isVoiceListening = false;
            });
          }
        },
        onError: (error) {
          debugPrint('FoodExpiryUpsert: speech error: $error');
          if (!mounted) return;
          setState(() {
            _isVoiceListening = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(content: Text('음성 인식 중 오류가 발생했습니다')),
          );
        },
      );
    } catch (e) {
      debugPrint('FoodExpiryUpsert: speech init error: $e');
      _speechAvailable = false;
    }
    return _speechAvailable;
  }

  Future<void> _toggleVoiceInput() async {
    if (_isVoiceListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() {
        _isVoiceListening = false;
      });
      return;
    }

    final ok = await _ensureSpeechReady();
    if (!ok) return;

    if (!mounted) return;
    setState(() {
      _isVoiceListening = true;
      _voiceDraft = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('말씀하세요… (예: 팽이버섯 2봉 냉장 내일)')),
    );

    await _speech.listen(
      localeId: 'ko_KR',
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _voiceDraft = result.recognizedWords;
        });
        if (result.finalResult) {
          _applyVoiceInput(result.recognizedWords);
          setState(() {
            _isVoiceListening = false;
          });
        }
      },
      listenOptions: stt.SpeechListenOptions(),
    );
  }

  void _applyVoiceInput(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;

    final parsed = _parseUpsertVoice(text);

    setState(() {
      if (parsed.name != null && parsed.name!.trim().isNotEmpty) {
        _nameController.text = parsed.name!;
      }
      if (parsed.quantityText != null &&
          parsed.quantityText!.trim().isNotEmpty) {
        _quantityController.text = parsed.quantityText!;
      }
      if (parsed.unit != null && parsed.unit!.trim().isNotEmpty) {
        _unitController.text = parsed.unit!;
      }
      if (parsed.location != null && _locations.contains(parsed.location)) {
        _location = parsed.location!;
      }
      if (parsed.category != null && _categories.contains(parsed.category)) {
        _category = parsed.category!;
      }
      if (parsed.expiryDate != null) {
        _pickedExpiryDate = parsed.expiryDate;
      }
      if (parsed.priceText != null && parsed.priceText!.trim().isNotEmpty) {
        _priceController.text = parsed.priceText!;
      }
      if (parsed.healthTags.isNotEmpty) {
        final next = <String>{..._healthTags};
        next.addAll(parsed.healthTags);
        _healthTags = next.toList();
      }
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('음성 입력 적용: $text')));
  }

  _UpsertVoiceParseResult _parseUpsertVoice(String input) {
    final raw = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    final lower = raw.toLowerCase();

    String? location;
    for (final l in _locations) {
      if (raw.contains(l)) {
        location = l;
        break;
      }
    }

    String? category;
    for (final c in _categories) {
      if (raw.contains(c)) {
        category = c;
        break;
      }
    }

    final healthTags = <String>{};
    for (final t in HealthGuardrailService.defaultTags) {
      if (raw.contains(t)) healthTags.add(t);
    }

    DateTime? expiry;
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    if (raw.contains('오늘')) {
      expiry = dateOnly;
    } else if (raw.contains('내일')) {
      expiry = dateOnly.add(const Duration(days: 1));
    } else if (raw.contains('모레')) {
      expiry = dateOnly.add(const Duration(days: 2));
    } else {
      final m = RegExp(r'(\d{1,3})\s*일\s*(후|뒤)').firstMatch(raw);
      if (m != null) {
        final days = int.tryParse(m.group(1) ?? '');
        if (days != null) {
          expiry = dateOnly.add(Duration(days: days));
        }
      } else {
        final md = RegExp(r'(\d{1,2})\s*월\s*(\d{1,2})\s*일').firstMatch(raw);
        if (md != null) {
          final month = int.tryParse(md.group(1) ?? '');
          final day = int.tryParse(md.group(2) ?? '');
          if (month != null && day != null) {
            var candidate = DateTime(dateOnly.year, month, day);
            if (candidate.isBefore(
              dateOnly.subtract(const Duration(days: 1)),
            )) {
              candidate = DateTime(dateOnly.year + 1, month, day);
            }
            expiry = candidate;
          }
        }
      }
    }

    String? qtyText;
    String? unit;
    const unitPattern =
        r'(개|봉지|봉|팩|통|단|모|장|판|박스|상자|병|캔|그램|그람|g|kg|킬로|킬로그램|ml|밀리리터|l|리터)';
    final qtyMatch = RegExp(
      r'(\d+(?:[\.,]\d+)?)\s*' + unitPattern,
    ).firstMatch(lower);
    if (qtyMatch != null) {
      qtyText = (qtyMatch.group(1) ?? '').replaceAll(',', '.');
      unit = _normalizeUnit(qtyMatch.group(2));
    }

    String? priceText;
    final priceMatch = RegExp(r'(\d{1,9})\s*원').firstMatch(raw);
    if (priceMatch != null) {
      priceText = priceMatch.group(1);
    }

    String candidateName = raw;
    for (final l in _locations) {
      candidateName = candidateName.replaceAll(l, ' ');
    }
    for (final c in _categories) {
      candidateName = candidateName.replaceAll(c, ' ');
    }
    for (final t in HealthGuardrailService.defaultTags) {
      candidateName = candidateName.replaceAll(t, ' ');
    }
    candidateName = candidateName
        .replaceAll(RegExp(r'(오늘|내일|모레|유통기한|기한|까지|후|뒤)'), ' ')
        .replaceAll(
          RegExp(r'(등록|추가|저장|입력|해줘|해주세요|할래|해|좀|우리집|식재료|생활용품|품목|재료)'),
          ' ',
        );
    candidateName = candidateName.replaceAll(RegExp(r'\d{1,9}\s*원'), ' ');
    candidateName = candidateName.replaceAll(
      RegExp(r'(\d{1,3})\s*일\s*(후|뒤)'),
      ' ',
    );
    candidateName = candidateName.replaceAll(
      RegExp(r'(\d{1,2})\s*월\s*(\d{1,2})\s*일'),
      ' ',
    );
    if (qtyMatch != null) {
      candidateName = candidateName.replaceAll(qtyMatch.group(0) ?? '', ' ');
    }
    candidateName = candidateName.replaceAll(RegExp(r'\s+'), ' ').trim();

    final name = candidateName.isEmpty ? null : candidateName;

    return _UpsertVoiceParseResult(
      name: name,
      quantityText: qtyText,
      unit: unit,
      location: location,
      category: category,
      expiryDate: expiry,
      priceText: priceText,
      healthTags: healthTags,
    );
  }

  String? _normalizeUnit(String? rawUnit) {
    if (rawUnit == null) return null;
    final u = rawUnit.trim().toLowerCase();
    switch (u) {
      case '봉지':
        return '봉';
      case '상자':
        return '박스';
      case '그램':
      case '그람':
        return 'g';
      case '킬로':
      case '킬로그램':
        return 'kg';
      case '밀리리터':
        return 'ml';
      case '리터':
      case 'l':
        return 'L';
      default:
        return rawUnit.trim();
    }
  }
}
