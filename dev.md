# Iranian Dating App - Flutter Mobile Client

Flutter mobile client for Iranian dating app (Badoo-style).

## Features

- ✅ User Authentication (Register, Login)
- ✅ Secure token storage with flutter_secure_storage
- ✅ Environment configuration via .env
- ✅ Clean architecture with Provider state management
- ✅ Profile Edit & Account Settings (Session 21)
- ✅ Google Sign-In Integration
- ✅ Photo Upload with Drag & Drop
- ✅ Location Services with GPS and Manual Selection
- ✅ Settings Screen (Dark Mode, Privacy, Notifications, Language)
- ✅ Dark Mode - Full theme support
- ✅ Discover card swiping with Tinder-style stamps
- ✅ Interest icons from backend with emoji
- ✅ Profile detail screen with chip-style attributes
- ✅ Daily limits for likes (20) and chats (10) with badge indicators
- ✅ Filter persistence across app restarts (SharedPreferences)
- ✅ Widen search (+50km / +2 years) when no results
- ✅ Logout option in settings
- ✅ Verified badge on card and detail screen
- ✅ Detail page closes on like/pass/chat action
- ✅ Search screen with 3-column grid and infinite scroll
- ✅ Advanced search filters (25+ options)
- ✅ Search profile detail with Like + Chat buttons
- ✅ Filter persistence across app restarts (SharedPreferences)
- 🔄 Localization & Translation (In Progress)
- ✅ Real-time chat with WebSocket (Session 28)
- ✅ Likes & matches system (Session 28)
- ✅ Edit & delete messages (Session 28)
- ✅ Chat initiation limit — 2 messages until reply (Session 28)
- ✅ Voice messages (hidden on web) (Session 28)

## Tech Stack

| Category | Package |
|----------|---------|
| Framework | Flutter 3.x |
| State Management | Provider |
| HTTP Client | Dio |
| HTTP Caching | dio_cache_interceptor + Hive |
| WebSocket | web_socket_channel |
| Secure Storage | flutter_secure_storage |
| Local Storage | shared_preferences |
| Image Picker | image_picker |
| Image Caching | cached_network_image + shimmer |
| Environment | flutter_dotenv |
| Google Sign-In | google_sign_in |
| Geolocator | geolocator |
| Audio Recording | record |
| Audio Playback | just_audio |
| UUID | uuid |

## Requirements

