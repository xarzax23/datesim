# Next Steps

## Current Focus

Close Block 1 with one real OpenAI-backed turn while preserving the fully working local fallback flow:

1. load scenarios from backend
2. create a session from mobile
3. send chat messages to backend
4. receive SSE streaming responses
5. render scorecard when applicable
6. handle session end states
7. persist rejection and session state
8. align shared contracts so backend and mobile do not drift

## Current Block

### Block 1 - Mobile Backend Integration

#### Goal

Replace mock/mobile-only conversation flow with real backend-driven data and SSE streaming, then lock the visible contract between backend, shared types, and Flutter.

#### Status Snapshot

- Implemented in code: scenario loading, session creation, chat POST, SSE parsing, Riverpod chat state, home-to-chat routing, scorecard rendering for easy mode, and basic rejected state handling.
- Implemented after delegation: mobile `GET /sessions` service/provider and shared contracts alignment.
- Partial: completed-session lifecycle/UX and a complete OpenAI-backed streaming chat turn.
- Environment ready: Android SDK 36, the `DateSim_API_36` emulator, PostgreSQL 17, Firebase Auth Emulator, and the local backend are running on this computer.
- Verified locally: a fictitious email user authenticates, loads scenarios, creates a persisted session, sends messages, receives streamed responses and scorecards, and reaches a persisted rejected state from Android.
- Blocker/risk: the recovered `OPENAI_API_KEY` is valid but currently has no available quota; local fallback mode provides content-aware heuristic scoring for UI/SSE testing.
- Repository checkpoint completed: the restored environment, auth, backend fixes, local fallback, tests, and planning updates are consolidated in Git.

#### Tasks

- [x] Create Flutter scenarios service to consume `GET /scenarios`
  - Owner: mobile-flutter-developer
- [x] Create Flutter sessions service to consume `POST /sessions`
  - Owner: mobile-flutter-developer
- [x] Complete Flutter sessions service/provider for `GET /sessions`
  - Owner: mobile-flutter-developer
  - Scope: service/provider only; no history UI until Block 2
- [x] Create Flutter chat service to call `POST /sessions/:sessionId/messages`
  - Owner: mobile-flutter-developer
- [x] Implement SSE parsing in Flutter for `delta`, `scorecard`, `done`, and `error`
  - Owner: mobile-flutter-developer
- [x] Create Riverpod providers for scenarios, session creation, and chat
  - Owner: mobile-flutter-developer
- [x] Connect home screen to real scenarios endpoint
  - Owner: mobile-flutter-developer
- [x] Connect scenario selection to real session creation
  - Owner: mobile-flutter-developer
- [x] Connect chat screen to real backend messages
  - Owner: mobile-flutter-developer
- [x] Handle `rejected` and `done` states in chat UI at MVP-basic level
  - Owner: mobile-flutter-developer + product-ux-designer
- [x] Show scorecard in easy difficulty
  - Owner: mobile-flutter-developer + product-ux-designer
- [x] Align `packages/contracts` with backend/mobile runtime shapes
  - Owner: contracts-integration
  - Must resolve: `token` vs `delta`, `feedback` vs `reason`, scorecard payload shape, `done` payload shape, public/private scenario shape
- [x] Add or update focused regression tests for contract-visible parsing/state behavior
  - Owner: qa-release-engineer
- [x] Run backend unit tests and backend build
  - Owner: qa-release-engineer
  - Commands: `npm test -- --runInBand`, `npm run build`
- [x] Run contracts build
  - Owner: qa-release-engineer
  - Command: `npm run build`
- [x] Run Flutter validation once local tooling is available
  - Owner: qa-release-engineer
  - Commands: `flutter test`, `flutter analyze`
- [ ] Run real end-to-end smoke test with Firebase, PostgreSQL, and OpenAI environment configured
  - Owner: backend-api-developer + mobile-flutter-developer + qa-release-engineer
  - Blocked: the recovered OpenAI key currently returns `insufficient_quota`
- [x] Run local backend smoke test for database boot, Swagger, public scenarios, and protected route auth
  - Owner: backend-api-developer + qa-release-engineer
  - Result: backend runs on `http://localhost:3000`, Swagger returns 200, `/api/v1/scenarios` returns public scenario data, `/api/v1/sessions` returns 401 without bearer token
