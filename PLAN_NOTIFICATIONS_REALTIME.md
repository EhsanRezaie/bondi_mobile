# Plan — Real-time Notifications (4 Sections) + FCM Push + Unread Badges

Status: **Backend P1-P3 complete** (tests added) · Mobile M4-M9 pending
Repos: backend `C:\Users\Ehsan\Desktop\project_d` · mobile `C:\Users\Ehsan\Desktop\project_d_mobile`
Docs precedent: `project_d_mobile/PLAN_CHAT_REDESIGN.md`

---

## 0. Decisions locked in (from conversation)

- Notifications screen is rebuilt into **4 sections**, styled like the chat list:
  1. **Liked** — `type == "like"` (people liked me)
  2. **Likes** — `type == "liked"` (i liked; new backend type added)
  3. **Matches** — `type == "match"`
  4. **Announcements** — `type == "system"`
- `message` notifications are **push-only** — never rendered in a section.
- Tap on Liked / Likes / Matches → opens the user detail profile
  (`UserNotificationProfileScreen`). Tap on an Announcement → centered dialog
  (title on top, body below, Close button).
- **Real-time mechanism: WS + FCM**.
  - In-app live updates ride the existing persistent session socket
    (`/ws/stream`) via a new personal-channel `new_notification` event.
  - Background/closed-app delivery uses FCM push (backend already implemented).
- **Foreground behavior**: show a **custom app-themed toast** (NOT the API
  `action_toast`) with a **"See details"** button. Toast → See details:
  - liked / match → user profile page
  - announcement → announcement dialog
- **Background notification content**:
  - liked / match / message → show the other user's **name + avatar** (photo).
  - announcement → app icon + title/body.
- **No push to self**: liking someone does NOT push a system notification to
  yourself (matches current backend behavior — keep). The "Likes" section still
  updates live via WS while the screen is open.
- **Bell badge**: red **count pill** (number, capped at `99+`).
- **Section badges**: count pill per section header (unseen count per type).
- **Platforms**: Android push now (google-services.json already present,
  plugin already applied). iOS: real-time WS works; system push **deferred**
  until APNs credentials are added (no AppDelegate changes now).
- Announcement avatar note: system notification shows avatar as **BigPicture**
  (expanded) image; the compact row uses the app's small icon.

---

## Backend capabilities verified today

| Capability | Where |
|---|---|
| Notification rows: `like` / `liked` / `match` / `message` / `system` | `app/services/notification_service.py`, `app/api/v1/endpoints/admin_announcements.py` |
| FCM send (multicast, token cleanup, threading) | `app/services/push_service.py` |
| Device-token registration | `app/api/v1/endpoints/notifications.py` (`POST/DELETE /notifications/device-token*`) |
| Notifications list / read / delete | `app/api/v1/endpoints/notifications.py` (`GET /notifications`, `POST /notifications/read`, `DELETE /notifications/{id}`) |
| Session socket `/ws/stream` (personal channel) | `app/api/v1/websocket/stream.py` |
| Personal-channel publish | `app/services/websocket_manager.py` `send_personal_message(user_id, message, redis)` |
| Mobile session socket client | `lib/services/session_socket_service.dart` (owned by `ChatProvider`) |
| Notifications screen (4 sections, chat-list style) | `lib/screens/chats/notifications_screen.dart` |
| Notification model | `lib/models/notification.dart` |
| Notifications provider (list + pagination) | `lib/providers/notifications_provider.dart` |
| Bell icons (to upgrade) | `lib/screens/chats/chats_screen.dart:115`, `lib/screens/search/search_screen.dart:143` |
| Android Firebase config | `android/app/google-services.json` (pkg `ir.bondi.app`), `com.google.gms.google-services` plugin applied |

---

## Part 1 — Backend: WS `new_notification` event ✅ DONE

**Goal:** the app updates live (badges + toast) the moment a notification is
created for the logged-in user.