- Flutter SDK 3.0+
- Dart 3.0+
- Backend server running on port 8000

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/iranian-dating-app.git
cd iranian-dating-app/mobile
```

### 2. Get dependencies

```bash
flutter pub get
```

### 3. Configure environment

Create `.env` file in the project root:

```env
API_BASE_URL=http://10.0.2.2:8000/api/v1
WS_BASE_URL=ws://10.0.2.2:8000/api/v1
WEB_CLIENT_ID=your_web_client_id.apps.googleusercontent.com
```

> **Note:** Use `10.0.2.2` for Android emulator. For physical device, use your computer's IP address.

### 4. Run the app

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/                   # Configuration files
│   ├── app_constants.dart    # API URLs, keys
│   └── app_theme.dart        # Theme configuration (Light/Dark)
├── models/                   # Data models
│   ├── user.dart             # User model
│   ├── discover_profile.dart # Discover feed profile model
│   ├── interest.dart         # Interest model
│   ├── prompt.dart           # Prompt model
│   ├── photo.dart            # Photo model
│   ├── location_models.dart  # Location models
│   ├── swipe_user.dart       # Swipe/like user model
│   ├── match.dart            # Match model with last message
│   └── message.dart          # Message model (text/photo/voice)
├── services/                 # API services
│   ├── api_service.dart      # Dio HTTP client with interceptors + Hive cache
│   ├── auth_service.dart     # Auth API calls
│   ├── storage_service.dart  # Secure token storage
│   ├── discover_service.dart # Discover/swipe/limits API
│   ├── search_service.dart   # Search API with filters
│   ├── chat_service.dart     # Chat/matches/messages API
│   ├── chat_websocket_service.dart # WebSocket real-time events
│   ├── google_auth_service.dart # Google Sign-In
│   ├── location_service.dart # GPS & Location APIs
│   ├── onboarding_service.dart # Onboarding API calls
│   └── photo_service.dart    # Photo upload & management
├── providers/                # State management
│   ├── auth_provider.dart    # Auth state
│   ├── discover_provider.dart # Discover state (profiles, filters, limits)
│   ├── search_provider.dart  # Search state (filters, pagination)
│   ├── chat_provider.dart    # Chat state (matches, messages, WebSocket)
│   ├── language_provider.dart # Language selection
│   ├── onboarding_provider.dart # Onboarding state
│   ├── profile_provider.dart # Profile state
│   └── settings_provider.dart # Settings state (dark mode, privacy, notifications)
├── screens/                  # UI screens
│   ├── splash_screen.dart    # Splash screen with progress
│   ├── login_screen.dart     # Login screen
│   ├── main_screen.dart      # Main screen with bottom nav
│   ├── auth/                 # Auth screens
│   │   ├── sign_up_screen.dart
│   │   └── verify_code_screen.dart
│   ├── onboarding/           # Onboarding flow (6 steps)
│   │   ├── basic_info_screen.dart
│   │   ├── profile_details_screen.dart
│   │   ├── interests_screen.dart
│   │   ├── prompts_screen.dart
│   │   └── photo_upload_screen.dart
│   ├── discover/             # Discover/swiping screens
│   │   ├── discover_screen.dart
│   │   └── profile_detail_screen.dart
│   ├── search/               # Search screens
│   │   ├── search_screen.dart
│   │   ├── search_filter_sheet.dart
│   │   └── search_profile_detail.dart
│   ├── chats/                # Chat screens
│   │   ├── chats_screen.dart        # TabBar: Liked Me / I Liked / Chats
│   │   ├── liked_me_screen.dart     # Users who liked you
│   │   ├── i_liked_screen.dart      # Users you liked
│   │   ├── chat_list_screen.dart    # Active conversations
│   │   └── chat_detail_screen.dart  # Chat detail with WS
│   └── profile/              # Profile screens
│       ├── profile_screen.dart
│       ├── avatar_crop_screen.dart
│       ├── edit_basic_info_screen.dart
│       ├── edit_profile_details_screen.dart
│       ├── edit_interests_screen.dart
│       ├── edit_prompts_screen.dart
│       └── settings_screen.dart
├── widgets/                  # Reusable widgets
│   ├── loading_widget.dart
│   ├── progress_bar.dart
│   ├── shimmer_avatar.dart
│   ├── user_card.dart        # Swipeable card with stamps
│   ├── discover_action_button.dart # Circular button with badge
│   ├── search_grid_card.dart # Compact grid card for search
│   ├── matched_avatar_strip.dart # Horizontal avatar strip (Instagram Stories)
│   ├── chat_message_bubble.dart  # Text/photo/voice message bubble
│   ├── chat_input_bar.dart       # Text/voice/photo input with edit mode
│   ├── chat_app_bar.dart         # Chat detail AppBar
│   ├── typing_indicator.dart     # Animated typing dots
│   ├── online_indicator.dart     # Online/last seen indicator
│   └── voice_message_player.dart # Voice playback with progress bar
├── l10n/                     # Localization
│   ├── app_en.arb            # English translations
│   └── app_fa.arb            # Persian translations
├── generated/                # Generated localization files
└── utils/                    # Utilities
    └── validators.dart       # Form validators
```

## API Integration

The app connects to a FastAPI backend with the following endpoints:

