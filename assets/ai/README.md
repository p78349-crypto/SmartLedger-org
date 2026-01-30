Offline AI assets notes

- Vosk Korean models:
  - small models ~50MB, medium ~100MB
  - place under `tools/offline_ai_server/models/` for development

- Packaging considerations:
  - Android: consider using expansion files (OBB) or download at first run to avoid big APK sizes
  - iOS: consider on-demand resources or bundle only a tiny model

- STT integration approaches:
  - On-device native (Android/iOS) Vosk integration (JNI / Kotlin / Swift) and send recognized text to local server
  - Bundle a small Python server + Vosk inside app using a lightweight embed method (risky on iOS) — recommended: separate native STT wrapper
