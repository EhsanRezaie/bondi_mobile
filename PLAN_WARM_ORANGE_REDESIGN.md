# Bondi App — Warm Orange Full Redesign Plan

> Branch: `warm_orange` · Build: `lib/` only (widget build, layout structure, theme/token files).
> Status legend: `[ ]` = not started · `[~]` = in progress · `[x]` = done · `[!]` = blocked/needs decision.
> Rule: **same screens, same functionality, same navigation.** Visual/layout freedom only.
> Every screen must pass the responsiveness check at all 5 sizes before its checkbox is marked done.

---

## 0. Step 0 — Baseline Audit (complete)

### 0.1 Screen inventory (31) — source of truth for "same screens"

**Auth / entry (4)**
- [x] `lib/screens/splash_screen.dart` — splash with animated progress, retry on server-down
- [x] `lib/screens/login_screen.dart`
- [x] `lib/screens/auth/sign_up_screen.dart`
- [x] `lib/screens/auth/verify_code_screen.dart` (OTP 6-digit, forced LTR)

**Onboarding (5)**
- [x] `lib/screens/onboarding/basic_info_screen.dart`
- [x] `lib/screens/onboarding/profile_details_screen.dart`
- [x] `lib/screens/onboarding/interests_screen.dart`
- [x] `lib/screens/onboarding/prompts_screen.dart`
- [x] `lib/screens/onboarding/photo_upload_screen.dart`

**Discover (2)**
- [x] `lib/screens/discover/discover_screen.dart` (swipe stack)
- [x] `lib/screens/discover/profile_detail_screen.dart`

**Search (3)**
- [x] `lib/screens/search/search_screen.dart`
- [x] `lib/screens/search/search_profile_detail.dart`
- [x] `lib/screens/search/search_filter_sheet.dart` (bottom sheet)

**Profile (8)**
- [x] `lib/screens/profile/profile_screen.dart`
- [x] `lib/screens/profile/settings_screen.dart`
- [x] `lib/screens/profile/edit_basic_info_screen.dart`
- [x] `lib/screens/profile/edit_profile_details_screen.dart`
- [x] `lib/screens/profile/edit_interests_screen.dart`
- [x] `lib/screens/profile/edit_prompts_screen.dart`
- [x] `lib/screens/profile/edit_photos_screen.dart`
- [x] `lib/screens/profile/avatar_crop_screen.dart`

**Chats (7)**
- [x] `lib/screens/chats/chats_screen.dart` (TabBar: Liked Me / I Liked / Chats + avatar strip)
- [x] `lib/screens/chats/chat_list_screen.dart`
- [x] `lib/screens/chats/chat_detail_screen.dart`
- [x] `lib/screens/chats/notifications_screen.dart`
- [x] `lib/screens/chats/liked_me_screen.dart`
- [x] `lib/screens/chats/i_liked_screen.dart`
- [x] `lib/screens/chats/user_notification_profile_screen.dart`

**Shared (1)**
- [x] `lib/screens/shared/profile_detail_loader.dart` (loader/pass-through)

**Root (2)**
- [x] `lib/screens/main_screen.dart` (bottom nav)
- [x] `lib/` entrypoint `lib/main.dart` (MultiProvider + MaterialApp)

### 0.2 Shared widgets (14)
- [x] `user_card.dart` — swipe card (Mode A primary surface)
- [x] `discover_action_button.dart` — circular like/pass/chat buttons
- [x] `search_grid_card.dart`
- [x] `matched_avatar_strip.dart`
- [x] `chat_message_bubble.dart`
- [x] `chat_input_bar.dart`
- [x] `chat_app_bar.dart`
- [x] `typing_indicator.dart`
- [x] `online_indicator.dart`
- [x] `shimmer_avatar.dart`
- [x] `loading_widget.dart`
- [x] `progress_bar.dart` (onboarding)
- [x] `voice_message_player.dart`
- [x] `action_toast.dart`