| Endpoint | Method | Description | Status |
|----------|--------|-------------|--------|
| `/auth/register/init` | POST | Request verification code | ✅ |
| `/auth/register/verify` | POST | Verify code & create user | ✅ |
| `/auth/register/complete` | POST | Complete profile | ✅ |
| `/auth/login` | POST | User login | ✅ |
| `/auth/google` | POST | Google Sign-In | ✅ |
| `/auth/refresh` | POST | Refresh access token | ✅ |
| `/auth/logout` | POST | User logout | ✅ |
| `/auth/health` | GET | Health check | ✅ |
| `/users/me` | GET | Get current user | ✅ |
| `/users/me` | PUT | Update profile | ✅ |
| `/users/me/interests` | PUT | Update interests | ✅ |
| `/users/me/prompts` | PUT | Update prompts | ✅ |
| `/users/me/photos` | GET/POST | Photo management | ✅ |
| `/users/me/photos/{id}` | DELETE | Delete photo | ✅ |
| `/users/me/photos/{id}/main` | PUT | Set main photo | ✅ |
| `/users/me/settings` | PUT | Update settings | ✅ |
| `/users/me/location` | POST | Update GPS location | ✅ |
| `/users/me/location-text` | PATCH | Update text location | ✅ |
| `/locations/countries` | GET | Get countries | ✅ |
| `/locations/states` | GET | Get states/provinces | ✅ |
| `/locations/cities` | GET | Get cities | ✅ |
| `/locations/reverse-geocode` | GET | Reverse geocode | ✅ |
| `/locations/city-centroid` | GET | Get city centroid | ✅ |
| `/interests` | GET | Get interests | ✅ |
| `/prompts` | GET | Get prompts | ✅ |
| `/discover` | GET | Get card stack | ✅ |
| `/search` | GET | Search users with filters | ✅ |
| `/swipes` | POST | Send like/pass | ✅ |
| `/rewards/my-limits` | GET | Get daily limits | ✅ |
| `/matches` | GET | Get matches | ✅ |
| `/matches/{id}` | GET | Match detail | ✅ |
| `/swipes/likers` | GET | Users who liked you | ✅ |
| `/swipes/liked` | GET | Users you liked | ✅ |
| `/swipes/stats` | GET | Likes/chats remaining | ✅ |
| `/messages/{id}` | GET | Chat history | ✅ |
| `/messages/{id}/text` | POST | Send text message | ✅ |
| `/messages/{id}` | PUT | Edit message | ✅ |
| `/messages/{id}/photo` | POST | Send photo message | ✅ |
| `/messages/{id}/voice` | POST | Send voice message | ✅ |
| `/messages/{id}/accept` | POST | Accept unmatched chat | ✅ |
| `/messages/{id}` | DELETE | Delete message | ✅ |
| `/messages/delivered` | POST | Batch mark delivered | ✅ |
| `/messages/read` | POST | Batch mark read | ✅ |
| `/ws/chat/{id}` | WS | Real-time events | ✅ |

## Session Progress

| Session | Focus | Status |
|---------|-------|--------|
| 16 | Project Setup & Auth Screens | ✅ |
| 17 | Onboarding Flow (6 Steps) | ✅ |
| 18 | Photo Upload & Profile | ✅ |
| 19 | Location Services | ✅ |
| 20 | Google Sign-In | ✅ |
| 21 | Profile Edit & Account Settings | ✅ |
| 22 | Settings Screen & Dark Mode | ✅ |
| 23 | Localization, Discover Screen & Profile Detail Redesign | ✅ |
| 24 | Discover & Swiping (Swipe Stamps, Interest Icons from Backend) | ✅ |
| 25 | Discover Polish, Limits, Filters, Logout | ✅ |
| 26 | Search Screen (Grid, Filters, Detail, Infinite Scroll) | ✅ |
| 27 | Web Setup — Chrome browser + deployed backend | ✅ |
| 28 | Chat System (Messages + WebSocket) | ✅ |
| 29 | Likes, Matches & Production | ⬜ |

## Session 25 - Discover Polish, Limits, Filters, Logout

### Card Simplification
- **Card shows only**: name + age + gender icon, distance, location (city, province)
- **Removed from card**: interest chips, body type, workplace
- **Kept on card**: Premium badge, Verified badge (bigger circle, 14px icon)

