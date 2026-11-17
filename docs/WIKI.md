# Bondi Project Wiki

## 1. Purpose and scope

Bondi is a Flutter application for a dating/social-discovery service, with English and Persian interfaces. This repository is the Flutter client. It communicates with a separately operated backend over HTTP and WebSocket; backend schemas, authorization rules, migrations, and deployment behavior are not defined by this repository.

The application package name is `dating_app`. Android uses application ID and namespace `ir.bondi.app`. The app title shown by `MaterialApp` is `AURA` in the current source, while localization and Android branding use Bondi. Confirm desired product naming before changing those values.

## 2. Technology and dependencies

- Flutter/Dart, with SDK constraint in `pubspec.yaml` (`sdk: ^3.12.2`).
- Provider (`ChangeNotifier`) for application and feature state.
- Dio for HTTP requests, interceptors, authentication, and cache integration.
- `dio_cache_interceptor` with Hive-backed cache on app startup.
- `flutter_secure_storage` for access/refresh tokens and user ID.
- `shared_preferences` for language, theme, filters, onboarding state, and notification-token bookkeeping.
- `web_socket_channel` and `stream_channel` for the persistent session socket.
- Firebase Core, Messaging, Crashlytics, and Analytics packages.
- Flutter local notifications for local notification display and routing.
- `image_picker`, `camera`, `record`, `just_audio`, and related media packages for photo, selfie, and audio flows.
- `geolocator` for location access; URL launcher for external links.
- ARB-based Flutter localization for English and Persian.

The complete dependency list and version constraints are in `pubspec.yaml`.

## 3. Repository layout

```text
lib/
  main.dart                     Startup, providers, app root, global error hooks
  config/                       API constants and theme
  generated/                    Generated localization Dart (do not edit manually)
  l10n/                         English/Persian ARB translation sources
  models/                       JSON-backed feature models
  providers/                    ChangeNotifier state holders
  screens/                      Feature screens, grouped by flow
  services/                     HTTP, storage, media, notification and socket work
  utils/                        Navigation, phone, responsive, media and formatting helpers
  widgets/                      Reusable presentation components
android/                        Android application and Gradle configuration
ios/                            iOS application and Xcode configuration
test/                           Unit and responsive/widget tests
docs/                           Project wiki and tracked TODO list
```

Important screen groups:

- `screens/auth/`: phone entry and verification.
- `screens/onboarding/`: basic information, profile details, interests, prompts, and photos.
- `screens/discover/` and `screens/search/`: profile discovery and filtered search.
- `screens/chats/`: chat list/detail, liked profiles, notifications, and notification destinations.
- `screens/profile/`: profile management, settings, privacy/safety, tickets, and account deletion.
- `screens/legal/`: legal text pages.
- `screens/shared/`: reusable screen-level profile loading/details.

## 4. Startup and application shell

`lib/main.dart` initializes Flutter bindings, installs Flutter and platform error handlers, and starts an asynchronous guarded zone. Startup loads `.env`, sets portrait orientation, initializes `ApiService`, and attempts Firebase, local-notification, and crash-reporting initialization. Firebase/notification bootstrap errors are caught so they do not necessarily prevent app startup.

The app creates these root providers in `MultiProvider`:

- `AuthProvider`
- `OnboardingProvider`
- `LanguageProvider`
- `SettingsProvider`
- `ChatProvider`
- `NotificationsProvider`
- `TicketProvider`

`AppView` wires logout teardown between `AuthProvider`, `NotificationsProvider`, and `ChatProvider`. The `MaterialApp` uses `SplashScreen` as its home, global navigator and crash-reporting observer, theme mode from `SettingsProvider`, locale from `LanguageProvider`, generated localizations, and a text-scale clamp of 1.0–1.3.

`SplashScreen` performs a system version check, then initializes auth. The version check fails open on network/parse errors. Depending on auth and profile/onboarding state, the user is routed to login, a resumable onboarding step, or `MainScreen`.

## 5. State management and navigation

Feature state is held in `ChangeNotifier` providers and exposed through Provider. Screens generally call providers/services from lifecycle callbacks and user actions, then render based on provider getters.

