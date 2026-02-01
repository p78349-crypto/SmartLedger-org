// Build-time feature flags.
// To enable voice features at build-time use:
// flutter build apk --dart-define=ENABLE_VOICE=true

const bool kEnableVoice = bool.fromEnvironment('ENABLE_VOICE');
