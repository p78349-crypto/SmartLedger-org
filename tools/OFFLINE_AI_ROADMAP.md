# Offline AI Integration Roadmap (Summary)

This file summarizes the steps you provided and maps them to concrete tasks in this repo.

1. Planning & Prep (1w)
  - Audit app structure (UI, DB, storage)
  - Decide integration points: voice button -> STT -> NLU -> DB
  - Goal: keep app size <200MB and fully offline

2. Prototype AI Module (2-3w)
  - STT: Vosk (small Korean model ~50MB)
  - NLU: Rasa Lite or rule-based fallback
  - Prepare 100~200 example utterances for intents/entities
  - Local server: FastAPI (tools/offline_ai_server)

3. Flutter Integration (2-3w)
  - Add `VoiceInputButton` (lib/widgets/voice_input_button.dart)
  - Add `OfflineAiService` (lib/services/offline_ai_service.dart)
  - DB saving flow: when user confirms parsed result, map to Transaction and save (sqflite)

4. Testing & Optimize (2w)
  - Measure extraction accuracy (target 90% for amount/category/date)
  - Compress models and remove unused libs
  - Keep final app 150~180MB

5. Release Prep (1w)
  - Policy checks, privacy policy, build AAB/IPA, beta tests

6. Launch & Post-launch
  - Marketing ("Fully offline AI ledger")
  - Ongoing improvements: add more training data, UI tweaks

Notes
- Files added as prototype: tools/offline_ai_server, scripts/install_vosk_model.ps1, lib/service/widget stubs, assets/ai/README.md
- Next concrete tasks: integrate native STT (Vosk) per platform, add DB save flow, collect utterances, add CI test for offline server health