### Profile Detail - Chip Style
- Physical, Lifestyle, Background sections now use **chip/pill layout** (like interests)
- Each value is a rounded pill with emoji prefix (e.g. 📏 175 cm, ⚖️ 70 kg)
- Removed key-value row layout (`_buildInfoRow`)
- About, Languages, Interests, Prompts sections unchanged

### Daily Limits (Likes & Chats)
- **Likes**: 20/day for free users, unlimited for premium
- **Chats**: 10/day for free users, unlimited for premium
- **Badge indicators**: Red circle with remaining count on like and chat buttons
- **Client-side enforcement**: Buttons disabled when limit reached
- **Popup dialog**: AlertDialog shown when tapping blocked button
- **Card stays on limit reached**: Card not removed until explicit pass/like

### Filter Persistence
- Filters saved to SharedPreferences on every change
- Loaded once on first `loadProfiles()` call (not on every load)
- Keys: `discover_gender`, `discover_age_min`, `discover_age_max`, `discover_distance_km`

### Widen Search
- When no results, empty state shows **+50 km** and **+2 years** buttons
- Each tap adds 50km to distance or 2 years to max age
- When max reached (500km / 100 years), sets to null (no limit)
- Backend receives no param → returns all users

### Filter Sliders
- Distance: 1-500km, at max shows "500+ km" (no limit)
- Age: 18-100, at max shows "100+" (no limit)
- When at no-limit, param omitted from API call

### Chat Button Style
- White background + blue icon + blue border (both discover and detail screens)

### Detail Page Navigation
- Like/Pass/Chat actions close the detail page and return to discover
- Next card shown automatically

### Logout
- Settings → Account section → Log Out button (red)
- Confirmation dialog before logout
- Clears tokens, navigates to login screen

### Bug Fixes
- Fixed swipeRight/swipeAndChat: `_removeProfile` now only called after server confirms success
- Fixed limit race condition: `_loadFilters` only called once, not on every empty result
- Fixed detail page navigation: uses MaterialPageRoute (not named routes)

## Session 26 - Search Screen

### Search Grid
- **3-column grid** with compact cards (smaller than Discover cards)
- **Infinite scroll** pagination (loads more when scrolling near bottom)
- **No caching** — all searches use `ApiService.noCache` for real-time results
- **Card shows**: photo, name + age + gender icon, distance, location

### Search Filters
- **Quick filter bar**: Gender, Age range, Distance, Sort, Advanced (opens sheet)
- **Advanced filter sheet** (25+ options):
  - Location: Country → Province → City cascading dropdowns (English)
  - Physical: Height range, Weight range, Body type chips
  - Lifestyle: Relationship, Education, Smoking, Drinking, Political, Children, Living
  - Background: Religion chips, Ethnicity chips
  - Interests: Collapsible by category, multi-select with count badges
  - Languages: Multi-select chips
  - Verification: Has Photos toggle, Verified Only toggle
- **Filter persistence**: All filters saved to SharedPreferences with `search_` prefix
- **Sort options**: Recent (default), Distance, Age, Name

### Search Profile Detail
- Same layout as Discover profile detail (hero image, photo strip, chip sections)
- **2 buttons only**: Like + Chat (no Pass button)
- Uses callbacks instead of Provider (since pushed via Navigator)
- Shows all photos, interests, prompts when backend provides them

### Limits Sync
- Shares same `/rewards/my-limits` endpoint as Discover
- `WidgetsBindingObserver` refreshes limits when app resumes
- Both providers independently call the same backend endpoint

### Files Created
- `lib/services/search_service.dart` — API layer
- `lib/providers/search_provider.dart` — State management
- `lib/widgets/search_grid_card.dart` — Compact card widget
- `lib/screens/search/search_screen.dart` — Main screen
- `lib/screens/search/search_filter_sheet.dart` — Advanced filters
- `lib/screens/search/search_profile_detail.dart` — Detail page

### Localization
- 48 new search keys in `app_en.arb` and `app_fa.arb`
- Filter values in English (location names from API)
- UI labels localized for both languages

## Session 27 — Web Setup (Chrome Browser)