- [x] **B1-1** `app/services/notification_service.py` — in `notify_like`:
  - [x] after creating the row, publish to recipient's personal channel:
    `{"type":"new_notification","data":{id,type,title,body,is_read,created_at,user_id}}`
  - [x] use `websocket_manager.send_personal_message(str(liked_user_id), payload, redis_client)`; wrap in try/except (log, don't fail)
- [x] **B1-2** `app/services/notification_service.py` — in `notify_liked`:
  - [x] publish to the liker (self) personal channel (same payload shape) so the "Likes" section updates live
  - [x] do **NOT** send any FCM push to self
- [x] **B1-3** `app/services/notification_service.py` — in `notify_match` (both branches):
  - [x] publish `new_notification` to user1 and user2 with `data:{..., user_id, match_id}`
- [x] **B1-4** `app/api/v1/endpoints/admin_announcements.py` — after creating announcement rows:
  - [x] publish `new_notification` (type `system`) to each recipient's personal channel
  - [x] batch-safe: loop recipients, best-effort per user
- [x] **B1-5** Do NOT publish for `message` type (push-only) — confirm no WS publish in `notify_message`
- [x] Shared payload helper `_notification_ws_payload(notification)` in `notification_service.py` to keep one source of truth

### Verification (B1)
- [x] `py_compile` on changed files
- [x] pytest: WS event published on like / liked / match / system; no event for message (added to `test_notifications.py`)
- [x] pytest: self-like does not push FCM
- [x] All backend tests pass (17 tests in `test_notifications.py`) (added to `test_notifications.py`)

---

## Part 2 — Backend: unread counts endpoint ✅ DONE

**Goal:** accurate bell badge + per-section pills independent of pagination.

- [x] **B2-1** `app/schemas/notification.py` — add
  `NotificationCountsResponse { total: int, by_type: dict[str,int] }`
- [x] **B2-2** `app/api/v1/endpoints/notifications.py` — add
  `GET /notifications/counts`:
  - [x] single `GROUP BY type` query on `Notification` where `user_id == current` and `is_read == false`
  - [x] `total` = sum, `by_type` keyed by `like|liked|match|system`
  - [x] `@limiter.limit("60/minute")`
- [x] **B2-3** Tests in `project_d/tests/done/test_notifications.py`:
  - [x] counts returns correct total + per-type after creating several unread rows
  - [ ] counts drops after `POST /notifications/read`
  - [ ] counts drops after `DELETE /notifications/{id}`
  - [ ] no notifications → `{total:0, by_type:{}}`

### Verification (B2)
- [x] `pytest tests/done/test_notifications.py -v` → green (17 tests pass)
- [x] Stop infra after

---

## Part 3 — Backend: push payload avatar (name + photo) ✅ DONE

**Goal:** background notification shows the other user's name + avatar for
liked / match / message; app icon for announcements.

- [x] **B3-1** `app/services/push_service.py` — `send_to_user(..., image_url=None)`:
  - [x] pass `image=image_url` into `messaging.Notification(...)` when provided
- [x] **B3-2** `app/services/notification_service.py`:
  - [x] `notify_like`: resolve liker main photo URL → include in push `image_url` + data
  - [x] `notify_match`: include other user's main photo URL in push for each side
  - [x] `notify_message`: include sender main photo URL (resolved internally if not passed)
  - [x] `notify_liked`: no push (self) — skip
- [x] **B3-3** `admin_announcements.py` — no avatar; rely on default app icon (no change expected; verify)
- [x] Photo URL resolution helper `_get_main_photo_url` in `notification_service.py`

### Verification (B3)
- [x] `py_compile`
- [x] pytest: push payload includes `image`/photo URL for like/match/message (added to `test_notifications.py`)
- [x] pytest: no push to self for liked action (added to `test_notifications.py`)

---

## Part 4 — Mobile: deps & native config (Android push)

- [ ] **M4-1** `pubspec.yaml` — add:
  - [ ] `firebase_core`
  - [ ] `firebase_messaging`
- [ ] **M4-2** `android/app/src/main/AndroidManifest.xml`:
  - [ ] add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`
  - [ ] verify default notification channel works (Firebase plugin auto-creates)
- [ ] **M4-3** iOS: **no changes now** (deferred). WS realtime still works. Leave `AppDelegate.swift` untouched.

### Verification (M4)
- [ ] `flutter pub get` succeeds
- [ ] `flutter analyze` clean

---

## Part 5 — Mobile: FCM token registration service

New file `lib/services/push_service.dart`:

- [ ] **M5-1** `initPush()` — called once after login at app start:
  - [ ] `Firebase.initializeApp()` (or rely on `firebase_core` default)
  - [ ] `FirebaseMessaging.instance.requestPermission()` (Android 13+)
  - [ ] `getToken()` → `POST /notifications/device-token` `{token, platform:"android"}`
- [ ] **M5-2** token refresh:
  - [ ] subscribe `onTokenRefresh` → re-register token
- [ ] **M5-3** foreground message `onMessage`:
  - [ ] parse payload → fire callback → show custom notification toast
  - [ ] do not duplicate with WS toast (dedupe by notification id)
- [ ] **M5-4** background/terminated `onMessageOpenedApp` + `getInitialMessage`:
  - [ ] if `data.type` is liked/match → navigate to `UserNotificationProfileScreen` with `data.user_id`
  - [ ] if `data.type` is system → open announcement dialog
  - [ ] if `data.type` is message → navigate to chat detail (`data.chat_id`)
- [ ] **M5-5** logout hook: optionally `DELETE /notifications/device-token/{id}` and dispose listeners
- [ ] Add `registerDeviceToken` / `deleteDeviceToken` to `lib/services/chat_service.dart` (endpoints exist)

### Verification (M5)
- [ ] `flutter analyze` clean
- [ ] Manual: app start registers token (check DB row); token refreshed on change

---

## Part 6 — Mobile: custom notification toast

New file `lib/widgets/notification_toast.dart` (distinct from API `action_toast`):

- [ ] **M6-1** `showNotificationToast({title, body, type, onSeeDetails})`:
  - [ ] own `OverlayEntry` + `_currentNoticeEntry` (independent of `action_toast`'s `_currentEntry`)
- [ ] **M6-2** Styling — Bondi tokens only:
  - [ ] floating card at top, `BorderRadius.circular(AppTheme.radiusModule)` (16, not pill)
  - [ ] surface `AppTheme.moduleFillNeutral(isDark)` + `AppTheme.shadowModule(isDark)` + thin border (`lightBorder`/`darkBorder`)
  - [ ] padding ~ `EdgeInsets.fromLTRB(16, 12, 12, 12)`
  - [ ] leading icon in small gradient circle (`primaryGradient()` / `likeGradient()` per type)
  - [ ] title `bodyBold` 15, body `body`/`caption` muted
  - [ ] **"See details"** text button — `lightPrimary`/`darkPrimary`, bold, compact
  - [ ] slide/fade entrance, auto-dismiss ~5s, tappable body dismisses
- [ ] **M6-3** Navigation wiring:
  - [ ] liked/match → `UserNotificationProfileScreen(userId, fallback)`
  - [ ] system → announcement dialog
- [ ] **M6-4** i18n: add "See details" key to `app_en.arb` + `app_fa.arb`; run `flutter gen-l10n`

### Verification (M6)
- [ ] `flutter gen-l10n` succeeds; keys present in both ARB files
- [ ] `flutter analyze` clean
- [ ] Manual: WS event → toast appears; See details navigates correctly

---

## Part 7 — Mobile: provider & real-time wiring

- [ ] **M7-1** `lib/providers/chat_provider.dart`:
  - [ ] expose `Stream<Map<String,dynamic>> get socketEvents` (wraps `_socketService!.events`)
- [ ] **M7-2** `lib/providers/notifications_provider.dart`:
  - [ ] add `int unreadTotal`, `Map<String,int> unreadByType`
  - [ ] `refreshUnread()` → `GET /notifications/counts` (no cache)
  - [ ] subscribe to `socketEvents` (via a setter `attachSocket(ChatProvider)` or a `StreamSubscription`):
    - [ ] on `new_notification` → `refreshUnread()` + emit an in-app notice stream (for toast) + prepend item to `_notifications` if on screen
  - [ ] after `markRead` / `deleteNotification` → recompute counts locally (or `refreshUnread()`)
  - [ ] getters: `unreadFor(type)` helper for section pills
- [ ] **M7-3** `lib/main.dart`:
  - [ ] after `connectSessionSocket()` (in `main_screen.dart` post-login) call `NotificationsProvider.attachSocket(...)`
  - [ ] start `initPush()` post-login
- [ ] **M7-4** Dedupe: toast triggered by WS **and** FCM for same id → guard by notification id timestamp

### Verification (M7)
- [ ] `flutter analyze` clean
- [ ] Manual: like/match → badge + toast update without leaving screen

---

## Part 8 — Mobile: bell badge & section pills

- [ ] **M8-1** New `lib/widgets/notification_bell.dart`:
  - [ ] `IconButton` + red count pill (`Stack`, `Clip.none`)
  - [ ] shows `unreadTotal`, hides at 0, caps at `99+`
  - [ ] pill styling: small, bold white text on `AppTheme.accentLike`/error, radius pill
- [ ] **M8-2** `lib/screens/chats/chats_screen.dart:115` — replace bell `IconButton` with `NotificationBell` (watch `NotificationsProvider.unreadTotal`)
- [ ] **M8-3** `lib/screens/search/search_screen.dart:143` — same replacement
- [ ] **M8-4** `lib/screens/chats/notifications_screen.dart`:
  - [ ] section headers show a count pill from `unreadByType` (like→Liked, liked→Likes, match→Matches, system→Announcements)
  - [ ] pill hidden when 0

### Verification (M8)
- [ ] `flutter analyze` clean
- [ ] Manual: unread grows → bell pill + section pills update; marking read decrements

---

## Part 9 — i18n & regression

- [ ] **M9-1** New/changed strings (`app_en.arb` + `app_fa.arb`):
  - [ ] `notifications_see_details` — "See details" / «مشاهده جزئیات»
  - [ ] (existing `notifications_section_*`, `notifications_empty_section`, `notifications_close` already added)
- [ ] **M9-2** `flutter gen-l10n` regenerated; keys present in both ARB files
- [ ] **M9-3** Regression checklist:
  - [ ] `flutter analyze` → 0 errors
  - [ ] backend changed files `py_compile`
  - [ ] backend tests run one file at a time: `test_notifications.py` (+ any affected)
  - [ ] No regression to existing action toast (separate OverlayEntry)
  - [ ] 4-section screen still works with empty/partial data
  - [ ] message notifications never appear in sections

---

## Part 10 — Execution order (traceable milestones)

1. **P1** ✅ Backend WS `new_notification` events + tests → green
2. **P2** ✅ Backend counts endpoint + tests → green
3. **P3** ✅ Backend push avatar (image_url) + tests → green
4. **P4** 📋 Mobile deps + Android native config (M4) — **next**
5. **P5** 📋 Mobile FCM service (M5)
6. **P6** 📋 Mobile custom notification toast (M6)
7. **P7** 📋 Mobile provider + real-time wiring (M7)
8. **P8** 📋 Mobile bell badge + section pills (M8)
9. **P9** 📋 i18n + regression (§9)

---

## Open follow-ups (out of scope for now)

- [ ] iOS system push: needs APNs key/cert + `AppDelegate.swift` Firebase init (deferred by decision)
- [ ] Compact-row avatar in the system tray requires an Android `NotificationService` + local avatar cache (BigPicture used for now)
