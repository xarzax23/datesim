# Next Steps

## Current Focus

Complete the first real end-to-end MVP flow:

1. load scenarios from backend
2. create a session from mobile
3. send chat messages to backend
4. receive SSE streaming responses
5. render scorecard when applicable
6. handle session end states

## Current Block

### Block 1 — Mobile ↔ Backend Integration

#### Goal

Replace mock/mobile-only conversation flow with real backend-driven data and SSE streaming.

#### Tasks

- [ ] Create Flutter scenarios service to consume `GET /scenarios`
- [ ] Create Flutter sessions service to consume `POST /sessions` and `GET /sessions`
- [ ] Create Flutter chat service to call `POST /sessions/:sessionId/messages`
- [ ] Implement SSE parsing in Flutter for `delta`, `scorecard`, `done`, and `error`
- [ ] Create Riverpod providers for scenarios, sessions, and chat
- [ ] Connect home screen to real scenarios endpoint
- [ ] Connect scenario selection to real session creation
- [ ] Connect chat screen to real backend messages
- [ ] Handle `rejected` and `done` states in chat UI
- [ ] Show scorecard in easy difficulty

#### Definition of Done

- A signed-in user can select a real scenario from backend data
- A real session is created in backend
- The user can send a real message
- The assistant response streams progressively in the chat UI
- If a scorecard is returned, it is rendered in the UI
- If the session is rejected, the UI reflects it correctly

## Next Block After That

### Block 2 — Session UX Completion

- [ ] Session summary UI
- [ ] List past sessions
- [ ] Basic progression/history screen
- [ ] Cleaner error and retry states in chat

## Important Constraints

- Do not expand scoring complexity before mobile-backend integration works end to end
- Do not build profile/progress screens before real session data is flowing
- Do not let backend/mobile contracts drift; strengthen `packages/contracts` soon after Block 1

## Open Risks

- SSE handling in Flutter may require careful parsing and cancellation management
- Scorecard payload shape may need alignment between backend and mobile
- Contracts package is still weaker than intended and can become a source of divergence

## Short Weekly Plan

### This week

- Finish services for scenarios, sessions, and chat
- Wire providers into home and chat flows
- Replace mocked chat behavior with backend-driven behavior

### Next week

- Polish chat state handling
- Add session summary and history basics
- Start strengthening shared contracts

## Update Rule

Update this file whenever:
- the current implementation block changes
- a checklist item is completed
- a blocker changes the recommended order
- the project moves from one MVP block to the next