### 0.3 Navigation graph (must not change)
- No named routes. All imperative `Navigator.push` / `pushReplacement` / `showModalBottomSheet` / `showDialog`.
- Splash (server down → stay + Retry) → MainScreen | LoginScreen.
- MainScreen: `BottomNavigationBar(fixed)` + `IndexedStack`, 4 tabs — Search(0), **Discover(1, default)**, Chats(2), Profile(3). Tab data-refresh side effect on Chats tab tap (loadConversations / loadPendingIncoming / refreshLimits) — keep, not a visual concern.
- MainScreen auto-routes: incomplete profile → BasicInfoScreen; <3 photos → PhotoUploadScreen; unauthenticated → LoginScreen.
- 19 `Navigator.push` + 18 `pushReplacement` + 18 `showModalBottomSheet` + 13 `showDialog` (+1 `pushAndRemoveUntil` on logout). **Preserve all.**

### 0.4 Token file & call-site census
- Token file: `lib/config/app_theme.dart` (615 lines) — `lightTheme`/`darkTheme`, `lightX`/`darkX` constants, text styles, button styles, `ThemeColors` context extension.
- 466 call sites: `isDark ? AppTheme.darkX : AppTheme.lightX`
- 398 call sites: `Colors.*`  ·  10 sites: raw `Color(0x...)`
- 332 sites: hardcoded `fontFamily: 'Inter'` (grants NOT bundled; google_fonts unused → falls back to Roboto today)
- ~17 distinct radius values (r2…r28) across 247 lines in 33 files
- Responsive helper exists: `lib/utils/responsive.dart` (`AppLayout.s()`, `isTablet`, `contentWidth`, `box`)

### 0.5 Feature/data facts that constrain visuals
- Dark mode: binary, persisted `'dark_mode'` + backend PATCH; `themeMode` in main.dart.
- Locale: persisted `'selected_language'`; `MaterialApp.locale`. **No RTL, no Directionality wrapper today** (only forced-LTR OTP). Bottom-nav order fixed as implemented — do not reverse.
- Numerals: Western digits at runtime (Persian glyphs only as literal text inside `app_fa.arb`). Keep Western.
- Chat state tracks: text/photo/voice, edit, delete (for me/everyone), typing, online/last-seen, 2-message initiation limit, unread counts. **No reactions/forward — do not add.**
- Voice messages exist (hidden on web). Phone exist? **No call feature — do not add call button.**
- Read-receipt ticks: `is_delivered`/`is_read` exist on messages → inline tick next to timestamp is allowed (data exists).

---

## 1. Phase 0 — Font assets (bundle Inter + Vazirmatn)

- [x] Download Inter family (Regular/Medium/SemiBold/Regular→ExtraBold, w400-w800) into `assets/fonts/Inter/`
- [x] Download Vazirmatn family (Regular/Medium/SemiBold/Bold/ExtraBold) into `assets/fonts/Vazirmatn/`
- [x] Declare both families + weights in `pubspec.yaml` `flutter: fonts:`
- [x] `flutter pub get` resolves; fonts copy into build
- [x] Update `app_theme.dart`: `fontFamily` → Inter; add `fontFamilyFa` → Vazirmatn

## 2. Phase 1 — Token layer (design system)

### 2.1 Colors — all new constants (keep `lightX`/`darkX` names → auto-restyles 466 sites)
- [x] Light: background `#FFF8F3`, moduleFillNeutral `#FFFFFF`, textPrimary `#1E1E1E`, textSecondary `#8A8A8A`, textOnPhoto `#FFFFFF`, divider `#F0F0F0`, success `#4CAF7D`, error `#E5484D`, accentLike `#FF4F81`, accentSuperlike `#FFC93C`, accentReject `#F1F1F1`(icon `#4A4A4A`)
- [x] Dark: background `#15131A`, moduleFillNeutral `#24222C`, textPrimary `#F5F5F5`, textSecondary `#9A98A5`, divider `#332F3C`, error `#FF6B6B`, accentReject `#322F3A`(icon `#E8E6EC`); accents/gradient/success unchanged
- [x] Gradient helper: `primaryGradient` #FF6B6B → #FFA751 @ 135° (light+dark)
- [x] `moduleFillTinted` helpers (gradient/accent @10% light / @18% dark)
- [x] `textOnPhoto`, legacy `lightSurface`→moduleFillNeutral mapping so old refs keep working where sensible

