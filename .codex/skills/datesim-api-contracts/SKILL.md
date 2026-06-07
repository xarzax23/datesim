---
name: datesim-api-contracts
description: Contract and integration guidance for DateSim backend, Flutter mobile app, shared TypeScript contracts, and SSE chat events. Use when Codex must align API routes, DTOs, TypeScript interfaces, Dart models, Riverpod services, Firebase-authenticated calls, scorecard payloads, session/scenario shapes, or backend-mobile mismatches such as event names, encoded JSON, status values, or field naming.
---

# DateSim API Contracts

## Purpose

Use this skill to prevent drift between backend producers, Flutter consumers, and `packages/contracts`. Contract-visible changes must be updated across all affected layers, not only in one file.

## Sources Of Truth

Read the narrowest relevant set:

- `docs/project/status.md`
- `docs/project/next-steps.md`
- `.github/agents/contracts-integration.agent.md`
- `packages/contracts/src/index.ts`
- `apps/backend/src/**/controller.ts`
- `apps/backend/src/**/service.ts`
- `apps/backend/src/**/dto/*.ts`
- `apps/backend/src/entities/*.ts`
- `apps/flutter_app/lib/features/**/models/*.dart`
- `apps/flutter_app/lib/features/**/data/*.dart`
- `apps/flutter_app/lib/features/**/providers/*.dart`
- nearest backend and Flutter tests

## Current MVP Contract Surface

Check implementation before editing, but Block 1 revolves around:

- `GET /api/v1/scenarios`
- `GET /api/v1/scenarios/:id`
- `POST /api/v1/sessions`
- `GET /api/v1/sessions`
- `POST /api/v1/sessions/:sessionId/messages`

All mobile requests that need user identity should send Firebase bearer auth when available.

## Known Drift To Resolve

Before declaring Block 1 complete, verify and align these known mismatch risks:

- SSE event name: shared contracts may say `token`, while backend/mobile use `delta`.
- Scorecard text field: shared contracts may say `feedback`, while backend/mobile use `reason`.
- Scorecard payload shape: backend may encode scorecard JSON inside `data`, while contracts may model it as an object.
- Done event shape: backend/mobile may use `data: "ok"` or `data: "rejected"`, while contracts may model a richer object.
- Public scenario response must not expose `systemPrompt`.

Do not fix only the documentation. Align producers, consumers, contracts, and tests together unless the mismatch is intentionally documented as temporary.

## Canonicalization Workflow

1. Find all producers and consumers:
   - backend controller/service/DTO/entity
   - `packages/contracts`
   - Flutter model/service/provider
   - tests
2. Identify the runtime shape currently used by the app.
3. Decide the canonical shape for the current MVP, preserving existing working behavior unless there is a concrete bug.
4. Update in this order:
   - `packages/contracts/src/index.ts`
   - backend DTO/event producer
   - Flutter parser/model/service
   - tests for parsing, state transitions, and endpoint behavior
   - planning docs if the change alters project status
5. Run focused validation.

## Preferred Shapes

Use explicit names and typed data. Avoid adding new event types unless the UI needs them.

### Scenario

Public mobile scenario fields:

- `id`
- `name`
- `description`
- `difficulty`
- `characterName`
- `characterBio`
- `openingMessage`

Private backend-only field:

- `systemPrompt`

### Session

Session status values:

- `active`
- `completed`
- `rejected`
- `abandoned`

Create session request:

- `scenarioId`
- `difficulty`

### Scorecard

Current MVP dimensions:

- `fluency`
- `empathy`
- `initiative`
- `clarity`
- `safety`
- `overall`
- `decision`
- `reason`

Decision values:

- `continue`
- `cool_down`
- `reject`

### Chat SSE Events

Keep event parsing explicit in Flutter. The current app expects logical events for:

- assistant text chunk
- scorecard
- done
- error

If using `delta` as the chunk event, ensure contracts also say `delta`. If choosing `token`, update backend and mobile together. Do not leave both names active without a compatibility reason.

## Coordination Rules

- Use `backend-api-developer` for NestJS route, auth, validation, persistence, and SSE producer changes.
- Use `mobile-flutter-developer` for Dart models, services, Riverpod state, and UI consumption.
- Use `llm-scenarios-scoring` for scorecard semantics, prompt behavior, rejection behavior, or scenario content.
- Use `qa-release-engineer` for regression tests and CI readiness.
- Use `product-ux-designer` when payload changes affect visible states or Spanish copy.

## Validation

Use the smallest useful set:

- backend: `npm run test`, `npm run test:e2e`, `npm run build`
- contracts: `npm run build`
- Flutter: `flutter test`, `flutter analyze`

If validation cannot run because dependencies or SDKs are missing, report the exact command and missing executable.
