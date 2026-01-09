# Voice Assistant Data Access Policy (Bixby / Siri / Google)

**Purpose**
- Prevent sensitive data leakage via voice assistant channels.
- Keep voice control safe-by-default (navigation allowlist + state-change confirmation).

## 1) Core Principle
- **Allow only what is safe if externally exposed.**
  - Treat voice assistants as potentially *external* input/output surfaces.
  - Assume voice text/transcripts may be processed outside the app.

## 2) Allowed Scope (Default)
- **Navigation-only** actions via allowlisted deep links.
- **Prefill-only** parameters that do not reveal sensitive user data.
- **State-changing** actions must follow the **Preview → Confirm** model.
  - Auto-submit is only allowed with `autoSubmit=true&confirmed=true`.
  - If `autoSubmit=true` without `confirmed=true`, the app must require in-app confirmation.

## 3) Disallowed Scope (Default)
- Any voice command that:
  - Retrieves or speaks back sensitive personal/financial data.
  - Searches external content (web, email, contacts, calendar) and applies results inside the app.
  - Exports, shares, or transmits user data externally.

## 4) Data Minimization Rules
- Do not store:
  - Raw voice audio.
  - Raw assistant transcript (original text) unless explicitly required and approved.
- If logging is required, log only:
  - `route`, `intent`, safety flags (`autoSubmit`, `confirmed`), and coarse outcome (success/blocked/confirmed).
  - **Mask** or omit user-provided text fields by default.

## 5) Retention Guidance (No single universal standard)
Choose retention by *data class* and purpose:
- Operational/debug logs: **7–30 days**
- Security/audit logs (non-sensitive, minimal fields): **90–180 days** ("6 months" is a common choice)
- Analytics: aggregate/anonymous only; retention per analytics policy

## 6) Enforcement Points (SmartLedger)
- Deep link allowlist gate: `smartledger://nav/open?route=...`
- Preview → Confirm safety for state-changing commands
- Parameter allowlists (e.g., health tag allowlist)

## 7) Change Control
Any expansion of voice assistant capabilities that touches:
- data retrieval,
- sensitive fields,
- external search,
- or longer retention

must be documented and reviewed before shipping.
