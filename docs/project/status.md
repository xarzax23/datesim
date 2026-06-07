# Project Status

## Project

DateSim is a mobile-first social skills training app focused on simulated dating conversations with AI-powered characters. It is not a generic chatbot. The core product loop is:

1. User selects a scenario.
2. User chats freely with an AI character.
3. Each user message is scored.
4. The conversation can improve, cool down, or fail.
5. The user receives progression and feedback based on difficulty.

## Current Technical Direction

- Mobile: Flutter
- Backend: NestJS
- Auth: Firebase Auth
- LLM: OpenAI GPT-4o-mini
- Database: PostgreSQL
- Cloud target: GCP / Cloud Run
- Payments target: RevenueCat + native IAP

## Current State Summary

### Backend

Implemented:

- Modular NestJS backend structure
- entities for user, session, and message
- Firebase auth guard and user bootstrap flow
- scenarios module with initial hardcoded scenarios
- sessions module to create and list sessions
- chat service with SSE streaming design
- scoring service with structured JSON result
- basic rejection flow that updates session status to `rejected`
- explicit session completion endpoint with persisted average score
- terminal-state protection that rejects new messages after completion or rejection

Partial:

- scoring dimensions are simpler than the longer product vision
- scene direction logic exists only as lightweight steering in chat flow
- production-grade moderation path is not yet defined
- completed-session summary remains intentionally basic until Block 2

Missing:

- richer post-session feedback
- progression/history features
- evals pipeline for prompts and scoring regressions

### Mobile App

Implemented:

- Flutter app structure with feature-first organization
- auth flow scaffold with Firebase providers
- login screen
- home screen connected to real scenarios endpoint
- real session creation from scenario selection
- chat screen connected to backend message endpoint
- SSE parsing for `delta`, `scorecard`, `done`, and `error`
- Riverpod chat state for streaming, errors, scorecard, and rejected session state
- scorecard display in easy mode
- explicit practice completion with confirmation, persisted result, terminal banner, and disabled input
- tests around scorecard parsing/display and chat state transitions

Partial:

- rejected/done UX is MVP-basic and still needs product polish
- completed/rejected summary UX still needs the richer Block 2 view
- backend integration still needs one real OpenAI-backed device validation

Missing:

- session summary UI
- past sessions list UI
- profile and progress surfaces
- production-ready retry/cancellation behavior for long SSE streams

### Contracts / Tooling

Implemented:

- `packages/contracts` exists with shared TypeScript types
- CI workflow exists for backend and Flutter
- agent role definitions exist under `.github/agents`
- DateSim Codex skills exist under `.codex/skills`

Partial:

- shared contracts are aligned with the current runtime shape
- contracts package now declares TypeScript locally and builds with `npm run build`
- backend unit tests and backend build pass after `npm ci`
- Flutter SDK 3.32.7 is installed locally and `flutter analyze` / `flutter test` pass
- focused Flutter regression coverage exists for chat event parsing, scorecard parsing/display, chat state, and session parsing
- Local backend runs against PostgreSQL 17 on port `55432`; Swagger and public scenario endpoint are verified
- Android SDK 36, Android Studio, AEHD acceleration, and the `DateSim_API_36` emulator are configured locally
- the Android debug APK builds, installs, and opens successfully in the emulator
- Firebase Auth Emulator is configured for local email/password testing without Google sign-in
- a fictitious email user can authenticate, load scenarios, create a persisted session, and open the chat from Android
- local fallback mode is verified from Android and now derives varied heuristic scores and feedback from each message while OpenAI has no quota
- normal completion is verified from Android and PostgreSQL: the latest device session persisted as `completed` with its calculated overall score

Missing:

- fully operational shared contracts workflow beyond the current aligned TypeScript types
- contract regression tests across backend/mobile expectations
- release automation maturity

## MVP Phase

The project is still in:

**Block 1 - Mobile Backend Integration**

The practical focus is no longer creating the first pass of mobile services; that work is present and the local Android flow is verified. The focus now is:

1. validate one complete OpenAI-backed streaming conversation turn
2. then move to session summary/history UX

## Immediate Next Step

Highest-value next block of work inside Block 1:

### Verification Before Block 2

Goals:

- run a real end-to-end chat-turn smoke test with OpenAI configured
- preserve focused tests for parsing and state-transition gaps
- keep public scenario payloads free of `systemPrompt`

Suggested owner sequence:

1. `delivery-manager`
2. `backend-api-developer`
3. `qa-release-engineer`
4. `product-ux-designer`
5. `contracts-integration`
6. `mobile-flutter-developer`

## Current Risks

- product docs can become stale because implementation has moved ahead of the old checklist
- contracts can drift again if future backend/mobile changes do not update `packages/contracts`
- the real OpenAI-backed response still needs an emulator smoke test with available API quota
- the recovered OpenAI key is valid but currently returns `insufficient_quota`

## Questions This File Should Answer Quickly

- Where are we right now?
- What is already built?
- What is still partial?
- What is the next priority?
- Which specialist agent should own the next task?

## Update Rule

Update this file whenever one of these changes:

- a major feature moves from partial to implemented
- the current MVP block changes
- a new blocker appears
- priorities change
