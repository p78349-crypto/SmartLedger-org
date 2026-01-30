# Offline AI Server (Prototype)

Quick notes to run the local prototype server (FastAPI) for offline AI NLU/STT integration.

Prerequisites
- Python 3.10+
- pip

Recommended components
- STT: Vosk (offline, Korean model ~50-100 MB)
- NLU: small rule-based prototype or Rasa Lite when ready

How to run (dev)
1. Install deps: `pip install -r requirements.txt`
2. Download or place a Vosk model in `models/` (see scripts/install_vosk_model.ps1)
3. Start server: `uvicorn main:app --host 127.0.0.1 --port 8000`

API
- POST /analyze
  - body: {"text": "..."}
  - response: {"intent": "add_expense", "entities": {"amount": 12000, "date": "2026-01-12", "category": "식비", "memo": "점심"}}

Notes
- This is a prototype: implement the NLU bridging (Rasa/other) or keep rule-based for small vocab.
- For mobile bundling, place models in app assets (size considerations) or use expansion files (Android) or on-device storage.
- Consider process lifecycle (start/stop server with app) and permission/security implications.