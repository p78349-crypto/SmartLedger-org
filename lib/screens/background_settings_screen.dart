import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_ledger/services/background_service.dart';
import 'package:smart_ledger/theme/app_theme_seed_controller.dart';
import 'package:smart_ledger/widgets/background_widget.dart';
import 'package:smart_ledger/widgets/special_backgrounds.dart';

class BackgroundSettingsScreen extends StatefulWidget {
  const BackgroundSettingsScreen({super.key});

  @override
  State<BackgroundSettingsScreen> createState() =>
      _BackgroundSettingsScreenState();
}

class _BackgroundSettingsScreenState extends State<BackgroundSettingsScreen> {
  String _backgroundType = 'color';
  String? _backgroundImagePath;
  double _backgroundBlur = 0.0;
  Color _backgroundColor = Colors.white;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final type = await BackgroundService.getBackgroundType();
    final imagePath = await BackgroundService.getBackgroundImagePath();
    final blur = await BackgroundService.getBackgroundBlur();
    final colorHex = await BackgroundService.getBackgroundColor();

    setState(() {
      _backgroundType = type;
      _backgroundImagePath = imagePath;
      _backgroundBlur = blur;
      _backgroundColor = _hexToColor(colorHex);
    });
  }

  Color _hexToColor(String hexString) {
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

  String _colorToHex(Color color) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2)}';
  }

  Future<void> _pickImage() async {
    // Check permissions first
    final photosStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;

    if (!photosStatus.isGranted && !storageStatus.isGranted) {
      final result = await [Permission.photos, Permission.storage].request();
      if (result[Permission.photos] != PermissionStatus.granted &&
          result[Permission.storage] != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지를 선택하려면 저장소 권한이 필요합니다.')),
          );
        }
        return;
      }
    }

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      await BackgroundService.setBackgroundImagePath(image.path);
      await BackgroundService.setBackgroundType('image');
      await BackgroundHelper.refreshAll();
      if (mounted) {
        _loadSettings();
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    // Camera permission check
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('카메라를 사용하려면 카메라 권한이 필요합니다.')),
          );
        }
        return;
      }
    }

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (image != null) {
      await BackgroundService.setBackgroundImagePath(image.path);
      await BackgroundService.setBackgroundType('image');
      await BackgroundHelper.refreshAll();
      if (mounted) {
        _loadSettings();
      }
    }
  }

  Future<void> _changeBackgroundColor() async {
    final result = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorPickerDialog(initialColor: _backgroundColor),
    );
    if (result != null) {
      final hexColor = _colorToHex(result);
      await BackgroundService.setBackgroundColor(hexColor);
      await BackgroundService.setBackgroundType('color');
      await BackgroundHelper.refreshColor();
      if (mounted) {
        _loadSettings();
      }
    }
  }

  Future<void> _resetBackground() async {
    await BackgroundService.reset();
    await BackgroundHelper.refreshColor();
    if (mounted) {
      _loadSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        BackgroundHelper.colorNotifier,
        BackgroundHelper.typeNotifier,
        BackgroundHelper.imagePathNotifier,
        BackgroundHelper.blurNotifier,
        AppThemeSeedController.instance.presetId,
      ]),
      builder: (context, _) {
        final bgColor = BackgroundHelper.colorNotifier.value;
        final bgType = BackgroundHelper.typeNotifier.value;
        final bgImagePath = BackgroundHelper.imagePathNotifier.value;
        final bgBlur = BackgroundHelper.blurNotifier.value;
        final presetId = AppThemeSeedController.instance.presetId.value;
        final theme = Theme.of(context);

        // In dark mode, if the background color is still the default white,
        // we should use the theme's scaffold background color instead.
        Color effectiveBgColor = bgColor;
        final isDefaultWhite =
            bgColor.toARGB32() == 0xFFFFFFFF ||
            bgColor.toARGB32() == 0xffffffff;

        if (theme.brightness == Brightness.dark && isDefaultWhite) {
          effectiveBgColor = theme.scaffoldBackgroundColor;
        }

        return Scaffold(
          backgroundColor: effectiveBgColor,
          extendBodyBehindAppBar: bgType == 'image' && bgImagePath != null,
          appBar: AppBar(
            title: const Text('배경 설정'),
            backgroundColor: bgType == 'image' && bgImagePath != null
                ? Colors.transparent
                : null,
            elevation: 0,
          ),
          body: Stack(
            children: [
              // 1. Base Background (Color or Image)
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    if (bgType == 'image' && bgImagePath != null) {
                      return Image.file(
                        File(bgImagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            ColoredBox(color: effectiveBgColor),
                      );
                    }

                    if (presetId == 'midnight_gold') {
                      return MidnightGoldBackground(
                        baseColor: effectiveBgColor,
                      );
                    } else if (presetId == 'starlight_navy') {
                      return StarlightNavyBackground(
                        baseColor: effectiveBgColor,
                      );
                    }
                    return ColoredBox(color: effectiveBgColor);
                  },
                ),
              ),

              // 2. Blur Effect (if image)
              if (bgType == 'image' && bgImagePath != null && bgBlur > 0)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: bgBlur, sigmaY: bgBlur),
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),

              // 3. Dark Overlay for images to ensure readability
              if (bgType == 'image' && bgImagePath != null)
                Positioned.fill(
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.2)),
                ),

              // 4. Content
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '배경 유형',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(label: Text('색상'), value: 'color'),
                        ButtonSegment(label: Text('이미지'), value: 'image'),
                      ],
                      selected: {_backgroundType},
                      onSelectionChanged: (Set<String> newSelection) async {
                        final type = newSelection.first;
                        await BackgroundService.setBackgroundType(type);
                        await BackgroundHelper.refreshAll();
                        if (mounted) {
                          _loadSettings();
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_backgroundType == 'color') ...[
                      Text(
                        '배경 색상',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                          title: const Text('색상 선택'),
                          subtitle: Text(_colorToHex(_backgroundColor)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _changeBackgroundColor,
                        ),
                      ),
                    ] else ...[
                      Text(
                        '배경 이미지',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_backgroundImagePath != null)
                        Card(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_backgroundImagePath!),
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.image),
                              label: const Text('갤러리'),
                              onPressed: _pickImage,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('카메라'),
                              onPressed: _pickImageFromCamera,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '블러 효과',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: _backgroundBlur,
                        max: 20,
                        divisions: 20,
                        label: _backgroundBlur.toStringAsFixed(1),
                        onChanged: (value) async {
                          setState(() {
                            _backgroundBlur = value;
                          });
                          await BackgroundService.setBackgroundBlur(value);
                          await BackgroundHelper.refreshAll();
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('기본값으로 재설정'),
                      onPressed: _resetBackground,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _hsv = HSVColor.fromColor(_selectedColor);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('색상 선택'),
      content: SizedBox(
        width: 300,
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _hsv = _hsv.withSaturation(
                      (details.localPosition.dx / 300).clamp(0, 1),
                    );
                    _hsv = _hsv.withValue(
                      1 - (details.localPosition.dy / 250).clamp(0, 1),
                    );
                    _selectedColor = _hsv.toColor();
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        HSVColor.fromAHSV(1, _hsv.hue, 0, 1).toColor(),
                        HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
                        HSVColor.fromAHSV(1, _hsv.hue, 1, 0).toColor(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _hsv.hue,
                    max: 360,
                    onChanged: (value) {
                      setState(() {
                        _hsv = _hsv.withHue(value);
                        _selectedColor = _hsv.toColor();
                      });
                    },
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text('적용'),
        ),
      ],
    );
  }
}