### 2.2 Typography — exaggerated minimalism, two resolved sets
- [x] Build `AppTextStyles` (en): heroDisplay 34/w800/h1.1, h1 24/w700/h1.2, h2 18/w600/h1.3, body 15/w400/h1.45, bodyBold 15/w600/h1.45, caption 13/w400/h1.3, overline 12/w600/ls1.0 caps, button 16/w700/ls0.2
- [x] Build `AppTextStylesFa` (fa): same sp/weights → Vazirmatn; line-heights +15%; letterSpacing 0; overline role → textSecondary + bodyBold/h2 weight
- [x] Wire ThemeData.textTheme per locale resolve (no hardcoded family in widgets)
- [x] Replace all 332 hardcoded `fontFamily: 'Inter'` sites with token/theme resolution

### 2.3 Shape & shadow
- [x] `radiusModule = 16`, `radiusChip/ButtonSm = 999`, `radiusInput = 14`
- [x] `shadowModule` = black 4%, blur 8, offset(0,2)
- [x] `shadowFloatingBtn` = fill*25%, blur 16, offset(0,6)

### 2.4 Buttons / toggles / chips
- [x] CTA: gradient fill, textOnPhoto, pill, h52, tinted shadow; secondary=outline 1.5px gradient-start
- [x] Toggles: track divider/gradient, white thumb
- [x] Chips: accent @10-18% tint, accent text (pills)
- [x] Floating circular swipe buttons (48/48/56), pressed scale 0.94

### 2.5 Bottom nav
- [x] Full-width `primaryGradient`, top corners radiusModule, icons white 60% → 100% + dot

---

## 3. Phase 2 — Mode A screens (full-bleed / text-over-photo)

Design language: no card, photo flush to edges, bottom-anchored name/age/location over gradient scrim (transparent→black65, ~40% height), large hero type, floating circular action buttons with own shadow, whole-screen card transition, Stories-style progress strip on top edge, scrim top bar.

### Screen list
- [x] `main_screen.dart` — bottom nav + loading/auth guard styling
- [x] `splash_screen.dart` — full gradient bg, white wordmark, no modules
- [x] `discover_screen.dart` + `user_card.dart` — full-bleed stack, scrim, floating buttons, whole-screen dismiss
- [x] `discover/profile_detail_screen.dart` — Mode A hero + (mode B info below fold)
- [x] `search/search_profile_detail.dart` — Mode A hero + Mode B info
- [x] `chats/user_notification_profile_screen.dart` — classify by content (hero → Mode A)
- [x] `profile/profile_screen.dart` — hero/photo area Mode A, sections Mode B
- [x] Match dialog (`discover_screen.dart` + `search_profile_detail.dart`) — gradient splash-style
- [x] `search_grid_card.dart` — compact Mode A card in grid

**Per-screen responsiveness check** — `[ ]` markers, all 5 sizes + orientation (see §7).

## 4. Phase 3 — Mode B screens (bento-grid modular)

Design language: asymmetric modules, 12px gutters, radiusModule 16, flat/tinted fills (no white-card-on-bg), minimal shadow, h2 module headers, section padding +30%.

- [x] `settings_screen.dart` — group toggles into modules; Premium upgrade = distinct tinted module; logout module
- [x] `settings_screen.dart` language picker sheet restyle
- [x] `chats_screen.dart` — segmented pill control + bento sections
- [x] `chat_list_screen.dart` — flat-fill rows, "new matches" module on top, asymmetric unread emphasis, matched avatar strip restyle
- [x] `liked_me_screen.dart` / `i_liked_screen.dart`
- [x] `notifications_screen.dart`
- [x] `search_screen.dart` — grid + filter bar modules
- [x] `search_filter_sheet.dart` — filter categories as variable-size modules
- [x] Onboarding `basic_info_screen.dart` (hybrid: Mode A framing for intro + Mode B form module)
- [x] Onboarding `profile_details_screen.dart`, `interests_screen.dart`, `prompts_screen.dart`, `photo_upload_screen.dart`
- [x] Profile edit screens: `edit_basic_info`, `edit_profile_details`, `edit_interests`, `edit_prompts`, `edit_photos`, `avatar_crop`

