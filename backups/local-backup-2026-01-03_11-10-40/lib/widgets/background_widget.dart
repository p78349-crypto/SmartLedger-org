import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_ledger/services/background_service.dart';

/// 배경 설정을 가져와서 Scaffold의 backgroundColor로 사용할 수 있는 위젯
class BackgroundWidget extends StatefulWidget {
  final Widget child;
  final bool useBackgroundImage;

  const BackgroundWidget({
    super.key,
    required this.child,
    this.useBackgroundImage = true,
  });

  @override
  State<BackgroundWidget> createState() => _BackgroundWidgetState();
}

class _BackgroundWidgetState extends State<BackgroundWidget> {
  String _backgroundType = 'color';
  String? _backgroundImagePath;
  double _backgroundBlur = 0.0;
  Color _backgroundColor = Colors.white;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadBackgroundSettings();
  }

  Future<void> _loadBackgroundSettings() async {
    final type = await BackgroundService.getBackgroundType();
    final imagePath = await BackgroundService.getBackgroundImagePath();
    final blur = await BackgroundService.getBackgroundBlur();
    final colorHex = await BackgroundService.getBackgroundColor();

    if (mounted) {
      setState(() {
        _backgroundType = type;
        _backgroundImagePath = imagePath;
        _backgroundBlur = blur;
        _backgroundColor = _hexToColor(colorHex);
        _loaded = true;
      });
    }
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
    } else if (hexString.length == 8) {
      buffer.write(hexString.replaceFirst('#', ''));
    } else {
      return Colors.white;
    }
    return Color(int.tryParse(buffer.toString(), radix: 16) ?? 0xffffffff);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return widget.child;
    }

    if (!widget.useBackgroundImage ||
        _backgroundType == 'color' ||
        _backgroundImagePath == null) {
      return widget.child;
    }

    // 배경 이미지 사용
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.file(
            File(_backgroundImagePath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return SizedBox.expand(
                child: ColoredBox(color: _backgroundColor),
              );
            },
          ),
        ),
        // Blur effect
        if (_backgroundBlur > 0)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _backgroundBlur,
                sigmaY: _backgroundBlur,
              ),
              child: Container(color: Colors.transparent),
            ),
          ),
        // Semi-transparent overlay
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.3)),
        ),
        // Content
        widget.child,
      ],
    );
  }
}

/// 배경색/이미지를 가져오는 유틸리티
class BackgroundHelper {
  static final ValueNotifier<Color> _colorNotifier = ValueNotifier(
    Colors.white,
  );

  static ValueNotifier<Color> get colorNotifier => _colorNotifier;

  static Future<void> initialize() async {
    final color = await getBackgroundColor();
    _colorNotifier.value = color;
  }

  static Future<Color> getBackgroundColor() async {
    final type = await BackgroundService.getBackgroundType();
    if (type == 'color') {
      final colorHex = await BackgroundService.getBackgroundColor();
      return _hexToColor(colorHex);
    }
    return Colors.white;
  }

  static Future<void> refreshColor() async {
    final color = await getBackgroundColor();
    _colorNotifier.value = color;
  }

  static Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    final hex = hexString.replaceFirst('#', '');

    if (hex.length == 6) {
      buffer.write('ff');
      buffer.write(hex);
    } else if (hex.length == 8) {
      buffer.write(hex);
    } else {
      return Colors.white;
    }

    final value = int.tryParse(buffer.toString(), radix: 16);
    return Color(value ?? 0xffffffff);
  }
}
