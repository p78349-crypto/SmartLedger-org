library background_settings_screen;

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/background_service.dart';
import '../theme/app_theme_seed_controller.dart';
import '../widgets/background_widget.dart';
import '../widgets/special_backgrounds.dart';

part 'background_settings_screen_helpers.dart';
part 'background_settings_screen_color_picker.dart';

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
