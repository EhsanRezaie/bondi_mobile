# PLAN — Support Ticket System (ticketing flow)

Adds an end-to-end support ticket flow: users create tickets with a predefined subject +
message, admins reply in a conversation thread, and users track status from the app.

Three repos are involved:

| Repo | Path | Remote | CI deploy |
|---|---|---|---|
| Backend (FastAPI) | `C:\Users\Ehsan\Desktop\project_d` | `github.com/EhsanRezaie/bondi.git` | push to `main` (deploy.yml: migrations check → tests → SSH deploy) |
| Admin panel (Vite/React) | `C:\Users\Ehsan\Desktop\bondi_admin` | `github.com/EhsanRezaie/bondi_admin.git` | push to `main` (build+typecheck → SCP → compose up) |
| Mobile app (Flutter) | `C:\Users\Ehsan\Desktop\project_d_mobile` | `github.com/EhsanRezaie/bondi_mobile.git` | push (flutter_test.yml / flutter_e2e.yml) |

## Product decisions (confirmed with user)

- Ticket subjects (predefined, plus **Other** where the user explains in the message):
  1. Account / Login issue
  2. Photo verification
  3. Payment / Premium
  4. Report a problem (bug)
  5. Other
  - No "Report a user" — a separate report system already exists.
- App entry point: **headphones icon top-left** (`AppBar.leading`) of the Profile screen → "My Tickets" list.
- Admin panel: upgrade the ticket drawer to show the **full conversation thread** and reply inline.

## Backend API (already implemented in working tree — verify + push)

- `POST /api/v1/tickets` — create ticket (subject 3–200, message 10–2000). Seeds first message.
- `GET  /api/v1/tickets` — my tickets (offset pagination).
- `GET  /api/v1/tickets/{id}` — ticket detail + messages.
- `POST /api/v1/tickets/{id}/messages` — user reply (reopens closed tickets).
- `GET  /api/v1/admin/tickets` — admin list (status filter).
- `GET  /api/v1/admin/tickets/{id}` — admin detail + conversation.
- `POST /api/v1/admin/tickets/{id}/messages` — admin reply (no status change).
- `PATCH /api/v1/admin/tickets/{id}` — status change (+ legacy admin_response).
- `DELETE /api/v1/admin/tickets/{id}` — delete.
- New table `ticket_messages` via migration `f8a2c9e05b1d` (backfills existing tickets).

## Traceable checks

### 1. Backend — verify & deploy
- [ ] `docker compose -f docker-compose.test.yml up -d` (db_test, redis_test, minio)
- [ ] `pytest tests/done/test_tickets.py tests/done/test_admin_tickets.py -v` passes
- [ ] `pytest tests/done/ -v` full suite passes
- [ ] `git diff --stat` reviewed (tickets + migration only)
- [ ] Commit + push `origin/main` → CI runs migrations check + tests + auto-deploy
- [ ] Confirm migration chain: `f8a2c9e05b1d` → `ad655e0fe278` (current head)

### 2. Admin panel — conversation thread
- [ ] `src/api/tickets.ts` adds `replyTicket(id, content)` → `POST /admin/tickets/{id}/messages`
- [ ] `TicketsPage.tsx` drawer renders `detail.messages` thread (user/admin + timestamps)
- [ ] Reply box posts via `replyTicket`; status buttons still PATCH
- [ ] `npm run typecheck` passes
- [ ] `npm run build` passes
- [ ] Commit + push `origin/main` → CI deploys

### 3. Mobile app — ticketing flow
- [ ] `lib/models/ticket.dart` (Ticket, TicketMessage, TicketListPage + fromJson)
- [ ] `lib/services/ticket_service.dart` (create/list/detail/reply)
- [ ] `lib/providers/ticket_provider.dart` (list+paging, create, detail, reply, errors)
- [ ] `lib/screens/profile/tickets_screen.dart` (list, status chips, empty state, New Ticket)
- [ ] `lib/screens/profile/create_ticket_screen.dart` (subject dropdown + message)
- [ ] `lib/screens/profile/ticket_detail_screen.dart` (conversation + reply, reopen note)
- [ ] `profile_screen.dart` AppBar `leading` headphones icon → TicketsScreen
- [ ] `main.dart` registers TicketProvider
- [ ] `app_en.arb` + `app_fa.arb` keys added; `flutter gen-l10n` regenerates
- [ ] Unit tests: `test/unit/models/ticket_test.dart`, `test/unit/providers/ticket_provider_test.dart`
- [ ] Widget test: tickets list; `profile_screen_test.dart` checks headphones icon
- [ ] `flutter analyze` clean
- [ ] `flutter test` passes
- [ ] Commit + push

## File map (mobile app)

```
lib/models/ticket.dart
lib/services/ticket_service.dart
lib/providers/ticket_provider.dart
lib/screens/profile/tickets_screen.dart
lib/screens/profile/create_ticket_screen.dart
lib/screens/profile/ticket_detail_screen.dart
```

### Status → color mapping (theme tokens)
- open → `lightWarning` / `darkWarning`
- in_progress → `lightPrimary` / `darkPrimary`
- closed → `lightSuccess` / `darkSuccess`

### Subject IDs (localized)
`account_login`, `photo_verification`, `payment_premium`, `bug`, `other`

## Progress log (updated as I work)

- [x] Plan created
- [x] Backend: ticket tests (35) + full suite (779) pass locally; committed `1c1a3cd` & pushed `main` → CI auto-deploy running
- [x] Admin panel: conversation thread + `replyTicket` API wired; pushed `592bd55` (typecheck/build verified by CI — Node not installed locally)
- [x] Mobile: model/service/provider + 3 screens + profile headset icon + provider registration + ARB localization
- [x] Mobile: `flutter analyze` clean; full suite `flutter test` → 397 passed
- [x] Mobile: committed & pushed (see commit below)

### Checkboxes
- [x] `lib/models/ticket.dart`
- [x] `lib/services/ticket_service.dart`
- [x] `lib/providers/ticket_provider.dart`
- [x] `lib/screens/profile/tickets_screen.dart`
- [x] `lib/screens/profile/create_ticket_screen.dart`
- [x] `lib/screens/profile/ticket_detail_screen.dart`
- [x] `profile_screen.dart` AppBar `leading` headphones icon → TicketsScreen
- [x] `main.dart` registers TicketProvider
- [x] `app_en.arb` + `app_fa.arb` keys; `flutter gen-l10n` regenerated
- [x] Unit tests: `ticket_test.dart`, `ticket_provider_test.dart`
- [x] Widget test: `tickets_screen_test.dart`; `profile_screen_test.dart` headset icon
- [x] `flutter analyze` clean
- [x] `flutter test` → 397 passed