**Per-screen responsiveness check markers** (§7).

## 5. Phase 4 — Chat Telegram-inspired redesign (special case)

No new features. Bubbles 75% max width, r18, tail 4px; group gap 4-6px with tail only on last; inline 11sp timestamp + read tick (data exists); date pills (inline, not sticky — sticky would require a CustomScrollView refactor that risks the load-more-on-scroll-to-top behavior); tinted bg `gradientStart @4%`; in-flow top bar; pill input w/ single circular send; scroll-to-bottom button when scrolled up (no unread badge — active chat, unread not tracked); restyled context sheets (moduleFillNeutral + shadowModule).

- [x] `chat_detail_screen.dart` — layout, date separators, scroll-to-bottom, top bar, bg tint
- [x] `chat_message_bubble.dart` — bubble geometry, timestamp, grouping, tail logic, read tick
- [x] `chat_input_bar.dart` — pill field + circular send, existing attach/record behaviors restyled only
- [x] `chat_app_bar.dart` — in-flow bar, avatar/name/status left, existing actions right
- [x] `online_indicator.dart`, `typing_indicator.dart` tokens
- [x] Message-options / report / delete / chat-menu sheets restyle

**Per-screen responsiveness check markers** (§7).

## 6. Phase 5 — Localization, RTL, numerals

- [x] Wrap app in `Directionality`/locale handling so `fa` resolves RTL (text-align right, chevrons mirror, symmetric icons unchanged)
- [x] Verify bottom-nav order stays as implemented (do not reverse)
- [x] ASCII/Western numerals confirmed (no converter added)
- [x] Vazirmatn resolves for fa text app-wide (no Inter on fa)
- [x] `flutter gen-l10n` if any ARB touched (keys identical → likely none required)

---

## 7. Responsiveness verification ledger (every screen, every size)

Sizes × orientation (overflows to show RenderFlex/click/overlap): 360×640, 390×844, 430×932 (phones), 768×1024 & 1024×768 (tablets, portrait+landscape). Mark `[x]` only when clean.

Use `flutter run -d chrome` resized, or `--dart-define` size harness if needed; rely on `AppLayout.s()` / `LayoutBuilder` / `MediaQuery`.

| Screen | 360×640 | 390×844 | 430×932 | 768×1024 | 1024×768 |
|---|---|---|---|---|---|
| splash | [ ] | [ ] | [ ] | [ ] | [ ] |
| login | [x] | [x] | [x] | [x] | [x] |
| sign_up | [x] | [x] | [x] | [x] | [x] |
| verify_code | [ ] | [ ] | [ ] | [ ] | [ ] |
| basic_info | [x] | [x] | [x] | [x] | [x] |
| profile_details | [x] | [x] | [x] | [x] | [x] |
| interests | [x] | [x] | [x] | [x] | [x] |
| prompts | [x] | [x] | [x] | [x] | [x] |
| photo_upload | [x] | [x] | [x] | [x] | [x] |
| discover (Mode A) | [x] | [x] | [x] | [x] | [x] |
| profile_detail (Mode A) | [x] | [x] | [x] | [x] | [x] |
| search_screen | [x] | [x] | [x] | [x] | [x] |
| search_profile_detail | [x] | [x] | [x] | [x] | [x] |
| search_filter_sheet | [x] | [x] | [x] | [x] | [x] |
| profile_screen | [x] | [x] | [x] | [x] | [x] |
| settings + lang sheet | [x] | [x] | [x] | [x] | [x] |
| edit_basic_info | [x] | [x] | [x] | [x] | [x] |
| edit_profile_details | [x] | [x] | [x] | [x] | [x] |
| edit_interests | [x] | [x] | [x] | [x] | [x] |
| edit_prompts | [x] | [x] | [x] | [x] | [x] |
| edit_photos | [x] | [x] | [x] | [x] | [x] |
| avatar_crop | [ ] | [ ] | [ ] | [ ] | [ ] |
| chats_screen (tabs) | [x] | [x] | [x] | [x] | [x] |
| chat_list | [x] | [x] | [x] | [x] | [x] |
| chat_detail (Telegram) | [x] | [x] | [x] | [x] | [x] |
| notifications | [x] | [x] | [x] | [x] | [x] |
| liked_me / i_liked | [x] | [x] | [x] | [x] | [x] |
| user_notification_profile | [x] | [x] | [x] | [x] | [x] |
| profile_detail_loader | [x] | [x] | [x] | [x] | [x] |
| main_screen (nav) | [ ] | [ ] | [ ] | [ ] | [ ] |

