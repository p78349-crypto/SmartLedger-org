import 'package:shared_preferences/shared_preferences.dart';

class BackgroundService {
  static const String _backgroundTypeKey = 'bg_type'; // 'color' or 'image'
  static const String _backgroundColorKey = 'bg_color'; // hex color
  static const String _backgroundImagePathKey = 'bg_image_path'; // file path
  static const String _backgroundBlurKey = 'bg_blur'; // blur effect

  // 기본값
  static const String defaultBackgroundColor = '#ffffff'; // 흰색

  // Get background type
  static Future<String> getBackgroundType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backgroundTypeKey) ?? 'color';
  }

  // Set background type
  static Future<void> setBackgroundType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundTypeKey, type);
  }

  // Get background color (hex)
  static Future<String> getBackgroundColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backgroundColorKey) ?? defaultBackgroundColor;
  }

  // Set background color (hex)
  static Future<void> setBackgroundColor(String hexColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundColorKey, hexColor);
  }

  // Get background image path
  static Future<String?> getBackgroundImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backgroundImagePathKey);
  }

  // Set background image path
  static Future<void> setBackgroundImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundImagePathKey, path);
  }

  // Get blur effect value
  static Future<double> getBackgroundBlur() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_backgroundBlurKey) ?? 0.0;
  }

  // Set blur effect value
  static Future<void> setBackgroundBlur(double blur) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_backgroundBlurKey, blur);
  }

  // Reset to default
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backgroundTypeKey);
    await prefs.remove(_backgroundColorKey);
    await prefs.remove(_backgroundImagePathKey);
    await prefs.remove(_backgroundBlurKey);
  }
}
