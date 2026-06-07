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

Partial:

- scoring dimensions are simpler than the longer product vision
- scene direction logic exists only as lightweight steering in chat flow
- production-grade moderation path is not yet defined
- completed-session lifecycle is not fully modeled in user-facing UX

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
- tests around scorecard parsing/display and chat state transitions

Partial:

- rejected/done UX is MVP-basic and still needs product polish
- session lifecycle UI is not complete beyond active/rejected chat behavior
- backend integration still needs real environment/device validation

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
- Local backend runs against Docker PostgreSQL on port `55432`; Swagger and public scenario endpoint are verified
- Android SDK/Android Studio is not installed yet, so Android emulator/device builds are not ready

Missing:

- fully operational shared contracts workflow beyond the current aligned TypeScript types
- contract regression tests across backend/mobile expectations
- release automation maturity

## MVP Phase

The project is still in:

**Block 1 - Mobile Backend Integration**

The practical focus is no longer creating the first pass of mobile services; that work is mostly present. The focus now is:

1. validate the authenticated end-to-end conversation flow in a prepared local or CI environment
2. add focused regression coverage where smoke testing exposes gaps
3. then move to session UX completion

## Immediate Next Step

Highest-value next block of work inside Block 1:

### Verification Before Block 2

Goals:

- run a real end-to-end smoke test with Firebase, PostgreSQL, and OpenAI environment configured
- add focused tests for any uncovered parsing or state-transition gaps
- keep public scenario payloads free of `systemPrompt`

Suggested owner sequence:

1. `qa-release-engineer`
2. `backend-api-developer`
3. `mobile-flutter-developer`
4. `delivery-manager`

## Current Risks

- product docs can become stale because implementation has moved ahead of the old checklist
- contracts can drift again if future backend/mobile changes do not update `packages/contracts`
- Android emulator/device validation requires Android SDK/Android Studio
- OpenAI/Firebase/PostgreSQL paths still require environment-backed integration validation

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
