/// Development-only overrides.
///
/// Compile-time flag to bypass asset/root security gates.
///
/// Safe-by-default:
/// - Defaults to `false`.
/// - Forced to `false` in release builds.
///
/// Enable only for local prototyping/testing:
/// `flutter run --dart-define=SL_DEV_BYPASS_SECURITY=true`
///
/// **DO NOT** ship with this enabled.
library dev_overrides;
import 'package:flutter/foundation.dart' show kReleaseMode;

const bool kDevBypassSecurity =
	kReleaseMode
		? false
		: bool.fromEnvironment('SL_DEV_BYPASS_SECURITY');
