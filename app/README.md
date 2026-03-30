# MediAssist App

Offline-first bilingual healthcare guidance prototype built with Flutter.

## Run

From this folder:

```bash
flutter pub get
flutter run -d chrome
```

For Android device:

```bash
flutter run -d <device_id>
```

## Runtime Modes

- `Offline`: deterministic local rule engine.
- `Online`: tries Groq (Llama 3.3 70B) enrichment and auto-falls back to offline-safe guidance.

## Groq Online Enrichment

Pass API key at run time:

```bash
flutter run -d chrome --dart-define=GROQ_API_KEY=your_api_key_here
```

If key is missing or API/network fails, the app remains functional with offline-safe output.