### Changes Made
- **`.env`** — `API_BASE_URL` and `WS_BASE_URL` updated from localhost to deployed server (`87.107.5.88`)
- **`flutter config --enable-web`** — Enabled Flutter web platform support
- **CORS** — Backend configured with `*` (all origins) for development

### Running in Chrome
```bash
flutter run -d chrome
```
App uses email/password auth (Google Sign-In not configured for web yet).

### Requirements for Web Deployment
- Backend CORS must allow the web app's origin (currently `*`)
- Google Sign-In needs a Web OAuth client ID + authorized JS origins in Google Cloud Console
- `flutter_secure_storage` v9+ has web support (Web Crypto API)
- GPS location on web requires HTTPS (works on `localhost` for dev)

### Notes
- Google Sign-In intentionally skipped — login via email/password only
- All packages support web: `flutter_secure_storage_web`, `google_sign_in_web`, `geolocator_web`, `hive`
- Backend health check confirmed: `{"status":"healthy","redis":"connected"}`

## Session 28 — Chat System (Messages + WebSocket)

### Architecture
- **Global `ChatProvider`** in `main.dart` MultiProvider — WS connection persists across tab switches
- **HTTP REST** for message persistence (send, edit, delete, read receipts)
- **WebSocket** for real-time events (new messages, typing, online/offline, new matches)

### Three-Tab Chats Screen
- **Liked Me** — Users who liked you (`/swipes/likers`), tap opens unmatched chat
- **I Liked** — Users you liked (`/swipes/liked`), tap opens unmatched chat
- **Chats** — Active conversations with matches (`/matches`), shows last message preview

### Matched Avatar Strip
- Instagram Stories-style horizontal avatar strip at top of chats screen
- Shows 5 newest matches with gradient ring + online dot
- Auto-updates when `new_match` WebSocket event arrives

### Messages
- Text, photo (multipart upload), voice (record + just_audio playback) messages
- Cursor pagination for chat history (load more on scroll to top)
- Optimistic UI — messages appear instantly, replaced with server response

### Edit & Delete Messages
- **Long-press** on own message → bottom sheet with Edit / Delete / Reply
- **Edit**: inline edit bar replaces input bar, HTTP `PUT /messages/{id}`
- **Delete**: confirmation dialog → "Delete for me" or "Delete for everyone"

### Chat Initiation Limit
- In unmatched chats: max **2 messages** until receiver replies
- `canSendMessage` getter blocks send when limit reached
- Shows info banner: "Send up to 2 messages. Wait for a reply to continue chatting."
- Counter resets when `isAccepted` becomes true (receiver replies or accepts)

### Typing & Online Indicators
- Animated 3-dot pulse typing indicator (auto-hides after 5s)
- Green dot + "Online" text or "Last seen X ago"

### Voice Messages
- Hold-to-record button (max 120s countdown)
- Playback widget with progress bar + play/pause
- **Hidden on web** via `kIsWeb` check (record button + player both hidden)

### WebSocket Service
- Connect/disconnect with JWT auth
- Heartbeat (ping every 30s)
- Auto-reconnect with exponential backoff (1s→30s, max 6 attempts)
- Close codes: 4001 (unauthorized), 4003 (access denied)

### Files Created (16 new)
- `lib/models/swipe_user.dart` — User in swipe/like context
- `lib/models/match.dart` — Match with last message
- `lib/models/message.dart` — Message with text/photo/voice, edit/delete, copyWith
- `lib/services/chat_service.dart` — All HTTP endpoints (matches, messages, edit, delete, limits)
- `lib/services/chat_websocket_service.dart` — WebSocket with heartbeat, reconnect, streams
- `lib/providers/chat_provider.dart` — Global provider with all state, edit/delete, initiation limit
- `lib/widgets/matched_avatar_strip.dart` — Horizontal avatar strip with gradient ring
- `lib/widgets/chat_message_bubble.dart` — Text/photo/voice bubbles with long-press menu
- `lib/widgets/typing_indicator.dart` — Animated 3-dot pulse
- `lib/widgets/online_indicator.dart` — Green dot or "Last seen X ago"
- `lib/widgets/voice_message_player.dart` — Play/pause with progress bar (hidden on web)
- `lib/widgets/chat_input_bar.dart` — Text/voice/photo input, edit mode, reply preview
- `lib/widgets/chat_app_bar.dart` — Avatar + name + online indicator
- `lib/screens/chats/chats_screen.dart` — TabBar (Liked Me / I Liked / Chats) + avatar strip
- `lib/screens/chats/liked_me_screen.dart` — Users who liked you, paginated
- `lib/screens/chats/i_liked_screen.dart` — Users you liked, paginated
- `lib/screens/chats/chat_list_screen.dart` — Active conversations
- `lib/screens/chats/chat_detail_screen.dart` — Full chat with WS, edit/delete, reply, typing

