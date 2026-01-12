part of background_settings_screen;

extension BackgroundSettingsHelpers on _BackgroundSettingsScreenState {
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    final hex = hexString.replaceFirst('#', '');

    if (hex.length == 6) {
      buffer
        ..write('ff')
        ..write(hex);
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
    final photosStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;

    if (!photosStatus.isGranted && !storageStatus.isGranted) {
      final result = await [Permission.photos, Permission.storage].request();
      final photosGranted =
          result[Permission.photos] == PermissionStatus.granted;
      final storageGranted =
          result[Permission.storage] == PermissionStatus.granted;
      if (!photosGranted && !storageGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미지를 선택하려면 저장소 권한이 필요합니다.'),
            ),
          );
        }
        return;
      }
    }

    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
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
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('카메라를 사용하려면 카메라 권한이 필요합니다.'),
            ),
          );
        }
        return;
      }
    }

    final image = await _imagePicker.pickImage(source: ImageSource.camera);
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
      builder: (context) => _ColorPickerDialog(
        initialColor: _backgroundColor,
      ),
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
}