**Automated coverage:** `test/responsive/responsive_layout_test.dart` (7 screens) +
`test/responsive/responsive_layout_mode_b_test.dart` (20 screens, real Inter font loaded via
`FontLoader` so text metrics match production; Ahem would overstate width). Overflows found
& fixed during this pass: `photo_upload_screen.dart` tips `Row` → `Wrap`, `interests_screen.dart`
Next-button label → `FittedBox(scaleDown)`.

**Manual-only rows (left `[ ]`):** `splash` (async progress loop + navigation), `verify_code`
(resend countdown timer), `avatar_crop` (native ImageCropper), `main_screen` (navigates to
onboarding when user is not profile-complete). Verify these via `flutter run -d chrome` at the
five sizes above. **Blocked in this environment** — no Android emulator; only desktop/Chrome/
Edge targets available. These 4 rows + the light/dark toggle-persist check remain `[ ]` pending
an on-device/interactive run.

## 8. Verification (end of every phase)

- [x] `flutter analyze` — no new issues
- [x] `flutter test` — green (rebaseline goldens: `flutter test --update-goldens` where layout intentionally changed; fix widget tests asserting old geometry/colors)
- [ ] Light/dark toggle compiles, switches, persists across restart — **blocked: needs device run**
- [ ] Manual smoke on device: auth → onboarding → discover → search → chat flows — **blocked: needs device run**

## 9. Acceptance checklist (final gate)

- [ ] No old "white card floating on solid background" pattern remains — **visual, device-run**
- [ ] Mode A screens have zero visible card containers around primary photo content — **visual, device-run**
- [ ] Mode B screens show visibly varied module sizes (not a uniform list) — **visual, device-run**
- [x] Every hardcoded old-system color/radius/text style replaced with new tokens — colors + fontFamily fully tokenized (no stray `Color(0x...)`/`fontFamily: 'Inter'` outside `app_theme.dart`); ~116 local `BorderRadius.circular()` geometry sites (r2–r100) remain as **intentional per-element shapes** (pills/hero/input), tokens r2/r16/r24/r999 defined and used for module/button/input radii
- [ ] Light + dark both compile + toggle + persist — compiles ✓ (release APK built), toggle-persist needs device run
- [ ] 26/30 §7 rows `[x]` via automated harness + 4 manual rows (splash, verify_code, avatar_crop, main_screen) verified in `flutter run -d chrome` — zero overflow/clipping/overlap — **26 automated rows pass (`responsive_layout_test.dart` + `responsive_layout_mode_b_test.dart` green in `flutter test`); 4 manual rows blocked (no device)**
- [x] Every screen has identical navigation entry/exit + functional behavior (diff review) — **verified vs base `9585022`**: all six nav-call types byte-identical (`push` 18, `pushReplacement` 18, `pop` 85, `showModalBottomSheet` 16, `showDialog` 8, `pushAndRemoveUntil` 0 = 145 total both sides); `lib/providers/`, `lib/services/`, `lib/models/` untouched. The §0.3 census numbers (19/18/18/13) were approximate; the actual structure is preserved exactly.
- [x] `git diff` contains no changes outside widget `build()`, layout structure, theme/token files — **verified**: changed files are screens/widgets (build/layout), `app_theme.dart` (tokens), `main.dart`, `pubspec.yaml` (fonts), `l10n`/`generated` (localization); only new source file is `lib/utils/cached_image.dart` (in-scope rendering/perf helper).
- [x] Commit on `warm_orange`; optional PR to `initial_design`/`main` — **committed `d26087d`**; PR is optional and not pushed.