### Files Modified
- `pubspec.yaml` — Added `record`, `just_audio`, `uuid`
- `lib/main.dart` — Added `ChatProvider` to global MultiProvider
- `lib/l10n/app_en.arb` — ~40 new chat keys (tabs, actions, limits, errors, media)
- `lib/l10n/app_fa.arb` — ~40 new Persian chat keys

### Localization Keys (~40 new)
- Tabs: `chat_liked_me`, `chat_i_liked`, `chat_chats`
- Empty states: `chat_empty_matches`, `chat_empty_liked_me`, `chat_empty_i_liked`, `chat_empty_chats`
- Status: `chat_online`, `chat_last_seen_minutes/hours/days`, `chat_offline`
- Actions: `chat_send`, `chat_reply`, `chat_edit`, `chat_delete`, `chat_delete_for_me`, `chat_delete_for_everyone`
- Limits: `chat_limit_reached`, `chat_initiation_limit`, `chat_initiation_limit_explanation`
- Errors: `chat_error_loading`, `chat_error_sending`

## Color Rules (strict)

| Element | Color Source |
|---------|-------------|
| Reject (X) / NOPE stamp / Premium badge / Gender female | `lightError` / `darkError` |
| Chat button / LIKE stamp / Verified badge / Gender male | `lightPrimary` / `darkPrimary` |
| Like (Heart) button / Match dialog heart | `lightPrimary` / `darkPrimary` (via `likeGradient`) |
| Message sent checkmark | `lightSuccess` / `darkSuccess` |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `API_BASE_URL` | Backend API URL | `http://10.0.2.2:8000/api/v1` |
| `WS_BASE_URL` | WebSocket URL for chat | `ws://10.0.2.2:8000/api/v1` |
| `WEB_CLIENT_ID` | Google OAuth Client ID | Required for Google Sign-In |

## Error Handling

The app provides user-friendly error messages for common scenarios:

| HTTP Status | User Message |
|-------------|--------------|
| 401 | "Incorrect email or password. Please try again." |
| 404 | "User not found. Please check your email." |
| 409 | "Account already exists. Please login." |
| 422 | "Please check your information and try again." |
| 429 | "Too many attempts. Please wait a moment." |
| Network | "Cannot connect to server. Make sure backend is running." |

## Backend Requirements

Make sure the backend server is running:

```bash
cd backend
uvicorn app.main:app --reload --port 8000
```

Verify connection:

```bash
curl http://localhost:8000/api/v1/auth/health
```

Expected response: `{"status":"healthy","redis":"connected"}`

## Development

### Run in debug mode

```bash
flutter run
```

### Build APK

```bash
flutter build apk --release
```

### Build App Bundle

```bash
flutter build appbundle --release
```

## Troubleshooting

### Connection refused

Make sure backend is running and `API_BASE_URL` is correct.

### Google Sign-In not working

Make sure `WEB_CLIENT_ID` is set correctly in `.env` and `google-services.json` is configured.

### Packages not downloading

If you have network issues, try:

```bash
flutter pub get --offline
```

### Emulator can't connect to localhost

Use `10.0.2.2` instead of `localhost` in `.env` file.

### Location not working

Make sure location permissions are enabled and GPS is on.

## Contributing

This project is developed by Ehsan (solo developer).

## License

All rights reserved.
