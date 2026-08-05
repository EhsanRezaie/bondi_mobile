# Bondi (`dating_app`) — Flutter Testing Plan

> Location: `~/Desktop/project_d_mobile/bondi-flutter-testing-plan.md`
> Status legend: `[ ]` = not started · `[~]` = in progress · `[x]` = done
> Update the checkboxes as work progresses to trace the tasks.
> Backend is already fully covered. This is the client-side plan only.

---

## 0. Reality check — what the generic draft got wrong

This plan was rewritten after reading the actual `project_d_mobile` codebase. The original blueprint assumed a stack that does not exist here:

| Assumption in original draft | Reality in this repo |
|---|---|
| Bloc/Riverpod state management | **Provider + ChangeNotifier** — 8 providers registered in `MultiProvider` (`lib/main.dart:58-70`): `AuthProvider`, `OnboardingProvider`, `LanguageProvider`, `SettingsProvider`, `ChatProvider` (+ `DiscoverProvider`, `SearchProvider`, `ProfileProvider` created per-screen or not in `main`). Tests target ChangeNotifier state, **not** reducers. |
| "Mock at the repository/service layer — keep data layer as a swappable abstraction" | **No repository layer exists.** Every service is a **static** class (`ChatService`, `DiscoverService`, `SearchService`, `AuthService`, `PhotoService`, `OnboardingService`, `LocationService`) calling static `ApiService.get/post/put/patch/delete/upload` which wraps a **static singleton `Dio`** (`lib/services/api_service.dart:11-13`). Providers reference services directly (`ChatService.getConversations()` etc.) and instantiate `StorageService()` as a hard field (`chat_provider.dart:32`, `auth_provider.dart:12`). Nothing is injectable today. |
| Iranian phone number validator + OTP digit boxes | No phone validator. Real validators in `lib/utils/validators.dart`: `validateEmail`, `validatePassword`, `validateName`, `validateAge` (pure static — ideal unit targets). OTP screen **does** use per-digit `FocusNode`s (`lib/screens/auth/verify_code_screen.dart:33-105`) — matches the widget-test example. |
| "Formatters" to unit test (last seen, distance) | Formatting is **inline in widgets**: last-seen relative text at `lib/widgets/online_indicator.dart:49-66`; distance label at `lib/screens/discover/discover_screen.dart:735-737, 939-943`. No formatter utils exist → must be extracted first. |
| `test/`, `integration_test/`, mocktail, patrol, GitLab CI | **None exist.** Only `flutter_test` + `flutter_lints` in dev_dependencies (`pubspec.yaml:61-70`). The backend repo uses **GitHub Actions** (`.github/workflows/deploy.yml`), and this app is a separate GitHub repo → use **GitHub Actions**, not GitLab. |
| Golden "Quiet Luxury" tokens (Inter/Navy/white) | Design tokens live in `lib/config/app_theme.dart` (`AppTheme.lightTheme/darkTheme`, `darkPrimary/lightPrimary`, `darkSurface/lightSurface`, …). `Inter` font comes from **`google_fonts`** (runtime fetch) — goldens need a deterministic font strategy (default test font is "Ahem"). |

### Decided approach (confirmed with owner)