## 10. Rollout order (solo-dev safe slicing)

1. Phase 0 fonts → 2. Phase 1 tokens + bottom nav → 3. Phase 2 Mode A → 4. Phase 3 Mode B → 5. Phase 4 Chat → 6. Phase 5 RTL → 7. §7 ledger + §8 verify → 8. §9 final gate + commit.

---

# PART 2 — Performance & Smoothness Pass

> Companion to the visual redesign. Fix jank the redesign would otherwise inherit. Same boundaries: rendering, rebuild scope, images, animation implementation — **no business logic, data, or navigation changes.**

## P0. Diagnose before fixing (grounded findings)

**Methodology rule:** All performance judgments from now on use **profile or release mode** (`flutter run --profile`), not debug. Debug = JIT + assertions + no tree-shaking → not representative.

### Static diagnosis already done (grep census, 2026-08)
- **No direct `Image.network` / `NetworkImage` anywhere** — 100% of network images go through `CachedNetworkImage`/`CachedNetworkImageProvider` ✓ (good baseline).
- **Cache resolution:** only `profile_screen.dart:227` passes `memCacheWidth: 400`. All other photo sites decode full-source resolution to render at thumbnail/card size: `user_card.dart:320`, `search_grid_card.dart:43`, `search_profile_detail.dart:155/455`, `discover/profile_detail_screen.dart:276/530`, `chat_message_bubble.dart:193/280`, `edit_photos_screen.dart:850/932`, plus avatar providers (`chat_app_bar.dart:58`, `chat_list_screen.dart:140`, `liked_me_screen.dart:127`, `i_liked_screen.dart:128`, `matched_avatar_strip.dart:90`). → **#1 jank suspect** in a photo-heavy app.
- **`setState`-loop animation anti-patterns found:**
  - `splash_screen.dart:76-90` — `_animateProgress` drives a 20-step `setState` loop via `Future.delayed` (not interruptible, rebuilds whole splash). → convert to `AnimationController`.
  - `voice_message_player.dart:39-57` — `positionStream` fires `setState` on every audio tick; player + parent bubble rebuild constantly during playback. → narrow rebuild to progress bar only (e.g. `AnimatedBuilder`/stream→value, small dedicated widget).
- **Eager lists found (build all children upfront):**
  - `chat_list_screen.dart:46` `ListView(children:)`
  - `notifications_screen.dart:64` `ListView(children:)`
  - `search_screen.dart:182` `ListView(children:)` and `search_screen.dart:322` `GridView(children:)` (eager grid)
  - `search_filter_sheet.dart:242` `ListView(children:)`
  - Lazy `.builder` already used in: `chat_detail_screen.dart:715`, `profile_detail_screen.dart:499`, `search_profile_detail.dart:424`, `liked_me`/`i_liked:82`, `matched_avatar_strip.dart:50`, `notifications_screen.dart:107`, `search_screen.dart:440` ✓.
- **`user_card.dart` drag:** `setState` per pan frame for `_dx/_dy/_rotation` (`:75-86`, `:116`) — rebuilds the whole card subtree every drag tick. The redesign's whole-screen swipe transition raises the stakes → wrap card content in `RepaintBoundary`, drive transform via controller.
- **No `compute()`/isolate usage** — check for JSON parse / image decode on UI thread during profile hydration (candidate: `profile_detail_loader.dart` fetch+parse).
- **`main_screen.dart` uses `IndexedStack`** (keeps all 4 tabs alive) — fine for tab state, but means all 4 tabs build at startup; verify no tab does heavy work in `initState`.