`MainScreen` has four bottom-navigation tabs: Search, Discover, Chats, and Profile. Tabs are created lazily and retained in an `IndexedStack` after first visit. Search and Discover each receive feature providers at the tab boundary. Profile creates a `ProfileProvider`. Chat and notification providers are root-scoped.

`lib/utils/global_navigator.dart` supplies the global navigator key used by session-expiry and notification routing paths. Notification taps can route to chat or a user/profile destination based on payload data.

## 6. Services and network layer

### 6.1 API configuration

`AppConstants` reads these values from `flutter_dotenv`:

| Variable | Use | Fallback in source |
|---|---|---|
| `API_BASE_URL` | Dio API base URL | `http://localhost:8000/api/v1` |
| `WS_BASE_URL` | WebSocket base URL | `ws://localhost:8000/api/v1` |
| `GOOGLE_CLIENT_ID` | Google client ID accessor | Empty string |
| `ADMIN_SECRET_KEY` | Admin-secret accessor | Empty string |

`.env.example` currently documents `API_BASE_URL`, `WS_BASE_URL`, `WEB_CLIENT_ID`, and `ADMIN_SECRET_KEY`; the code accessor is named `GOOGLE_CLIENT_ID`. Treat that naming difference as a configuration item to verify when using Google sign-in.

For Android emulator development, `.env.example` uses `10.0.2.2` to reach a host-machine backend. On a physical device, use an address reachable from the device. Production deployments should use secure HTTPS/WSS endpoints.

### 6.2 `ApiService`

`lib/services/api_service.dart` owns a static Dio instance. It configures the API base URL, 30-second connection timeout, 90-second receive timeout, JSON content type, an auth/refresh interceptor, cache interceptor, and debug-only request/response logging.

The request interceptor reads `access_token` from secure storage and adds a Bearer authorization header. The error interceptor handles HTTP 401 responses, avoids refreshing a refresh request, and uses a single-flight refresh future so concurrent unauthorized requests do not concurrently rotate the same refresh token. A successful refresh stores returned access and refresh tokens and retries the original request. On refresh failure or missing tokens, it clears secure storage and calls `onSessionExpired`.

The default cache policy is `noCache`; specific GET requests opt in via `CacheOptions`. Cache storage is Hive-backed in app startup, and the class exposes in-memory test initialization seams. `healthCheck()` removes `/api/v1` from the configured base URL and requests `/health`.

### 6.3 Service responsibilities

| Service | Responsibility |
|---|---|
| `auth_service.dart` | Phone verification, auth/session operations, user profile and account operations |
| `onboarding_service.dart` | Interest and prompt catalogs |
| `discover_service.dart` | Discovery profiles, swipes, first-message flow, and discovery limits |
| `search_service.dart` | Filtered profile search |
| `chat_service.dart` | Matches/chats/messages, likes, notification APIs, moderation, daily limits, and public profiles |
| `photo_service.dart` | Profile photos and selfie/identity verification operations |
| `location_service.dart` | Permission/current position, reverse geocode, country/province/city lookup |
| `ticket_service.dart` | Support ticket creation, retrieval, and replies |
| `system_service.dart` | Version/maintenance gate check |
| `session_socket_service.dart` | Persistent authenticated WebSocket and realtime frames |
| `push_service.dart` | FCM permission/token registration and message handlers |
| `local_notifications.dart` | Local notification initialization, display, launch/tap routing |
| `storage_service.dart` | Secure tokens and shared user/onboarding data |
| `crash_reporting.dart` | Crash reporting integration and navigation observer |

Service methods commonly return Dio `Response` values, converting response-bearing `DioException`s into their response so providers can inspect status codes. Network failures without an HTTP response are generally rethrown or mapped by feature code.

### 6.4 Client endpoint inventory

Routes below are observed in client service calls. They are relative to the configured API base URL; request and response contracts are owned by the backend.

**Authentication and user profile**

