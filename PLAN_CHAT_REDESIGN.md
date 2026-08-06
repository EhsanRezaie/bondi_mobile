# Plan — Chat Sub-Sections + Real-time + Notifications + Message Buttons + Presence

Status: **Planned** (implementation not started)
Repos: backend `C:\Users\Ehsan\Desktop\project_d` · mobile `C:\Users\Ehsan\Desktop\project_d_mobile`
Docs precedent: `project_d/PLAN_CHAT_MODEL.md`

---

## 0. Decisions locked in (from conversation)

- Replace the match/conversation split with **3 chat tabs**: **Conversations** (default) / **Pending** / **Incoming**.
  - Conversations = `status == "accepted"`.
  - Pending = `status == "pending"` **and I am the initiator** (I started it, awaiting their accept).
  - Incoming = `status == "pending"` **and I am the recipient** (they started it, awaiting my accept).
- Old Liked-Me / Matches / Likers match-list UI is **removed from the app**. Backend `/matches`, `/swipes/*` stay untouched.
- Pagination: each section loads **page size 20** (backend `limit` default already 20; add `status` filter + expose `initiator_id`).
- Real-time chat list strategy: **refetch page 1** of the affected section on WS event (server-accurate ordering/preview/unread).
- Notifications: 4 types (message, match, like, system), backed by existing `/api/v1/notifications`, page size 20, mark-read, delete.
- Notification bell moves from Discover top-right → Chats top-left; tap → notifications screen.
- Discover/Search **message button** = pure chat start via `POST /chats` (no like). If `is_new == false` (chat exists) → just redirect to the chat screen, do **not** send typed message.
- Chat header presence: green dot on avatar corner + live subtitle (Online / Last seen X).
- Typing indicator: animated **3-dot bubble** appended as a temporary received message (NOT a top-bar label).

### Backend capabilities verified today
| Capability | Where |
|---|---|
| `/chats` list with `limit`/`offset`/`next_offset`/`total` | `project_d/app/api/v1/endpoints/chats.py:280` |
| `POST /chats` create (existing→`is_new:false`, new→`is_new:true`+first msg) | `chats.py:85` |
| `POST /chats/{id}/accept` (recipient-only) | `chats.py:231` |
| `/chats/{id}` detail (`initiator_id`, `recipient_id`) | `chats.py:403` |
| WS per-chat `ws:chat:{id}` (new_message, user_online/offline, typing, read) | `websocket/chat.py`, `websocket_manager.py` |
| WS personal `ws:user:{id}` via `/ws/matches` (new_match, new_chat) | `websocket/matches.py`, `websocket_manager.py:217` |
| `/notifications` list/read/delete | `endpoints/notifications.py`, `schemas/notification.py` |
| **Missing**: list `status` filter, `initiator_id` in `ChatItemResponse`, personal-channel `chat_updated`/`chat_accepted`, offline timestamp in WS, `hide_last_seen` respect | — |

---

## Part 1 — Backend: `/chats` list filters & direction

**Goal:** let mobile split 3 tabs server-side with clean per-tab pagination.

- [ ] **B1-1** `project_d/app/schemas/chat.py` — add `initiator_id: UUID` to `ChatItemResponse`.
- [ ] **B1-2** `project_d/app/api/v1/endpoints/chats.py` `list_chats` (`:280`):
  - [ ] add `status: Optional[str] = Query(None, pattern="^(accepted|pending)$")`
  - [ ] apply `Chat.status == status` when provided (before pagination)
  - [ ] compute `total` / `next_offset` on the filtered set
  - [ ] populate `initiator_id` in rows + `ChatItemResponse`
- [ ] **B1-3** Tests in `project_d/tests/done/test_chats.py`:
  - [ ] list filter `status=accepted`
  - [ ] list filter `status=pending`
  - [ ] `initiator_id` present & correct per user
  - [ ] pagination (limit/offset/next_offset) correct under filter
  - [ ] no-filter backward compatible (returns both statuses)

### Verification (B1)
- [ ] Start test infra: `docker compose -f docker-compose.test.yml up -d`
- [ ] `pytest tests/done/test_chats.py -v` → all green
- [ ] Stop infra: `docker compose -f docker-compose.test.yml down`

---

## Part 1b — Backend: real-time chat-list events on the personal channel

