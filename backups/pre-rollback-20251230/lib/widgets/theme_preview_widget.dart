import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_ledger/services/theme_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/device_utils.dart';
import 'package:smart_ledger/utils/theme_presets.dart';

enum ApplyScope { icons, wallpaper, both }

class ThemePreviewWidget extends StatefulWidget {
  const ThemePreviewWidget({super.key});

  @override
  State<ThemePreviewWidget> createState() => _ThemePreviewWidgetState();
}

class _ThemePreviewWidgetState extends State<ThemePreviewWidget> {
  ApplyScope _scope = ApplyScope.both;
  bool _allowLocalWallpaper = true; // default until checked
  bool _checkingDevice = true;

  @override
  void initState() {
    super.initState();
    _checkDeviceSupport();
  }

  Future<void> _checkDeviceSupport() async {
    // Android 13 (SDK 33) and above are allowed; others disabled by default
    final ok = await isAndroidSdkAtLeast(33);
    if (!mounted) return;
    setState(() {
      _allowLocalWallpaper = ok;
      _checkingDevice = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Theme preview', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),

          // Variant selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ThemeVariant.all.map((v) => _variantButton(context, v)).toList(),
            ),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              _buildIconCard('assets/icons/custom/sample_icon_circle.svg'),
              const SizedBox(width: 12),
              _buildIconCard('assets/icons/custom/sample_icon_star.svg'),
              const SizedBox(width: 12),
              _buildIconCard('assets/icons/custom/sample_icon_spark.svg'),
            ],
          ),
          const SizedBox(height: 18),
          Text('Background preview', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),

          // live background preview reacts to ThemeService
          AnimatedBuilder(
            animation: ThemeService.instance,
            builder: (context, _) {
              final appliedWallpaper = ThemeService.instance.appliedWallpaper;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FutureBuilder<String>(
                      future: ThemeService.instance.wallpaperForCurrent(),
                      builder: (context, snapshot) {
                        final path = snapshot.data;
                        if (path == null) {
                          return const SizedBox.shrink();
                        }
                        // If path is an asset (starts with assets/), use Image.asset
                        if (path.startsWith('assets/')) {
                          return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(path, fit: BoxFit.cover));
                        }
                        // Otherwise treat as file path
                        return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(path), fit: BoxFit.cover));
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Applied wallpaper: ${appliedWallpaper?.name ?? 'Default'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Text('Wallpaper: '),
              const SizedBox(width: 8),
              if (_checkingDevice)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_allowLocalWallpaper)
                ElevatedButton(
                  onPressed: () async {
                    // Pick an image from gallery, process & apply as local wallpaper
                    final picker = ImagePicker();
                    final x = await picker.pickImage(source: ImageSource.gallery);
                    if (x == null) return;
                    final f = File(x.path);
                    await ThemeService.instance.applyLocalWallpaperFile(f);
                  },
                  child: const Text('Select from gallery'),
                )
              else
                const Text('Local photos disabled on this device for stability'),
            ],
          ),

          // Presets controls + Apply / Cancel + scope selector
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  // Save current preview as preset
                  final pv = ThemeService.instance.current;
                  final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
                  await UserPrefService.setThemePreset(id: id, data: pv.toJson());
                },
                child: const Text('Save preset'),
              ),
              const SizedBox(width: 8),
              FutureBuilder<Map<String, Map<String, dynamic>>>(
                future: UserPrefService.getThemePresets(),
                builder: (context, snap) {
                  final presets = snap.data ?? {};
                  if (presets.isEmpty) return const SizedBox.shrink();
                  return DropdownButton<String>(
                    hint: const Text('Load preset'),
                    onChanged: (id) async {
                      if (id == null) return;
                      final data = presets[id]!;
                      final v = ThemeVariant.fromJson(data);
                      ThemeService.instance.preview(v);
                    },
                    items: presets.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                  );
                },
              ),
              const SizedBox(width: 12),
              DropdownButton<ApplyScope>(
                value: _scope,
                items: const [
                  DropdownMenuItem(value: ApplyScope.icons, child: Text('Icons only')),
                  DropdownMenuItem(value: ApplyScope.wallpaper, child: Text('Wallpaper only')),
                  DropdownMenuItem(value: ApplyScope.both, child: Text('Both')),
                ],
                onChanged: (v) => setState(() => _scope = v ?? ApplyScope.both),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => ThemeService.instance.applyPreview(
                  applyIcons: _scope != ApplyScope.wallpaper,
                  applyWallpaper: _scope != ApplyScope.icons,
                ),
                child: const Text('Apply'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: ThemeService.instance.resetPreview,
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconCard(String asset) {
    return SizedBox(
      width: 96,
      height: 112,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: ThemeService.instance,
            builder: (context, _) {
              final current = ThemeService.instance.current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: current.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0,2))],
                ),
                child: Center(
                  child: SvgPicture.asset(asset, width: 44, height: 44, color: current.onColor),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text('Sample', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }



  Widget _variantButton(BuildContext context, ThemeVariant v) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          ThemeService.instance.preview(v);
        },
        child: AnimatedBuilder(
          animation: ThemeService.instance,
          builder: (context, _) {
            final current = ThemeService.instance.current;
            final isSelected = current.id == v.id;
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: v.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Image.asset(ThemeService.instance.wallpaperAssetFor(v), fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 6),
                  Text(v.name, style: TextStyle(color: v.onColor, fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

