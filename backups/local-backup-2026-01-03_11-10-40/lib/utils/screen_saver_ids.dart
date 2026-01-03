/// Screen saver shortcut icon identifiers & placement rules.
///
/// Keeping these in utils makes them shareable across UI surfaces.
class ScreenSaverIds {
  const ScreenSaverIds._();

  /// Main-page icon id for launching the in-app screen saver on demand.
  static const String shortcutIconId = 'shortcut_in_app_screen_saver';

  /// Only placeable on main page 1 (0-based index 0).
  static const int shortcutAllowedMainPageIndex = 0;
}