**Goal:** when a message arrives / chat is accepted while the user views the chat list, the recipient gets a WS event to trigger a page-1 refetch.

- [ ] **B1b-1** `project_d/app/api/v1/endpoints/messages.py` — in text send (`:268`), photo send (`:337`), voice send (`:407`):
  - [ ] after `send_to_conversation`, also `send_personal_message` to **recipient** with:
    `{"type":"chat_updated","data":{chat_id, status, unread_count, updated_at, last_message:{content,message_type,sent_at}}}`
  - [ ] extract a small shared builder (reuse list-row shape from `chats.py`) to keep one source of truth
- [ ] **B1b-2** `project_d/app/api/v1/endpoints/chats.py` `accept_chat` (`:258`):
  - [ ] in addition to the chat-channel `chat_accepted`, publish `chat_accepted` to **both** users' personal channels (`send_personal_message`), data `{chat_id, status, accepted_by}`
- [ ] **B1b-3** Keep existing `new_chat` personal push on create (`chats.py:198`).
- [ ] **B1b-4** Tests:
  - [ ] recipient personal channel receives `chat_updated` on text/photo/voice send
  - [ ] sender personal channel receives `chat_accepted` on accept
  - [ ] recipient personal channel receives `chat_accepted` on accept
  - [ ] `new_chat` still delivered on create

### Verification (B1b)
- [ ] `pytest tests/done/test_messages.py -v` → green (one file at a time)
- [ ] `pytest tests/done/test_chats.py -v` → green
- [ ] Stop infra

---

## Part 2 — Mobile: models & services

**Goal:** DTOs + HTTP layer matching the backend exactly.

### 2a. ChatCard models
- [ ] **M2-1** New `lib/models/chat_card.dart`:
  - [ ] `ChatCard` — `id, status, initiatorId, unreadCount, updatedAt`
  - [ ] `ChatUser` — `id, name, age, mainPhotoUrl, isOnline, lastSeenAt`
  - [ ] `ChatLastMessage` — `content, messageType, isSent, isRead, sentAt`
  - [ ] `fromJson`/`toJson` matching `ChatItemResponse`/`ChatUserResponse`/`ChatLastMessage` keys

### 2b. Notification model
- [ ] **M2-2** New `lib/models/notification.dart`:
  - [ ] `Notification` — `id, type, title, body, data, isRead, createdAt`
  - [ ] `fromJson` matching `NotificationResponse` keys (`id,type,title,body,data,is_read,created_at`)

### 2c. ChatService changes
- [ ] **M2-3** `lib/services/chat_service.dart`:
  - [ ] replace `getConversations` (dead `/conversations`) → `getChats({limit, offset, status})` hitting `/chats`
  - [ ] add `createChat(String userId, String content)` → `POST /chats {user_id, content}`
  - [ ] fix `acceptChat` → `POST /chats/{chat_id}/accept` (currently wrong `/messages/$id/accept`)
  - [ ] add `getNotifications({limit, offset})` → `GET /notifications`
  - [ ] add `markNotificationsRead(List<String> ids)` → `POST /notifications/read` (204)
  - [ ] add `deleteNotification(String id)` → `DELETE /notifications/{id}` (204)

### Verification (M2)
- [ ] `flutter analyze` → no new errors
- [ ] No remaining references to `/conversations` or `sendFirstMessage` message-button path in services

---

## Part 3 — Mobile: chat list 3 tabs + real-time socket

### 3a. ChatProvider state & loaders
- [ ] **M3-1** `lib/providers/chat_provider.dart`:
  - [ ] replace match-based `_conversations` with `List<ChatCard>` for `_conversations`, `_pendingChats`, `_incomingChats`
  - [ ] each bucket gets own `offset` + `hasMore`; drop match-tab usage (`_matches`, `loadMatches`)
  - [ ] `loadConversations()` → `getChats(status: accepted)`
  - [ ] `loadPendingChats()` → `getChats(status: pending)` filtered `initiatorId == myUserId`
  - [ ] `loadIncomingChats()` → `getChats(status: pending)` filtered `initiatorId != myUserId`
  - [ ] `loadMore*()` per bucket (page size 20, `next_offset`)
  - [ ] `acceptChat(chatId)` → new endpoint; on success move card from Pending/Incoming → Conversations

