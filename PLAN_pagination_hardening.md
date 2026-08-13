# Plan — Pagination hardening for other paging APIs

Scope: tiered (approved). Cursor keyset for discover + chats (real duplicate bugs);
id tiebreakers for append-only lists (offset stays safe). Mobile changes limited to
discover + chats.

## Backend — C:\Users\Ehsan\Desktop\project_d

- [x] 1. `GET /discover` (`app/api/v1/endpoints/discover.py`): add `ORDER BY User.last_seen_at DESC NULLS LAST, User.id DESC`, port `_encode_cursor`/`_decode_cursor`, add `cursor` query param, keyset WHERE (+ null-tail branch), keep offset path, emit `next_cursor` when has_more.
- [x] 2. `app/schemas/discover.py`: add `next_cursor: Optional[str] = None` to `DiscoverResponse`.
- [x] 3. `GET /chats` (`app/api/v1/endpoints/chats.py`): Python-side keyset slicing on computed `updated_at` + `cursor` param; keep offset path; emit `next_cursor`.
- [x] 4. `app/schemas/chat.py`: add `next_cursor: Optional[str] = None` to `ChatListResponse`.
- [x] 5. Id tiebreakers:
  - [x] matches.py:58 → `matched_at.desc(), Match.id.desc()`
  - [x] swipes.py:420, 534 → `created_at.desc(), Swipe.id.desc()`
  - [x] notifications.py:51 → `created_at.desc(), Notification.id.desc()`
  - [x] messages.py:191 → `sent_at.desc(), Message.id.desc()`
  - [x] blocks.py:192 → `created_at.desc(), Block.id.desc()`
  - [x] tickets.py:65 → `created_at.desc(), Ticket.id.desc()`
  - [x] reports.py:196 → `created_at.desc(), Report.id.desc()`
- [x] 6. Tests: `TestDiscoverCursorPagination` (7 tests) + `TestChatsCursorPagination` (4 tests) — walk no-dup, shift mid-scroll, ties, null tail, malformed cursor.
- [x] 7. Verify: `compileall` ok + pytest — search/discover/chats/notifications/matches/swipes/blocks = 160 passed.

## Mobile — C:\Users\Ehsan\Desktop\project_d_mobile

- [x] 8. `discover_service.dart`: add `cursor` param.
- [x] 9. `discover_provider.dart`: `_offset` → `_nextCursor` + `_seenUserIds` dedup.
- [x] 10. `chat_service.dart`: add `cursor` param to conversations + pending list calls.
- [x] 11. `chat_provider.dart`: conversations + pending → cursor + dedup (matches/likers/liked/messages untouched).
- [x] 12. Verify: `flutter analyze` — 5 issues, all pre-existing in `test/responsive/responsive_layout_manual_rows_test.dart`, none in edited files.

Notes:
- Discover deck order changes to most-recently-online-first (intended).
- Chats cursor slices the already-in-memory sorted list — no new query.
- Offset/`next_offset` paths preserved for backward compat everywhere.