- `GET /health` (the health-check Dio uses a base URL with `/api/v1` stripped).
- `POST /auth/request-code`
- `POST /auth/verify-code`
- `POST /auth/register/complete`
- `POST /auth/refresh`, `POST /auth/logout`
- `GET /users/me`, `PUT /users/me`, `PUT /users/me/interests`, `PUT /users/me/settings`, `PUT /users/me/prompts`, `POST /users/me/delete-code`.
- Referral routes: `POST /referrals/claim`, `GET /referrals/my-code`, `GET /referrals/stats`.
- Photo operations include `/users/me/photos`, `/users/me/photos/{photo_id}/main`, `/users/me/photos/{photo_id}/crop`, `/users/me/photos/order`, and verification at `/users/me/verify` and `/users/me/verify/status`.
- Public profiles use `GET /users/{user_id}`.

**Onboarding and location**

- `GET /interests`, `GET /prompts`
- Location routes include `GET /locations/reverse-geocode`, `/locations/countries`, `/locations/states`, `/locations/cities`, `/locations/cities/search`, `/locations/city-centroid`, `POST /locations/clear-cache`, and user location routes under `/users/me/location` and `/locations/me/location-manual`.

**Discovery and search**

- `GET /discover`, `POST /swipes`
- `GET /search` with age, gender, location, body/lifestyle, language, interests, photo/verification, sorting, and pagination filters.
- Discovery and search providers use cursor data when supplied by the backend.

**Chat, notifications, and safety**

- Chat routes include `/matches`, `/chats`, `/messages`, `/swipes/likers`, `/swipes/liked`, `/blocks`, and `/reports`.
- Message operations include history, text/photo/voice send, edit/delete/forward, accept-chat, delivery/read state, and status retrieval.
- Notification routes include `GET /notifications`, `POST /notifications/read`, `DELETE /notifications/{id}`, `GET /notifications/counts`, and device-token registration/removal under `/notifications/device-token`.
- The session WebSocket connects to `/ws/stream` and sends subscribe/unsubscribe, typing, read-receipt, and heartbeat frames.

**Other**

- `GET /rewards/my-limits`
- Ticket routes under `/tickets`.
- `POST /system/version-check`.

For exact request fields and response types, use the service call implementations and the backend's API schema; this wiki does not infer undocumented backend behavior.

## 7. Authentication and session lifecycle

The current primary sign-in path is phone-number verification:

1. The user enters a phone number; the app requests a verification code.
2. The user submits the code; `AuthProvider.verifyCode` calls the verify endpoint.
3. On success, access token, refresh token, and user ID are stored in secure storage, and the parsed user is held in memory.
4. New or incomplete users are sent through onboarding; complete users enter the main app.

At startup, `AuthProvider.initializeApp` checks backend health and whether an access token exists. It validates the current user. Explicit 401/403 indicates an invalid session; network/timeouts and other failures retain the session and fall back to cached user data when available.

On token-refresh failure, `ApiService` clears secure storage and calls the app callback. `AuthProvider.clearSessionLocally` tears down push/socket state, clears local auth fields, and the callback routes to login. User logout also attempts backend logout and clears local session data.

## 8. Onboarding and local persistence

`OnboardingProvider` stores multi-step form state and associates saved onboarding state with a user ID. It supports restoring state and resuming a step. Onboarding fields include personal information, lifestyle attributes, location, interests, prompts, and photo/selfie progress; refer to the provider and onboarding screens for the current field set.

`StorageService` writes access token, refresh token, and user ID to secure storage. User JSON and onboarding progress use SharedPreferences. Language, discovery/search filters, theme preference, FCM registration bookkeeping, and some UI notices are also persisted locally.

## 9. Feature providers

| Provider | Main responsibilities |
|---|---|
| `AuthProvider` | Startup auth, phone-code flow, onboarding completion, account state, logout/deletion |
| `OnboardingProvider` | Onboarding form values, user-scoped persistence, resume state |
| `DiscoverProvider` | Discovery filters/results, paging, swipe actions, daily limits |
| `SearchProvider` | Advanced search filters/results, persisted filters, paging, likes/chat initiation |
| `ChatProvider` | Matches/chats, message history and mutations, socket lifecycle and events |
| `NotificationsProvider` | Notification lists, per-type pagination, unread counts, socket updates |
| `ProfileProvider` | User photo list and optimistic photo order/main-photo state |
| `SettingsProvider` | Theme, account visibility, notification settings and API synchronization |
| `LanguageProvider` | Locale selection and persistence |
| `TicketProvider` | Support ticket list/detail/create/reply state |