### 3b. Real-time (refetch strategy)
- [ ] **M3-2** New `lib/services/chat_list_websocket_service.dart` — persistent connection to `/ws/matches?token=` (personal channel) started at app launch.
- [ ] **M3-3** `ChatProvider` subscribes to personal-channel events:
  - [ ] `chat_updated` → refetch page 1 of the affected section + refresh unread badges
  - [ ] `chat_accepted` → refetch Pending + Incoming + Conversations
  - [ ] `new_chat` → refetch Pending/Incoming
  - [ ] guard against duplicate refetches (debounce/min-interval)

### 3c. Screens
- [ ] **M3-4** `lib/screens/chats/chats_screen.dart`:
  - [ ] keep `TabController(length: 3)` → tabs **Conversations (default) / Pending / Incoming**
  - [ ] each tab renders generalized chat list
  - [ ] AppBar `leading` = bell icon → push `NotificationsScreen`
- [ ] **M3-5** Generalize `lib/screens/chats/chat_list_screen.dart` to accept a `List<ChatCard>` + optional `onAccept` callback; replace `Match`/`match.user` access.
- [ ] **M3-6** Retire from UI: `lib/screens/chats/i_liked_screen.dart`, `liked_me_screen.dart`, match tab, `matched_avatar_strip`.
- [ ] **M3-7** `lib/screens/discover/discover_screen.dart` — remove no-op bell in AppBar actions (`:517-523`).

### Verification (M3)
- [ ] `flutter analyze` → clean
- [ ] Manual: 3 tabs load correct buckets; scroll pagination works; incoming shows Accept action; accept moves chat to Conversations

---

## Part 4 — Mobile: notifications screen

- [ ] **M4-1** New `lib/providers/notifications_provider.dart`:
  - [ ] state: list, total, nextOffset, isLoading, isLoadingMore, unreadCount
  - [ ] `loadNotifications()`, `loadMoreNotifications()` (page 20)
  - [ ] `markRead(id)`, `markAllRead()`, `deleteNotification(id)`
- [ ] **M4-2** New `lib/screens/notifications/notifications_screen.dart`:
  - [ ] 4-type rendering (message/match/like/system) with icons
  - [ ] relative-time formatting (`formatLastSeen`/new formatter)
  - [ ] unread highlight/dot; pull-to-refresh; infinite scroll
  - [ ] swipe-to-delete; tap → markRead + deep-link (message/match→chat, like→profile, system→dialog)
  - [ ] empty state
- [ ] **M4-3** Wire real-time: refresh notifications list on personal-channel events (new_message/new_match/like).

### Verification (M4)
- [ ] `flutter analyze` clean
- [ ] Manual: list loads from `/notifications`, pagination, mark-read, delete, empty state

---

## Part 5 — Mobile: i18n & wiring

- [ ] **M5-1** `lib/l10n/app_en.arb` + `app_fa.arb`:
  - [ ] tab labels (Conversations / Pending / Incoming)
  - [ ] notification title/body templates (message/match/like/system)
  - [ ] accept button, mark-all-read, delete, empty-state strings
  - [ ] online/last-seen/typing strings
- [ ] **M5-2** Run `flutter gen-l10n`
- [ ] **M5-3** `lib/main.dart` — register `NotificationsProvider`; start global chat-list socket

### Verification (M5)
- [ ] `flutter gen-l10n` succeeds; keys present in both ARB files
- [ ] `flutter analyze` clean

---

## Part 6 — Mobile: Discover & Search message buttons → `POST /chats` + redirect

**Problem found:** all message-button entry points call like + `sendFirstMessage` → `POST /messages/{user_id}/text` which no longer exists (endpoint keys on `chat_id`). They would 404.