1. **Widget-test seam = HTTP mock adapter** (`http_mock_adapter` over `ApiService`'s Dio), **not** a constructor-injection refactor. Keeps prod services/providers as-is; adds a tiny transport override.
2. **CI = GitHub Actions** in this repo (mirrors the backend repo), with unit+widget on push and E2E on a nightly schedule.
3. **Minimal production seams** are acceptable (they are small and non-breaking).

### Existing good unit-test targets (already testable, zero refactor)

- `lib/models/*` — `Message`, `Match`, `SwipeUser`, `DiscoverProfile`, `User`, `Photo`, `Interest`, `Prompt`, `Location`, `ProfileStats` — all pure Dart `fromJson`/`toJson`.
- `lib/utils/validators.dart` — pure static validation functions.
- `lib/services/chat_websocket_service.dart` — an **instance** class (only needs a channel seam to be isolated).

---

## 1. Test pyramid target

```
        ▲
       /E2E\        5–8 critical flows (patrol) — nightly only
      /------\
     /Widget  \     one per screen + shared components (auth/discover/profile/chats/settings)
    /----------\
   / Unit tests \    validators, models, formatters, websocket service
  /--------------\
```

Coverage bar (realistic, not 100%):
- Every screen has **at least one** widget test.
- All validators + all models have unit tests.
- The 5 critical flows have E2E coverage.
- Let production bug reports guide later additions (Phase 8).

---

## 2. STEP 0 — Scaffolding + minimal production seams (do this first)

### 2.1 Dependencies (`pubspec.yaml` → `dev_dependencies`)
- [x] `mocktail: ^1.0.x` — mocking without code generation (Feels like Python's `unittest.mock`).
- [x] `http_mock_adapter: ^0.6.x` — mock Dio routes on a real `Dio` instance; lets the real providers + services run against fake HTTP.
- [x] `golden_toolkit: ^0.15.x` — golden-file helpers (`matchesGoldenFile`, `loadAppFonts`, multi-surface rendering).
- [x] `integration_test` (SDK) — E2E driver (Phase 6).
- [ ] `patrol: ^3.x` — E2E with native permission handling (Phase 6; do not add until Phase 6 begins to keep `pub get` fast).
- [x] `flutter pub get` — verify resolution.
- [x] Bonus: added `stream_channel` (channel-fake type), `nested` (test harness), `fake_async` (reconnect tests) as direct deps.

### 2.2 Production seams (small, non-breaking, isolated to a few files)

#### `lib/services/api_service.dart`
- [x] Add `static void setTransport(Dio dio)` → replaces `_dio` (used only in tests).
- [x] Add `static Future<void> initForTest({Dio? dio})` → initializes `_dio` from the injected transport **without** touching `flutter_secure_storage`, `path_provider`, or the cache store. Keeps `init()` (production) untouched. `_cacheStore` became nullable with a `MemCacheStore()` fallback so `noCache`/`makeCacheOptions` work in tests.
- [x] Keep `init()` as-is for production; `setTransport`/`initForTest` are additive.

#### `lib/services/chat_websocket_service.dart`
- [x] Add an optional constructor param: `final StreamChannel<dynamic> Function(Uri url) channelFactory;` defaulting to `WebSocketChannel.connect` (`chat_websocket_service.dart:20-23`). Typed as `StreamChannel` (the supertype `WebSocketChannel` already satisfies) so tests can inject a mixin-based fake without constructing `WebSocketImpl`.
- [x] `connect()` uses `channelFactory(Uri.parse(url))` instead of hardcoding `WebSocketChannel.connect` (`chat_websocket_service.dart:32-35`).
- [x] No behavior change when the default is used.

#### `lib/utils/formatters.dart` (new file)
- [x] Extract `formatLastSeen(DateTime lastSeen, {DateTime? now}) -> String` from `online_indicator.dart:49-66` (rules: "Just now" <1 min, "Xm ago" <60 min, "Xh ago" <24 h, "Xd ago" <7 d, else `MMM d`). Keep the exact current strings so UI doesn't change.
- [x] Extract `formatDistanceKm(double? distanceKm) -> String` from `discover_screen.dart:735-737, 939-943` (rules: null → `500+ km`, ≥500 → `500+ km`, else `N km` via `.round()`).
- [x] Update `online_indicator.dart` and `discover_screen.dart` to call the new functions (behavior identical).
- [x] `flutter analyze` — no new issues after the seam edits.

### 2.3 Test helpers

#### `test/helpers/test_helpers.dart`
- [x] `Widget buildTestable(Widget child, {List<SingleChildWidget> providers = const []})`:
  - Wraps in `MaterialApp` with `theme: AppTheme.lightTheme`, `darkTheme: AppTheme.darkTheme`, `themeMode: ThemeMode.light`.
  - Adds `localizationsDelegates: AppLocalizations.localizationsDelegates`, `supportedLocales: AppLocalizations.supportedLocales`, `locale: const Locale('en')` so `AppLocalizations.of(context)!` never throws.
  - Applies `MultiProvider(providers: [...providers])` so tests can inject `ChangeNotifierProvider.value(fake)`.
  - `initTestEnvironment()` sets `SharedPreferences.setMockInitialValues`, mocks the `flutter_secure_storage` method channel, and calls `dotenv.testLoad(...)` (required — `AppConstants.*` throws `NotInitializedError` until dotenv is loaded).
- [x] `Future<void> pumpApp(WidgetTester tester, Widget child, {...})` wrapper for the common pump + `pumpAndSettle`.

#### `test/helpers/fixtures.dart`
- [x] Canonical mock objects + the exact JSON maps the backend returns:
  - `Message`: text / photo / voice; with and without `reply_to`; **matched** (`match_id` set) and **unmatched** (`match_id` null); `is_sent/is_delivered/is_read` combos.
  - `Match`: `/matches` shape **and** `/conversations` shape (`kind: match|unmatched`, `unread_count`, `is_accepted`, `updated_at`, nullable `last_message`).
  - `SwipeUser`: with/without `is_online`, `last_seen_at`, `swiped_at`.
  - `DiscoverProfile`, `User`, `Photo`, `Interest`, `Prompt`.
- [x] `Map<String, dynamic> jsonMatch(...)`, `jsonMessage(...)` builders so tests can tweak one field without rewriting maps.

#### `test/helpers/mock_api.dart`
- [x] Thin wrapper over `http_mock_adapter`'s `DioAdapter`:
  - Fresh `Dio(BaseOptions(baseUrl: ...))` + `DioAdapter()` attached to `httpClientAdapter`.
  - `onGet`/`onPost`/`onPatch`/`onDelete` helpers that register JSON replies with zero delay.
  - `install()` applies `ApiService.setTransport(dio)`.
- [x] Helper to assert a request was made: `expectCalled(path, times:)` reads `adapter.history`.

#### `test/helpers/fake_websocket_channel.dart`
- [x] `StreamChannelMixin`-based fake with a controllable incoming stream, a captured `sent` list, and `closeCount`; `emitIncoming()`/`disconnect()` drive the service.

---

## 3. PHASE 1 — Unit tests (`test/unit/`) — no widgets, no device

### 3.1 Validators — `test/unit/validators/validators_test.dart`
- [x] `validateEmail`: accepts `a@b.co`, `name@domain.com`, `x@y.io`; rejects empty, `a@`, `a@b`, `no-at-sign`, spaces.
- [x] `validatePassword`: rejects empty; rejects <8 chars; accepts exactly 8 and 8+.
- [x] `validateName`: rejects empty and 1 char; accepts 2+.
- [x] `validateAge`: rejects empty, non-numeric, 17, 101; accepts 18 and 100 (boundaries).

### 3.2 Models — `test/unit/models/`
- [x] `message_test.dart` — `fromJson` text/photo/voice (content, `media_url`, `media_duration`, `reply_to`, `is_sent/is_delivered/is_read`, `sent_at` parsing), `fromSocketData` (no delivered/read timestamps → defaults), `local()` (optimistic), `copyWith`, `toJson` round-trip, **unmatched `match_id` null → `matchId == ''`**.
- [x] `match_test.dart` — `/matches` shape; `/conversations` shape: `kind == 'match'|'unmatched'`, `unreadCount`, `isAccepted` default per kind, `updatedAt`, `lastMessage == null` when absent.
- [x] `swipe_user_test.dart` — `isOnline` (bool/null), `lastSeenAt` (string), `swipedAt` (datetime/null), `distanceKm` numeric.
- [x] `discover_profile_test.dart` — nested fields, null `distanceKm`, list `interests`/`photos`, `displayPhotoUrl`/`locationDisplay` getters.
- [x] `user_test.dart` (incl. `UserSettings` + `getAgeFromBirthDate`), `photo_test.dart` (PhotoResponse/PhotoUpload/PhotoUploadResponse/CropData), `interest_test.dart`, `prompt_test.dart` — round-trips.

### 3.3 Formatters — `test/unit/utils/formatters_test.dart`
- [x] `formatLastSeen`: <1 min → "Just now"; 5 min → "5m ago"; 2h → "2h ago"; 6d → "6d ago"; ≥7d → short date (`Jul 1`). Deterministic via injected `now`.
- [x] `formatDistanceKm`: null → `500+ km`; 500 → `500+ km`; 12.4 → `12 km`; 0.5 → `1 km` (Dart `.round()` rounds half away from zero); 499 → `499 km`.

### 3.4 WebSocket service — `test/unit/services/chat_websocket_service_test.dart`
Uses `test/helpers/fake_websocket_channel.dart` (a fake `StreamChannel` whose stream is a controllable `StreamController`).
- [x] `connect()` opens channel with URL containing `/ws/chat/{id}` and `token=`; emits `connectionState = true`; no-op after dispose.
- [x] `sendTyping()` / `sendTypingStopped()` / `sendReadReceipt()` / `sendPing()` emit correct JSON envelopes; silent after dispose.
- [x] Incoming frame: valid JSON → `events` emits parsed map; **malformed JSON → ignored, no crash**. (Test awaits a microtask — the broadcast `events` controller delivers asynchronously.)
- [x] Healthy server close → `false` then reconnects after 1 s; backoff grows `[1,2,4,8,16,30]` when open keeps failing, capped at 6 attempts (7 total connects).
- [x] `dispose()` closes the channel sink (`closeCount == 1`) and cancels timers; subsequent `_send` is a no-op.
- [x] 79 unit tests total, `flutter test` green.

---

## 4. PHASE 2 — Widget tests — Auth flow (`test/widget/screens/auth/`)

> These screens are the most bug-prone due to async validation states — do them early.
> All pump the real provider tree with `buildTestable()` + mocked HTTP transport + mocked storage.

- [ ] `splash_screen_test.dart`
  - [ ] No tokens / unauthenticated → navigates to `SignUpScreen`.
  - [ ] Tokens present + token valid → navigates to Discover (`main_screen.dart`).
  - [ ] Token refresh fails → cleared tokens + back to sign-up.
  - [ ] Server down → shows server-error state (mock `/health` failing).
- [ ] `sign_up_screen_test.dart`
  - [ ] Empty fields → inline validation errors (`Validators` messages) shown on submit.
  - [ ] Submit button disabled while `isLoading`; spinner shown.
  - [ ] Successful `registerInit` → navigates to `VerifyCodeScreen`.
  - [ ] Failed request → error banner from `AuthProvider.errorMessage`.
  - [ ] "Continue with Google" button fires the correct callback.
- [ ] `verify_code_screen_test.dart`
  - [ ] Typing a digit auto-advances focus to next box (matches `_codeFocusNodes` at `verify_code_screen.dart:33-105`).
  - [ ] Backspace on empty box returns focus to previous.
  - [ ] Pasting full code fills all boxes.
  - [ ] Wrong code → inline error; resend button disabled during cooldown, re-enabled after timer.
  - [ ] Successful verify → proceeds to onboarding/complete step.

---

## 5. PHASE 3 — Widget tests — Discover + Profile (`test/widget/screens/discover/`, `profile/`)

- [ ] `discover_screen_test.dart`
  - [ ] Renders photo/name/age from a `DiscoverProfile` fixture.
  - [ ] Swipe right → `like` callback; swipe left → `pass` callback (verify via provider state or mocked API assertion).
  - [ ] Loading skeleton while feed is fetching (`provider.isLoading && feed empty`).
  - [ ] Empty feed → empty-state UI ("No more profiles nearby" equivalent).
  - [ ] Error → error banner + retry button.
  - [ ] Distance label renders from `formatDistanceKm` (e.g. `500+ km`).
- [ ] `profile_detail_screen_test.dart` (viewing another user)
  - [ ] All profile fields render from fixture.
  - [ ] Report / block buttons present and wired to callbacks.
- [ ] `profile_screen_test.dart` (own profile)
  - [ ] Edit toggle switches fields to editable.
  - [ ] Save disabled until a field actually changes.
  - [ ] Photo reorder / delete updates the grid (mock `PhotoService`).
- [ ] `search_filter_sheet_test.dart`
  - [ ] Slider/stepper updates the bound value.
  - [ ] Apply persists selection + closes the sheet (calls provider with new filters).
  - [ ] Reset returns to defaults.

---

## 6. PHASE 4 — Widget tests — Chats + Settings (`test/widget/screens/chats/`, `settings/`)

> Highest value: covers the chat-repair work already shipped (conversations list, unread badges, isMine, live online, photo send).

- [ ] `chat_list_screen_test.dart`
  - [ ] Lists `provider.conversations` (both `kind: match` and `kind: unmatched`).
  - [ ] Ordered by recency (as returned by API).
  - [ ] **Unread badge**: `unreadCount > 0` → badge with number; `99+` cap; hidden when 0.
  - [ ] Online dot shown when `user.isOnline == true`.
  - [ ] Empty state ("no conversations yet") when list empty.
  - [ ] Tapping a conversation opens `ChatDetailScreen` with correct `identifier` (match id vs user id for unmatched).
- [ ] `chat_detail_screen_test.dart`
  - [ ] Sent vs received bubbles aligned right/left with distinct styling (`isMine` from real stored user id, not `messages.first.senderId`).
  - [ ] Typing indicator shows on `typing` event, hides on `typing_stopped`/5s timeout.
  - [ ] Auto-scroll to bottom on new incoming message.
  - [ ] **Send text clears input** and adds optimistic bubble, then replaces it with the server `message` object on success.
  - [ ] Failed send removes the optimistic bubble and shows error.
  - [ ] Photo attach callback → picker → `sendPhoto` (mock picker; assert `sendPhoto` called and media bubble renders from `mediaUrl`).
  - [ ] Voice send → `sendVoice` called with path+duration.
  - [ ] Reply flow: long-press → Reply → banner shows quoted content → send includes `reply_to_id`.
  - [ ] App bar reflects live `isOtherUserOnline` (flips on `user_online`/`user_offline` WS events).
- [ ] `chats_screen_test.dart`
  - [ ] Three tabs render (LikedMe / ILiked / Chats).
  - [ ] `MatchedAvatarStrip` shows **only `kind == "match"`** conversations (not unmatched).
- [ ] `settings_screen_test.dart`
  - [ ] Toggles reflect saved state (`SettingsProvider.darkMode`, language, hide-online, hide-last-seen).
  - [ ] Premium/subscription status displayed correctly.
  - [ ] Navigation to each sub-screen works.

### Shared component tests (`test/widget/components/`) — test once, trust everywhere
- [ ] `chat_message_bubble_test.dart` — text/photo/voice content, mine/other styling, deleted-message placeholder, edited marker, timestamp + read ticks.
- [ ] `chat_input_bar_test.dart` — text send, voice record UI states (recording banner, timer, cancel, stop), photo button wired, edit mode, reply banner, canSend=false disabled state.
- [ ] `online_indicator_test.dart` — online / last-seen text (via `formatLastSeen`).
- [ ] `matched_avatar_strip_test.dart` — filters to matches, tap callback, empty → hidden.
- [ ] `user_card_test.dart`, `shimmer_avatar_test.dart`, `loading_widget_test.dart`, `typing_indicator_test.dart` — smoke renders.
- [ ] Bottom nav (`main_screen.dart:169`) — active tab highlight + tap navigation across Discover/Search/Chats/Profile.

---

## 7. PHASE 5 — Golden tests (`test/goldens/`)

> Protects the design system (`AppTheme` + Inter) from drift. High value on stable, data-shaped components.

- [ ] `goldens/discover_card.png` — `DiscoverCard`/`UserCard` with a fixture profile.
- [ ] `goldens/chat_bubble_mine.png` + `goldens/chat_bubble_other.png` — `ChatMessageBubble` text variants.
- [ ] `goldens/profile_header.png` — own-profile header.
- [ ] `goldens/settings_row.png` — a settings row in light + dark.
- [ ] `goldens/empty_chats.png` — chat list empty state.
- [ ] Font strategy: `GoogleFonts.config.allowRuntimeFetching = false` and load bundled Inter via `golden_toolkit`'s `loadAppFonts()` (deterministic rendering; default test font is "Ahem").
- [ ] Generate baselines: `flutter test --update-goldens`.
- [ ] Skip dynamic screens (chat list with variable content) — low value, high flake.

---

## 8. PHASE 6 — E2E tests (`integration_test/`, patrol)

> Real device/emulator, full app. Patrol handles native permission dialogs (photo access, notification) that vanilla `integration_test` cannot.

### Setup
- [ ] Add `patrol` dev dep + `patrol` native setup (Android/iOS build config).
- [ ] Add a **test-mode bypass** in `main()`: when `--dart-define=FLUTTER_TEST_MODE=true`, skip server health gate and inject a test user (`loginAsTestUser`), so E2E can start at Discover.
- [ ] `integration_test/main_test.dart` bootstrap.

### The 5 flows (keep 5–8 tests total)
- [ ] `auth_flow_test.dart` — Signup → OTP verify → onboarding → land on Discover.
- [ ] `google_oauth_test.dart` — Google OAuth login with a mocked provider response.
- [ ] `match_and_chat_test.dart` — Swipe → mutual match → navigate to chat → send message → visible in chat list (covers the chat-repair flows end-to-end).
- [ ] `filter_and_discover_test.dart` — Apply filters → Discover feed updates accordingly.
- [ ] `premium_upgrade_test.dart` — Free → premium upgrade → unlocked feature visible in UI (mock the payment callback state; ZarinPal is a backend concern).

### Cadence
- [ ] Run **nightly** in CI only (not on every push).
- [ ] Keep the suite small — it is the slowest and highest-maintenance layer.

---

## 9. PHASE 7 — CI (GitHub Actions)

> This repo uses GitHub Actions (backend does too). The original draft's GitLab YAML is **not** used.

### `.github/workflows/flutter_test.yml` — unit + widget + goldens on every push/PR
- [ ] Runs on `ubuntu-latest`, image `ghcr.io/cirruslabs/flutter:stable`.
- [ ] Steps: `flutter pub get` → `flutter analyze` → `flutter test --coverage` (with `xvfb-run` if golden tests need it).
- [ ] Upload coverage artifact: `coverage/lcov.info` (+ optional Codecov action).
- [ ] Coverage regex for the check badge: `/lines\.*:\s*\d+\.\d+\%/`.

### `.github/workflows/flutter_e2e.yml` — nightly only
- [ ] Trigger: `schedule` (e.g. `0 2 * * *`), workflow_dispatch for manual runs.
- [ ] Run `integration_test/` via patrol (`leancodepl/patrol-action`) or `reactivecircus/android-emulator-runner` with a test APK.
- [ ] Post run summary on failure (comment on the latest commit or an issue).

### Optional
- [ ] Add a `flutter_test` status badge to the repo README.

---

## 10. Folder structure (target)

```
project_d_mobile/
├── lib/
│   ├── services/
│   │   ├── api_service.dart            # + setTransport / initForTest (seam)
│   │   └── chat_websocket_service.dart # + channelFactory (seam)
│   ├── utils/
│   │   ├── validators.dart             # existing
│   │   └── formatters.dart             # NEW — extracted last-seen/distance
│   └── … (rest unchanged)
├── test/
│   ├── helpers/
│   │   ├── test_helpers.dart           # buildTestable(), pumpApp()
│   │   ├── fixtures.dart               # mock models + JSON builders
│   │   ├── mock_api.dart               # http_mock_adapter wrapper + route map
│   │   └── fake_websocket_channel.dart # controllable fake channel
│   ├── unit/
│   │   ├── validators/validators_test.dart
│   │   ├── models/{message,match,swipe_user,discover_profile,user,photo,interest,prompt}_test.dart
│   │   ├── utils/formatters_test.dart
│   │   └── services/chat_websocket_service_test.dart
│   ├── widget/
│   │   ├── screens/
│   │   │   ├── auth/{splash,sign_up,verify_code}_test.dart
│   │   │   ├── discover/{discover_screen,profile_detail}_test.dart
│   │   │   ├── profile/{profile_screen,search_filter_sheet}_test.dart
│   │   │   ├── chats/{chat_list,chat_detail,chats_screen}_test.dart
│   │   │   └── settings/settings_screen_test.dart
│   │   └── components/{chat_message_bubble,chat_input_bar,online_indicator,matched_avatar_strip,user_card,bottom_nav}_test.dart
│   └── goldens/{discover_card,chat_bubble_mine,chat_bubble_other,profile_header,settings_row,empty_chats}.png
└── integration_test/
    ├── auth_flow_test.dart
    ├── google_oauth_test.dart
    ├── match_and_chat_test.dart
    ├── filter_and_discover_test.dart
    └── premium_upgrade_test.dart
```

---

## 11. Phased rollout (solo-dev pace)

1. [x] **Step 0** — deps, seams (`ApiService`, `ChatWebSocketService`, `formatters.dart`), helpers.
  2. [x] **Phase 1** — unit tests: validators, models, formatters, websocket (fast wins, no widget overhead).
  3. [x] **Phase 2** — widget tests: auth flow (most bug-prone async states).
  4. [x] **Phase 3** — widget tests: Discover + Profile.
  5. [x] **Phase 4** — widget tests: Chats + Settings (validates the shipped chat-repair work).
  6. [~] **Phase 5** — golden tests for design-system-critical components.
  7. [ ] **Phase 6** — the 5 E2E flows via patrol, wired into nightly CI.
  8. [ ] **Phase 7** — GitHub Actions: `flutter_test.yml` (every push) + `flutter_e2e.yml` (nightly).
  9. [ ] **Phase 8** — revisit coverage gaps from real user bug reports.

---

## 12. Traceability checklist (run at the end of each phase)

- [ ] `flutter pub get` — resolves clean.
- [ ] `flutter analyze` — no new issues.
- [ ] `flutter test` — all green.
- [ ] `flutter test --update-goldens` run only when a golden is intentionally changed.
- [ ] Plan checkboxes updated for the finished phase.
- [ ] CI workflow green (once wired).

---

## 13. Commands cheat-sheet

```bash
flutter pub get
flutter analyze
flutter test                                   # all
flutter test test/unit/ -v                     # unit only
flutter test test/widget/ -v                   # widget only
flutter test --update-goldens                  # refresh golden baselines
flutter test --coverage                        # produces coverage/lcov.info
flutter test integration_test/                 # E2E on an attached device
patrol test                                    # patrol E2E with native permissions
```