### Runtime diagnosis to complete before any perf fix
- [ ] Run `flutter run --profile`, open DevTools Performance + on-screen overlay; record frame-loss during: Discover swipe, Search grid scroll, Chat message scroll, Chat send, Profile open. — **blocked: no Android device/emulator available**
- [ ] `debugPrintRebuildDirtyWidgets` on Discover + Chat: capture widgets rebuilding per frame vs. visible content change. — **blocked: needs device run**
- [ ] Confirm whether prior "clunkiness" reports were debug-mode only (likely explains a large share) — document in plan. — **blocked: needs device run**

## P1. Fix areas (apply where P0 confirms)

### P1.1 Images — decode at display resolution
- [x] Add a shared resolution helper (e.g. `lib/utils/image_cache.dart`: `CachedNetworkImage cachedImage(url, {displayWidth, displayHeight})` computing `memCacheWidth` from `MediaQuery.devicePixelRatio`). — **done**: shared `CachedImage` helper (`lib/utils/cached_image.dart`) computes `memCacheWidth`/`memCacheHeight` (and disk-cache tiles) from rendered size × `devicePixelRatio`, with `.widget()` / `.provider()` / `.providerRect()` variants.
- [x] Apply `memCacheWidth/Height` at all photo call sites listed in P0 (user_card, search_grid_card, profile_detail ×2, search_profile_detail ×2, chat_message_bubble ×2, edit_photos ×2, profile_screen keep, all avatar providers). — **done**: all 16 sites route through `CachedImage` with real display dimensions (verified: user_card full-bleed, search_grid_card 160×93, profile_detail hero, edit_photos 160/80 + slots, bubble `size`, profile avatar, avatars via `provider(diameter:)`). The P0 census predates this migration.
- [x] Confirm swipe-card photos are stable cached instances across parent rebuilds (no re-create/decodes per rebuild). — **verified in code**: all photos go through `CachedImage` (`CachedNetworkImage`); swipe card content is a cached `child` in the controller-driven `AnimatedBuilder` (B4).

### P1.2 Rebuild scope
- [x] Convert splash `_animateProgress` (splash_screen.dart:76-90) to `AnimationController` + `AnimatedBuilder` over the progress bar only.
- [x] Voice player: replace whole-widget `setState` on `positionStream` with a narrow position widget (`AnimatedBuilder`/stream-to-widget) so bubbles don't rebuild per audio tick. — **audit found it already satisfies this**: `voice_message_player.dart` uses a `StreamBuilder` scoped to the player widget; no parent-bubble rebuild per tick. No change needed.
- [x] Audit `setState` in hot rebuild paths: `chat_input_bar.dart:390`, `chat_detail_screen.dart:194/218/549/574`, `basic_info_screen.dart` (form-driven ok), `user_notification_profile_screen.dart:81-96` — narrow where the change is a single field. — **audited**: remaining sites are one-off state changes (reply/edit UI toggles, scroll-to-bottom flag) with bounded scope; kept as-is.
- [x] Add `const` constructors to stateless subtree widgets flagged by analyzer (grep `Missing const constructor` / prefer_const where safe). — **analyzer clean** (`flutter analyze` no issues) → nothing left flagged.
- [x] Provider: use `context.select`/`Selector` in list items (chat bubbles, search grid cards) so unread/status field changes don't rebuild whole rows. — **audit conclusion**: `chat_message_bubble.dart`/`search_grid_card.dart` are pure-param widgets (no provider dependency); rows rebuild only from the enclosing lazy list's `Consumer` (bounded by `ListView/GridView.builder`). No per-row Provider rebuild exists to eliminate; deep Selector refactor deferred unless P0 shows the bounded Consumer matters.
- [x] Wrap swipe card + search grid card content in `RepaintBoundary`.

