---
name: datesim-mobile-flutter
description: Flutter implementation guidance for the DateSim mobile app. Use when Codex must build or review Flutter features, Riverpod providers, GoRouter navigation, Firebase auth integration, Dio/http API services, SSE parsing, chat state, scorecard rendering, scenario/session flows, widget tests, unit tests, or mobile-side Block 1 backend integration work.
---

# DateSim Mobile Flutter

## Purpose

Use this skill to implement mobile behavior in `apps/flutter_app` with the existing feature-first structure, Riverpod state management, typed models, and focused tests.

## Sources Of Truth

Read only what the task needs:

- `docs/project/status.md`
- `docs/project/next-steps.md`
- `.github/agents/mobile-flutter-developer.agent.md`
- `apps/flutter_app/pubspec.yaml`
- `apps/flutter_app/lib/core/config.dart`
- `apps/flutter_app/lib/router/app_router.dart`
- `apps/flutter_app/lib/features/<feature>/**`
- `apps/flutter_app/test/features/<feature>/**`

For API/SSE shape, also use `datesim-api-contracts` and read:

- `packages/contracts/src/index.ts`
- relevant backend controller/service files

For visible UX/copy changes, also use `datesim-product-design`.

## Architecture Rules

- Keep the feature-first layout:
  - `data`
  - `models`
  - `providers`
  - `presentation`
  - `widgets`
- Keep network calls in services, not widgets.
- Keep state transitions in Riverpod notifiers/providers.
- Parse API data into typed models before UI use.
- Keep widgets responsible for rendering and user actions only.
- Do not introduce broad dependencies without checking existing patterns in `pubspec.yaml`.
- Do not expand profile, payments, or progression while Block 1 remains unfinished unless explicitly requested.

## Block 1 Mobile Scope

The active integration flow is:

1. Load scenarios from backend.
2. Create a real session from selected scenario.
3. Navigate to chat using the real session id.
4. Send user messages to backend.
5. Parse SSE events.
6. Stream assistant response in UI.
7. Render scorecard in easy difficulty when returned.
8. Handle rejected/done/error states.

## Implementation Workflow

1. Read the relevant model, service, provider, screen, and tests.
2. Check API shape with `datesim-api-contracts` before changing models or SSE parsing.
3. Implement in this order:
   - model/parser
   - service
   - provider/notifier state
   - screen/widget behavior
   - tests
4. Preserve current routing and auth patterns unless the task requires a change.
5. Add the narrowest test that proves the behavior.
6. Run targeted validation first, then full validation if the blast radius is broad.

## Service Patterns

- Use `apiBaseUrl` from `lib/core/config.dart`.
- Use Firebase `getIdToken()` when authenticated endpoints require bearer auth.
- Use `Dio` where existing services use `Dio`.
- Use `http.Client` for streaming if it is already the local pattern.
- Convert low-level errors into user-readable messages at the service/provider boundary.
- Keep cancellation and duplicate-send behavior explicit for chat streams.

## Riverpod Patterns

- Use providers to construct services with their dependencies.
- Use `FutureProvider` for simple read-only remote data.
- Use `AsyncNotifier` when an action has loading/error/data lifecycle, such as creating a session.
- Use `Notifier` for chat state when it must handle streaming state transitions.
- Avoid storing API response maps directly in state; store typed objects.

## Chat SSE Rules

For each incoming event, keep behavior deterministic:

- text chunk event: append to the active assistant message.
- `scorecard`: parse and validate scorecard; keep chat alive if parsing fails.
- `done`: stop streaming; if rejected, end the session locally.
- `error`: stop streaming, preserve user message, show a useful error.

Do not assume contracts are correct without checking backend and `packages/contracts`. Known risk areas are `delta` vs `token`, scorecard object vs encoded JSON, and `reason` vs `feedback`.

## UI Rules

- Keep visible text in Spanish.
- Provide loading, empty, error/retry, sending, rejected, and disabled states where applicable.
- Do not call APIs directly from widgets.
- Do not duplicate opening messages on rebuild.
- Do not allow sending while a message is already streaming or after session end.
- Show scorecard only when difficulty and payload rules allow it.

## Testing

Prefer focused tests:

- model parsing tests for scenario, session, chat event, scorecard
- notifier tests for chat state transitions
- widget tests for scorecard visibility and rejected UI
- service tests only when HTTP behavior is isolated or easily mocked

Useful commands:

- `flutter test test/features/<area>`
- `flutter test`
- `flutter analyze`

If Flutter is not available locally, report that the validation is blocked and keep the test risk explicit.
