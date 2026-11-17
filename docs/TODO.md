# Bondi TODO

This is a traceable list of work observed from the current Flutter client and repository configuration. It does not assert that backend or product requirements are complete. Add new entries with a stable ID, owner, and acceptance criteria; move completed items to a dated completion section rather than silently deleting them.

## How to track

- Status: `TODO`, `IN PROGRESS`, `BLOCKED`, or `DONE`.
- Record a responsible person and target release/issue when assigned.
- Check acceptance criteria before marking an item done.
- This list is client-side; backend work should link to its own issue or plan.

## Open work

| ID | Priority | Status | Area | Task | Acceptance criteria |
|---|---|---|---|---|---|
| APP-001 | High | TODO | Release | Replace debug signing for Android release builds with the documented production signing setup. | Release APK/AAB is signed with the intended production key; signing credentials remain outside Git; CI/release procedure is documented. |
| APP-002 | High | TODO | Configuration | Resolve `.env.example` `WEB_CLIENT_ID` vs `AppConstants.googleClientId` `GOOGLE_CLIENT_ID` mismatch. | One canonical variable name is used consistently in template, source, setup docs, and relevant sign-in code. |
| APP-003 | High | TODO | Platform permissions | Verify iOS permission declarations for all enabled location, photo, microphone/audio, and camera flows. | Required usage descriptions exist with user-facing purpose text; permission prompts and denied states are verified on device. |
| APP-004 | High | TODO | Firebase/push | Document and verify Firebase setup and push-token lifecycle for each supported platform. | Clean setup steps are documented; permission, token registration/refresh, logout/removal, foreground/background, and tap routing are tested. |
| APP-005 | Medium | TODO | Premium | Implement the Premium CTA actions in `lib/screens/profile/profile_screen.dart` (manage subscription and purchase). | Buttons reach real supported flows or are hidden/disabled with an explicit product decision; no no-op action remains. |
| APP-006 | Medium | TODO | Documentation | Reconcile `AGENTS.md` project/status notes with the current implementation and this README/wiki. | Current auth flow, SDK/build config, feature status, and environment variable names agree across docs. |
| APP-007 | Medium | TODO | Web compatibility | Audit and document which app features and screens are supported on web, especially `dart:io` media flows and Firebase/local notifications. | Supported web flows work; unsupported flows are gated and clearly documented; web build behavior is verified. |
| APP-008 | Medium | TODO | Privacy/security | Review debug request/response logging and WebSocket query-token handling for production exposure. | Release logging policy is explicit; server/proxy logs do not retain credentials; production traffic uses HTTPS/WSS. |
| APP-009 | Medium | TODO | Localization | Audit English/Persian completeness and remaining hardcoded user-visible strings. | User-visible strings use localization where appropriate; both ARB files are synchronized; generated localization is current. |
| APP-010 | Low | TODO | Branding | Confirm and align app naming across `MaterialApp` (`AURA`), iOS display name (`Project D Mobile`), Android label (`Bondi`), and localization. | Product owner confirms final names; app and platform display names are consistent. |
| APP-011 | Medium | TODO | API documentation | Add/maintain frontend-facing API docs when client API contracts are added or changed. | `docs/` contains factual request/response details validated against backend schema for touched contracts. |
| APP-012 | Medium | TODO | Verification | Run the project-approved validation workflow after confirmation. | User confirms test execution; `./run_tests.sh` output is captured under `/tmp/opencode` and results are recorded. |

## Completed

No items have been marked complete in this list yet. When an item is completed, move it here with completion date and PR/commit/issue reference where available.