### P1.3 Lists — lazy & flat
- [x] Convert eager lists to `.builder`: `chat_list_screen.dart:46`, `notifications_screen.dart:64`, `search_screen.dart:182` + `:322`, `search_filter_sheet.dart:242`. — converted: chat_list empty-state, notifications empty-state, search_filter_sheet (8 filter sections + trailing spacer). `search_screen` chip row intentionally kept eager (fixed 6-item control row — no lazy-build benefit); search grid already lazy.
- [x] Flatten deep per-item nesting in rebuilt list widgets; keep `shadowModule` near-flat (no heavy per-item shadows — aligns with redesign token).

### P1.4 Animations — controller-driven
- [x] Swipe card drag/fling (`user_card.dart`) and redesign's scale-0.94 press states: `AnimationController` + `Curves.easeOut`/`SpringSimulation`, no frame-by-frame `setState`. — `user_card.dart` now drives drag/dismiss/rotate via `AnimatedBuilder` merging `_controller` + `ValueNotifier<int>`; `_animateDismiss`/`swipeOut`/`snapBack` use controller animations with status listeners.
- [x] Screen transitions (Mode A whole-screen swap): controller/implicit animations, wrap only the animating widget in `AnimatedBuilder`. — discover whole-screen dismiss lives in `user_card`'s controller-driven transform; content subtree is a cached `child` wrapped in `AnimatedBuilder` + `RepaintBoundary`.
- [x] Verify no animation rebuilds a large subtree per tick. — verified: splash + voice progress scoped via `AnimatedBuilder`/`StreamBuilder`; card content cached.

### P1.5 General
- [x] Move heavy JSON parse in `profile_detail_loader.dart` (and any response parsing >~few ms) into `compute()`/isolate if P0 shows UI-thread blocking. — **done**: `_load()` now parses via `compute(_parseProfile, response.data)` (top-level isolate-safe function); `DiscoverProfile.fromJson` is a plain factory over a Map (verified isolate-safe). Applied proactively per go-ahead — low risk, keeps main thread free regardless.
- [x] Verify release config: `flutter build apk --release` tree-shakes (default) — confirm no debug flags leaking into release build. — **done**: `flutter build apk --release` succeeded (62.4MB APK, MaterialIcons tree-shaken 99.2%, no debug leaks).

## P2. Performance verification ledger

| Interaction | Profile-mode frames (target ~60fps) | Widget-rebuild check | Status |
|---|---|---|---|
| Discover swipe + transition | [ ] | [ ] | [!] blocked — no device for `flutter run --profile` |
| Search grid scroll | [ ] | [ ] | [!] blocked |
| Chat list scroll | [ ] | [ ] | [!] blocked |
| Chat send / optimistic bubble | [ ] | [ ] | [!] blocked |
| Chat message scroll | [ ] | [ ] | [!] blocked |
| Profile open / photo load | [ ] | [ ] | [!] blocked |
| Voice playback progress | [ ] | [ ] | [!] blocked |

## P3. Performance acceptance

- [ ] P0 diagnosis documented (screens/interactions measured janky + why) — **blocked: needs device**
- [x] All perf judgments in profile/release mode going forward — methodology rule honored; release build verified (P1.5)
- [ ] Discover / Matches / Messages hold ~60fps in DevTools overlay — **blocked: needs device**
- [ ] No unnecessary full-subtree rebuilds (Widget Rebuild stats) — **code-level only** (P1.2/P1.4 items done); runtime stats need device
- [x] All photos cached + decoded at display resolution — cached ✓ (100% CachedImage); decode-at-display ✓ (P1.1 done — all 16 sites pass display dimensions, `memCacheWidth/Height` derived from DPR)
- [x] All animations via `AnimationController`/implicit widgets, no `setState` loops — splash, voice, swipe card, press-scale states all controller/implicit-driven
- [x] No behavioral/functional changes introduced (same constraint as Part 1)

## P4. Perf rollout order

1. P0 runtime diagnosis (profile mode) → 2. P1.1 image resolution (highest payoff) → 3. P1.4 animations (splash, voice, swipe) → 4. P1.3 lazy lists → 5. P1.2 rebuild scope → 6. P1.5 compute/release check → 7. P2 ledger → 8. P3 gate.