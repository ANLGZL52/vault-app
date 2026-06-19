# vault

A new Flutter project.

## Vault AI

For the MVP, Vault calls OpenRouter directly from the Flutter client. Provide
the API key with `--dart-define` when running or building the app.

Debug:

```bash
flutter run --dart-define=OPENROUTER_API_KEY=sk-or-v1-xxxx
```

Release APK:

```bash
flutter build apk --release --dart-define=OPENROUTER_API_KEY=sk-or-v1-xxxx
```

Release AAB:

```bash
flutter build appbundle --release --dart-define=OPENROUTER_API_KEY=sk-or-v1-xxxx
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
