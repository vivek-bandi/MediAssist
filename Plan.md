# MediAssist AI Hackathon Prototype Plan

## Problem We Are Solving
- Large rural populations have limited access to timely, basic healthcare guidance.
- Internet access is unreliable, so cloud-only health apps fail in critical moments.
- Language barriers and typing-heavy UX reduce real-world usability.

## Hackathon Goal
Build a voice-first, offline-first healthcare guidance prototype that works on low-end smartphones and provides safe, basic symptom guidance in Telugu and English.

## Prototype Positioning
- MediAssist AI is a health guidance assistant, not a diagnosis tool.
- It helps users decide when to do self-care vs seek urgent medical help.
- It demonstrates practical accessibility: local language + simple voice interaction.

## Prototype Scope (In Scope)
- Voice and text symptom input.
- Telugu and English support.
- Offline rule-based symptom guidance.
- Red-flag detection and emergency escalation guidance.
- Text and voice output (TTS).
- Optional online enhancement (Gemini) when internet is available.
- Automatic fallback from online to offline mode.
- Basic medicine reminder flow (local reminder + voice alert).

## Out of Scope for Hackathon (Next Phase)
- Full 9-language support.
- Nearby health center discovery with live maps/data integration.
- Clinical-grade personalization and long-term care plans.
- Telemedicine or doctor appointment integration.

## Core Principles
- Offline-first by default.
- Safety over confidence.
- Voice-first and low-literacy friendly.
- Low memory and low compute footprint.
- Clear medical boundaries in every response.

## Runtime Modes
### Offline Mode (default)
- Uses local rule engine only.
- Works without internet.
- Prioritized for speed and reliability on low-end devices.

### Online Mode (optional)
- Uses Gemini for enriched explanation.
- Preserves the same safety constraints as offline mode.
- Falls back to offline mode on timeout, error, or connectivity drop.

## Symptom Guidance Flow
1. Capture user input (voice or text).
2. Detect/confirm language (Telugu or English).
3. Normalize phrases into symptom tags.
4. Check red flags first.
5. If red flag, immediately show escalation guidance.
6. If no red flag, generate guidance:
- Offline: deterministic rule response.
- Online: Gemini response with safety guardrails.
7. Localize response in selected language.
8. Deliver text plus voice playback.

## Safety Boundaries
- Always show disclaimer: guidance only, not diagnosis.
- Never give dosage-critical medication advice.
- Always escalate severe symptoms.
- Emergency triggers include:
- Chest pain.
- Breathing difficulty.
- Severe bleeding.
- Unconsciousness.
- Stroke-like symptoms.
- High-risk pregnancy danger signs.
- Infant danger signs.

## Language Plan for Prototype
- Production-ready prototype languages: Telugu and English.
- Design architecture to add more Indian languages after hackathon.
- Keep symptom ontology language-agnostic with mapped phrase dictionaries.

## Technical Blueprint
- App framework: Flutter (Android-first prototype).
- Speech-to-text: Vosk (offline local model).
- Text-to-speech: platform TTS abstraction.
- Rules engine: JSON/YAML-driven rule packs.
- Online adapter: Gemini wrapper with timeout and single-request fallback handling.
- Data storage: local history and reminder metadata.

## Repository Structure
- app/: mobile app code
- core/input/: voice/text ingestion
- core/nlp/: language detection and normalization
- core/rules/: offline rules and matching engine
- core/safety/: red-flag and policy enforcement
- core/online/: Gemini adapter and safety prompt contracts
- core/output/: formatter and TTS pipeline
- core/reminders/: local medicine reminder scheduler
- data/locales/: Telugu and English strings
- data/rules/: symptom and escalation rule packs
- docs/: architecture and safety policy

## Hackathon Deliverables
- Working Android demo app.
- Offline Telugu/English symptom guidance flow.
- Red-flag emergency escalation demo scenarios.
- Voice input and voice output demo.
- Online enhancement toggle with visible fallback behavior.
- Local medicine reminder demo.

## Non-Functional Targets (Prototype)
- Cold start under 3 seconds on low-end Android test device.
- Offline response under 1.5 seconds for common symptom prompts.
- Stable behavior under network loss during online mode.

## Privacy Baseline
- User data stored locally by default.
- Minimal cloud payload only in online mode.
- Clear user consent before enabling online AI.

## Hackathon Execution Plan
1. Foundation
- App shell, localization, mode indicator, core schemas.

2. Offline Safety Core
- Symptom rules, red-flag engine, deterministic guidance templates.

3. Voice Experience
- Vosk input pipeline, TTS output, confirmation prompts.

4. Online Enhancement
- Gemini adapter, safety middleware, failover handling.

5. Demo Readiness
- Scripted showcase flows, UI polish, backup offline demo path.

## Risks and Mitigations
- Noisy voice input:
- Add confirmation loops and quick edit before submit.
- Over-trust in AI output:
- Enforce strict safety templates and escalation-first logic.
- Device constraints:
- Use lightweight assets, lazy loading, bounded history.
- Language ambiguity:
- Expand phrase dictionaries iteratively from pilot utterances.

## Definition of Done (Hackathon Prototype)
- End-to-end Telugu/English voice and text guidance works offline.
- Red-flag escalation activates correctly in demo scenarios.
- Online mode enriches response and falls back safely to offline.
- Local medicine reminder can be created and announced by voice alert.
- Demo runs reliably on target low-end Android device.

## Implementation Status (Code Scan - 30 Mar 2026)
- [x] Flutter app shell and chat UI implemented.
- [x] Telugu and English language toggle implemented.
- [x] Offline symptom rules + red-flag detection implemented.
- [x] Offline-first guidance with clear safety disclaimer implemented.
- [x] Voice input (speech_to_text) integrated.
- [x] Voice output (flutter_tts) integrated.
- [x] Session history local storage implemented.
- [x] Online Gemini enhancement integrated with one request per submit.
- [x] Online failure/429 fallback to offline-safe guidance implemented.
- [ ] Local medicine reminder flow is not implemented yet.

## Known Runtime Constraint (Current)
- Gemini HTTP 429 is a provider quota/rate-limit response and can still occur even with correct app logic.
- Current code sends one online request per submit and falls back safely when 429 occurs.
- Remaining action is operational: rotate/restrict API key and increase quota/billing as needed.