- [ ] **M6-1** `lib/services/chat_service.dart` — `createChat` (created in M2-3).
- [ ] **M6-2** `lib/providers/discover_provider.dart` — rework `swipeAndChat` (`:224`) → call `createChat(profile.id, message)`, return `{chat_id, is_new, status}` (null on failure/429). Drop the like + drop `sendFirstMessage`.
- [ ] **M6-3** `lib/providers/search_provider.dart` — rework `chatWithUser` (`:465`) same way.
- [ ] **M6-4** `lib/screens/chats/user_notification_profile_screen.dart` `_handleChat` (`:120`) — same rework.
- [ ] **M6-5** Screens — after result, navigate to `ChatDetailScreen(identifier: chat_id, userName, avatarUrl, isOnline, lastSeenAt)`:
  - [ ] `discover_screen.dart` `_handleChat` (`:80`) + `_onChatPressed` (`:189`): remove match-dialog branch & card swipe-out on chat tap; redirect to chat
  - [ ] `search/profile_detail_screen.dart` + `search_profile_detail.dart` `_handleChat` (`:769`): redirect to chat; keep `_showMatchDialog` for the **like** path only
- [ ] **M6-6** Keep like-button paths untouched (`discover_provider.swipeRight`, `search_provider.likeUser`).

### Verification (M6)
- [ ] `flutter analyze` clean
- [ ] Manual: message button on Discover/Search → new chat opens; if chat exists → direct redirect (no duplicate message, no extra slot)

---

## Part 7 — Mobile & backend: real-time presence + typing bubble

### 7a. Real-time last-seen
- [ ] **B7-1** `project_d/app/api/v1/websocket/chat.py:128` — include offline timestamp: `{"type":"user_offline","user_id":..., "last_seen_at": <utcnow iso>}`
- [ ] **M7-1** `lib/providers/chat_provider.dart` — add `DateTime? _otherUserLastSeenAt`; set from detail/list load; update on `user_offline` (`data['last_seen_at']`); null on `user_online`; getter.
- [ ] **M7-2** `lib/screens/chats/chat_detail_screen.dart:256-257` — pass live `provider.otherUserLastSeenAt` (not static `widget.lastSeenAt`).

### 7b. Presence dot next to avatar
- [ ] **M7-3** `lib/widgets/chat_app_bar.dart` — wrap `CircleAvatar` in `Stack`; overlay green presence dot on corner when `isOnline`; keep live subtitle (`OnlineIndicator`).

### 7c. Typing = animated 3-dot bubble message
- [ ] **M7-4** New `lib/widgets/typing_bubble.dart` — received-style bubble containing 3 dots with looping animation (AnimationController).
- [ ] **M7-5** `lib/screens/chats/chat_detail_screen.dart` — replace top-bar typing label (currently `:324-334`) with appended temp bubble row at bottom of message list when `provider.isTyping`.

### 7d. `hide_last_seen` respect (small)
- [ ] **B7-2** `project_d/app/api/v1/endpoints/chats.py` list (`:386`) + detail (`:442`) — return `last_seen_at=None` when user settings `hide_last_seen` is true.

### Tests (Part 7)
- [ ] backend: offline WS payload includes `last_seen_at`; detail/list honor `hide_last_seen`
- [ ] run affected files one at a time; stop infra after

### Verification (M7)
- [ ] `flutter analyze` clean
- [ ] Manual: dot shows/hides live; subtitle shows live Online/Last seen; typing shows 3-dot bubble in the thread

---

## 8. Regression checklists (run at end)

### Backend
- [ ] All affected files green (run one file at a time): `test_chats.py`, `test_messages.py`, `test_notifications.py`, `test_chat_websocket*.py`
- [ ] Infra stopped after each run

### Mobile
- [ ] `flutter analyze` → 0 errors
- [ ] `flutter gen-l10n` regenerated
- [ ] No dangling imports of retired screens (`i_liked_screen`, `liked_me_screen`, `matched_avatar_strip`, `user_notification_profile_screen` if retired — verify usage)
- [ ] `POST /conversations` no longer referenced anywhere in `lib/`
- [ ] Existing tests preserved (do not delete); add missing scenarios where noted

---

## 9. Execution order (traceable milestones)

1. **P1** Backend `/chats` filters + tests → green
2. **P1b** Backend personal-channel events + tests → green
3. **P2** Mobile models + services (ChatCard, Notification, ChatService)
4. **P3** Mobile 3 tabs + provider buckets + global real-time socket
5. **P4** Mobile notifications screen + provider
6. **P5** i18n + wiring (ARB, gen-l10n, main.dart)
7. **P6** Mobile message buttons → `POST /chats` + redirect
8. **P7** Presence (backend + mobile) + typing bubble + `hide_last_seen`
9. **§8** Full regression (backend per-file + mobile analyze)
