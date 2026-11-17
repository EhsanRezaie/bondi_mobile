# Bondi — Flutter Mobile Client

Bondi is a Flutter client for a dating and social-discovery service. The app currently includes phone-number authentication, profile onboarding, discovery and search, chat, notifications, profile and privacy settings, account deletion, and support tickets.

This repository contains the client only. API behavior depends on a separately deployed backend; the Flutter client sources identify its routes but do not define the server contracts.

## Documentation

- [`docs/WIKI.md`](docs/WIKI.md) — technical guide to the app, architecture, configuration, and feature flows.
- [`docs/TODO.md`](docs/TODO.md) — traceable checklist of known follow-up work and verification needs.
- [`AGENTS.md`](AGENTS.md) — repository-specific development instructions.

## Requirements

- Flutter SDK and Dart SDK compatible with the constraints in `pubspec.yaml` (Dart `^3.12.2`).
- A reachable Bondi API backend.
- Android Studio/Xcode and platform tooling for native builds.

## Local setup

1. Install Flutter dependencies:

   ```bash
   flutter pub get
   ```

2. Create `.env` in the repository root. For an Android emulator talking to a backend on the host machine, start with:

   ```env
   API_BASE_URL=http://10.0.2.2:8000/api/v1
   WS_BASE_URL=ws://10.0.2.2:8000/api/v1
   GOOGLE_CLIENT_ID=
   ADMIN_SECRET_KEY=
   ```

   For a physical device, use a backend host address reachable from that device. Set `API_BASE_URL` and `WS_BASE_URL` to the corresponding HTTP and WebSocket base URLs. The app reads `.env` before startup; `.env` is ignored by Git.

3. Configure native Firebase services for push notifications and crash reporting as required by your environment. Android applies Google Services and Crashlytics plugins. Service configuration files may be required by the platform build and are environment-specific.

4. Run the client:

   ```bash
   flutter run
   ```

The application also has a web target, but features that rely on native camera, media, location, or push integrations may not be available there.

## Useful commands

```bash
flutter pub get
flutter gen-l10n                 # after editing localization ARB files
flutter analyze
flutter run
flutter run -d chrome
flutter build apk --release
flutter build appbundle --release
```

Tests are under `test/`. Before running tests, follow the repository's test-confirmation policy and use `./run_tests.sh` as required by local instructions.

## Feature areas

- Phone verification and account recovery/deletion flows.
- Profile onboarding with interests, prompts, location, and photos.
- Discovery cards, swipe actions, and daily-limit handling.
- Search with persisted filters and cursor-based pagination.
- Chats, messaging, read/delivery state, and a session WebSocket.
- Likes, matches, notifications, blocks, and reports.
- Profile editing, settings, themes, and English/Persian localization.
- Support tickets and legal pages.

See [`docs/WIKI.md`](docs/WIKI.md) for structure, state ownership, service responsibilities, persistence, platform notes, and key runtime flows.

## Backend and API

The client expects an API rooted at `/api/v1` by default. It calls authentication, user/profile, onboarding, location, discovery, search, photo, chat, notification, safety/reporting, ticket, and system/version-check routes. The detailed client-side endpoint inventory is in [`docs/WIKI.md`](docs/WIKI.md). The backend source and authoritative API schema are maintained separately.

For a local backend, consult its own setup instructions. The client health check targets `/health` after removing `/api/v1` from the configured API base URL:

```text
GET /api/v1/health
```

## Localization

English and Persian translations are stored in `lib/l10n/app_en.arb` and `lib/l10n/app_fa.arb`. Keep keys synchronized between both files and run `flutter gen-l10n` after changes. Generated localization sources are under `lib/generated/`; edit the ARB source files rather than generated Dart files.

## Android notes

- Application ID and namespace: `ir.bondi.app`.
- Android build configuration currently sets compile/target SDK 36 and Java/Kotlin target 17.
- The release build configuration currently uses the debug signing configuration. Configure production signing before publishing a release build.
- Firebase/Google Services configuration is needed for the corresponding integrations.

## Project status

Feature implementation is broader than the initial scaffold documentation described. The TODO file records only items observed in the current repository and explicit verification work; it is not a claim that every production or backend requirement is complete.