## 10. Realtime and push notifications

`SessionSocketService` maintains one authenticated `/ws/stream` connection. It reads a token from its provider on connect/reconnect, starts a heartbeat, exposes event and connection-state streams, and retries with bounded exponential backoff. It queues selected outbound frames while disconnected and flushes them when connected. `ChatProvider` owns the socket and subscriptions; notifications can subscribe to the chat provider's event stream.

`PushService` initializes Firebase Messaging, requests notification permission, obtains an FCM token, and registers it through the backend when an access token is available. On Android, `LocalNotifications` creates channels and handles local notifications including data-only messages. Notification payload taps are routed using the global navigator.

Firebase initialization and platform credentials must be configured for each target. Verify platform-specific notification delivery and token removal/rotation behavior against the backend before release.

## 11. Media, location, and platform notes

- Profile photos are uploaded as multipart data through `PhotoService`.
- Selfie verification uses camera and face-detection dependencies; verify platform permissions and native SDK setup for each release target.
- Audio messages use recording/playback dependencies and are represented in chat flows.
- Location access is requested through Geolocator and location lookup is delegated to backend routes.
- `media_url.dart` handles localhost media URLs and Android emulator mapping.
- Android manifest declares Internet, notifications, location, and camera permissions/features.
- The inspected iOS `Info.plist` declares camera use and remote-notification background mode. Check platform permission declarations against enabled flows when modifying location/media features.
- The app includes web-related conditionals, but `dart:io`-dependent media code means that not every feature is necessarily web-compatible.

## 12. Localization and theming

The source translation files are `lib/l10n/app_en.arb` and `lib/l10n/app_fa.arb`. Generated classes are in `lib/generated/`. Call `flutter gen-l10n` after editing ARB sources; do not hand-edit generated localization Dart.

`LanguageProvider` persists the selected language. `AppTheme` provides light and dark theme construction, including Persian font selection. `SettingsProvider` persists the user's dark-mode choice; the current default is dark mode unless a local choice has been stored.

## 13. Tests and quality checks

`test/` contains unit tests for providers, models, utilities, and responsive/widget layouts. `analysis_options.yaml` includes `flutter_lints`.

Useful commands:

```bash
flutter analyze
flutter gen-l10n
./run_tests.sh
```

Repository-specific policy requires confirmation before tests are run. Do not run an alternative test command when local instructions specify `./run_tests.sh`.

## 14. Build and release

Typical commands:

```bash
flutter build apk --release
flutter build appbundle --release
```

Current Android configuration uses application ID `ir.bondi.app`, compile/target SDK 36, Java 17, Google Services and Crashlytics plugins, and debug signing for the release build type. Debug signing is not suitable for a production store release. Configure production signing, app identifiers/versioning, Firebase files, secrets, backend URLs, and platform permission strings before distribution.

## 15. Security and operational considerations

- Keep `.env`, signing material, Firebase service files, and credentials out of version control unless repository policy explicitly requires sanitized templates.
- The app logs request/response bodies through Dio's `LogInterceptor` in debug mode. Avoid placing sensitive data in development logs and ensure release builds do not enable verbose logging.
- WebSocket authentication is currently passed as a `token` query parameter. Verify server/proxy access-log handling and transport security for deployed environments.
- Use HTTPS/WSS for production API/WebSocket traffic.
- Treat backend validation, authorization, data deletion, moderation, and privacy requirements as authoritative server responsibilities; verify them end-to-end.

## 16. Known follow-up items

See [`TODO.md`](TODO.md). Items currently observed in source include incomplete premium/subscription button actions and release-readiness verification around configuration, permissions, Firebase, and signing. Additional work should be added with a stable ID and acceptance criteria so progress can be tracked.
