# AGENTS.md

## Project

Flutter mobile client for an Iranian dating app (Badoo-style). Package name: `dating_app`, Android namespace: `ir.bondi.app`.

## Quick Commands

```bash
flutter pub get                    # install dependencies
flutter gen-l10n                   # regenerate localization (after editing ARB files)
flutter run                        # debug run on connected device
flutter run -d chrome              # web preview (connected to deployed backend)
flutter analyze                    # static analysis (uses flutter_lints)
flutter build apk --release        # Android APK
flutter build appbundle --release  # Android App Bundle
```

## Environment Setup

1. Copy `.env.example` to `.env` (or create `.env` manually):
   ```
   API_BASE_URL=http://10.0.2.2:8000/api/v1
   WS_BASE_URL=ws://10.0.2.2:8000/api/v1
   GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
   ADMIN_SECRET_KEY=your_admin_key
   ```
2. Use `10.0.2.2` for Android emulator (not `localhost`). For physical device, use your machine's IP.
3. `.env` is loaded via `flutter_dotenv` in `main.dart` before `runApp()`. It's declared as an asset in `pubspec.yaml`.

## Architecture

- **State management:** Provider (`MultiProvider` in `main.dart`)
- **HTTP:** Dio with auth interceptor (auto-refresh on 401) + `dio_cache_interceptor` (Hive store)
- **Secure storage:** `flutter_secure_storage` for tokens (access/refresh/user_id)
- **Local storage:** `shared_preferences` for user profile, language, onboarding state
- **Localization:** ARB-based (`lib/l10n/app_en.arb`, `app_fa.arb`). Generated to `lib/generated/`. Access via `AppLocalizations.of(context)!`.

### Directory Layout

```
lib/
  main.dart              # Entry point — loads .env, inits ApiService, creates providers
  config/
    app_theme.dart       # Light + dark themes, text styles, button styles, color constants
    app_constants.dart   # API URLs from .env, timeout values, storage keys
  services/
    api_service.dart     # Singleton Dio instance with auth/cache/logging interceptors
    auth_service.dart    # Auth API calls (register, login, logout, Google)
    storage_service.dart # Token + user persistence (secure_storage + shared_preferences)
    discover_service.dart # Discover/swipe/limits API
    location_service.dart # GPS + location text APIs
    photo_service.dart   # Photo upload/management
    onboarding_service.dart # Onboarding API calls
    google_auth_service.dart # Google Sign-In
  providers/             # ChangeNotifiers — auth, onboarding, settings, language, profile, discover
  screens/               # UI organized by feature: auth/, onboarding/, profile/, discover/, chats/
  widgets/               # Reusable widgets (loading, shimmer, user_card, progress_bar)
  models/                # Data classes with fromJson/toJson
  l10n/                  # ARB source files (app_en.arb, app_fa.arb)
  generated/             # Auto-generated localization — DO NOT edit manually
```

## Key Patterns

### Token refresh
The Dio interceptor in `api_service.dart` automatically refreshes tokens on 401 responses. On refresh failure, tokens are cleared and the user must re-login.

### Auth flow
Registration is 3 steps: `registerInit` (email + code) → `registerVerify` (code + password) → `registerComplete` (profile data). Login is single-step `POST /auth/login`. Google Sign-In goes through `POST /auth/google`.

### Error handling
Providers return `bool` success/failure and set `_errorMessage`. Screens read `errorMessage` from the provider and display localized strings via `AppLocalizations`.

### Localization
After editing `app_en.arb` or `app_fa.arb`, run `flutter gen-l10n`. Keys must exist in both ARB files. Use `t.key_name` pattern where `t = AppLocalizations.of(context)!`.

### Dark mode
Toggled via `SettingsProvider.darkMode`, persisted to backend + local storage. Theme switches automatically through `MaterialApp.themeMode`. Access theme colors via `context.isDarkMode` extension in `app_theme.dart`.

## Backend

FastAPI server expected at the configured `API_BASE_URL`. Start with:
```bash
cd backend && uvicorn app.main:app --reload --port 8000
```
Health check: `GET /api/v1/auth/health` → `{"status":"healthy","redis":"connected"}`

## Android Build

- compileSdk: 37 (required by permission_handler_android), targetSdk: 36
- minSdk: `flutter.minSdkVersion`
- JVM: Java 17 (`sourceCompatibility`, `targetCompatibility`, `jvmTarget`)
- Google Services plugin applied (requires `google-services.json` in `android/app/`)
- Google Sign-In dependency: `com.google.android.gms:play-services-auth:20.7.0`

## Development Status

- Sessions 16–22 complete (auth, onboarding, photos, location, Google Sign-In, profile edit, settings, dark mode)
- Persian translations in progress (auth/onboarding/profile screens partially done)
- Next: Discover swiping (Session 23), Search (Session 23), Chat/WebSocket (Session 24), Likes/Matches (Session 24)

## Gotchas

- `pubspec.yaml` has `generate: true` — Flutter auto-runs gen-l10n on some builds. If you see stale translations, run `flutter gen-l10n` manually.
- The `generated/` directory is committed to git — do not delete it. It's regenerated from ARB files.
- `ApiService.init()` is async and must complete before any HTTP calls. It's called in `main()` before `runApp()`.
- The health check endpoint strips `/api/v1` from the base URL (`ApiService.healthCheck()`).
- Error strings in providers use both localized messages (via `AppLocalizations`) and some hardcoded English strings (e.g. `updateProfile`, `updateInterests`). Prefer localized strings for new code.