- [x] Build, install, and launch the Android app in a local emulator
  - Owner: mobile-flutter-developer + qa-release-engineer
  - Result: `DateSim_API_36` boots, DateSim opens on the login screen, and the emulator reaches the backend at `10.0.2.2:3000`
- [x] Configure local email/password authentication without Google sign-in
  - Owner: mobile-flutter-developer + qa-release-engineer
  - Result: Firebase Auth Emulator accepts the fictitious test account and the Flutter app restores its authenticated state
- [x] Verify authenticated session creation from the Android emulator
  - Owner: backend-api-developer + mobile-flutter-developer + qa-release-engineer
  - Result: selecting `Encuentro en la cafetería` persists the user/session with internal UUIDs and opens the chat with its initial message
- [x] Verify one complete local fallback chat turn from the Android emulator
  - Owner: backend-api-developer + mobile-flutter-developer + qa-release-engineer
  - Result: messages receive streamed `delta` events, varied heuristic scorecards based on their content, and `done`; Flutter renders the response and feedback
- [x] Verify rejected session behavior from the Android emulator
  - Owner: backend-api-developer + mobile-flutter-developer + qa-release-engineer
  - Result: hostile or unsafe responses receive low scores, emit `done: rejected`, persist session status `rejected`, show the end-state banner, and disable further input
- [ ] Define and implement the normal `completed` session lifecycle
  - Owner: product-ux-designer + backend-api-developer + contracts-integration + mobile-flutter-developer
  - Scope: decide the completion trigger, persist `completed`, expose the terminal event to Flutter, and present a clear completed state

#### Definition Of Done

- A signed-in user can select a real scenario from backend data.
- A real session is created in backend.
- The user can send a real message.
- The assistant response streams progressively in the chat UI.
- If a scorecard is returned in easy mode, it is rendered in the UI.
- If the session is rejected, the UI reflects it and disables further input.
- Shared contracts match the backend/mobile runtime shape.
- Focused tests cover SSE parsing, scorecard parsing, rejected state, and session service behavior.
- A real OpenAI-backed turn is verified with local fallback disabled.

## Agent Delegation

- `project-orchestrator`: keep global state, detect stale docs, protect MVP focus.
- `delivery-manager`: maintain this file and sequence Block 1 work.
- `contracts-integration`: align `packages/contracts`, backend payloads, Flutter models/parsers, and tests.
- `mobile-flutter-developer`: own Flutter services, Riverpod providers, routing, chat state, and mobile tests.
- `backend-api-developer`: verify NestJS routes, Firebase auth, DTO validation, persistence, and SSE producer behavior.
- `llm-scenarios-scoring`: own scoring semantics, scenario prompts, rejection behavior, and scorecard meaning.
- `product-ux-designer`: refine visible chat, scorecard, rejected/completed, loading, empty, and error states.
- `qa-release-engineer`: run tests/analyze/builds, add regression coverage, and report residual release risk.

## Immediate Execution Order

1. backend-api-developer: restore OpenAI API quota or provide another funded key.
2. qa-release-engineer: repeat the verified turn with local fallback disabled and confirm the real model response.
3. product-ux-designer + backend-api-developer + contracts-integration: define the normal `completed` lifecycle.
4. delivery-manager: close Block 1 and start Block 2 after the real model turn and completed-lifecycle contract are verified.

## Next Block After That

### Block 2 - Session UX Completion

- [ ] Session summary UI for completed/rejected sessions
- [ ] List past sessions
- [ ] Basic progression/history screen
- [ ] Cleaner error and retry states in chat

## Important Constraints

- Do not expand scoring complexity before mobile-backend integration works end to end.
- Do not build profile/progress screens before real session data is flowing.
- Do not let backend/mobile contracts drift; strengthen `packages/contracts` before moving to Block 2.
- Do not expose scenario `systemPrompt` to mobile.

## Open Risks

- SSE handling in Flutter still needs explicit cancellation behavior.
- Malformed scorecard events are covered; malformed transport lines are ignored, but the user-facing retry path remains basic.
- Contracts package is aligned with the current runtime shape, but still needs a mature workflow before it becomes the long-term source of truth.
- Available OpenAI API quota is required before validating the complete real streamed chat turn.
- Active sessions do not yet have a normal path to persisted `completed` status.

## Update Rule

Update this file whenever:

- the current implementation block changes
- a checklist item is completed
- a blocker changes the recommended order
- the project moves from one MVP block to the next
