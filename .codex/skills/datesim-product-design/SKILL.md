---
name: datesim-product-design
description: Product and UX guidance for DateSim, a mobile-first AI dating conversation practice app. Use when Codex must design, review, or refine scenario selection, chat flow, scorecard feedback, rejected/completed states, session summary/history UX, onboarding, Spanish user-facing copy, or any mobile UI decision that affects the DateSim product experience.
---

# DateSim Product Design

## Purpose

Use this skill to keep DateSim focused as a practice product, not a generic chatbot or marketing surface. The product loop is: choose a scenario, talk to an AI character, receive per-turn scoring, and progress through feedback appropriate to difficulty.

## Sources Of Truth

Read only what is relevant for the task:

- `README.md`
- `docs/project/status.md`
- `docs/project/next-steps.md`
- `.github/agents/product-ux-designer.agent.md`
- `apps/flutter_app/lib/theme/app_theme.dart`
- `apps/flutter_app/lib/features/**/presentation/**`
- `apps/flutter_app/lib/features/**/widgets/**`
- `apps/flutter_app/test/features/**`

For contract-visible UI states, coordinate with `datesim-api-contracts` and check:

- `packages/contracts/src/index.ts`
- `apps/backend/src/**`
- `apps/flutter_app/lib/features/**/models/**`

## Product Principles

- Keep the app mobile-first, action-oriented, and practice-focused.
- The first useful screen should let the user start a scenario, not read a landing page.
- Do not hide missing backend behavior behind polished mock-only UX.
- Feedback must be calm, direct, and useful. Avoid shaming language.
- UI copy shown to users should be short, natural Spanish.
- Scenario difficulty should change feedback visibility and strictness, not the core chat affordance.
- Do not expand into profile, payments, progression, or release polish while Block 1 is unfinished unless explicitly requested.

## Workflow

1. Identify the current MVP block from `docs/project/next-steps.md`.
2. Read the current screen/widget and nearest tests before proposing UI changes.
3. Define the user's job for the moment:
   - choosing a scenario
   - waiting for data
   - creating a session
   - sending a message
   - reading the AI response
   - receiving scorecard feedback
   - handling rejection or completion
4. Define required states before calling the flow done:
   - loading
   - empty
   - ready
   - in progress
   - error and retry
   - rejected
   - completed, when supported by backend state
5. Make the smallest UI/product change that clarifies the workflow.
6. Ask `mobile-flutter-developer` to implement state/services/routing changes.
7. Ask `contracts-integration` when the UI depends on API payload shape, SSE event names, scorecard fields, or session status.

## DateSim Screen Guidance

### Scenario Selection

- Show real backend scenarios when available.
- Show loading, retry, empty, and create-session states explicitly.
- Surface scenario name, short description, difficulty, and enough character context to choose.
- Disable repeated taps while creating a session.
- Route into chat only after a real session id exists.

### Chat

- Keep chat as the core experience.
- Preserve the opening character message from the selected scenario.
- Disable input while a message is sending or when the session has ended.
- Show streaming assistant output progressively.
- Show errors without losing the conversation history.
- Rejection should be clear and respectful; it should explain that the session ended and prevent further input.

### Scorecard

- In easy difficulty, show per-turn scorecard feedback when returned.
- In medium/hard difficulty, avoid showing easy-mode coaching unless the product plan changes.
- Required visible fields: decision label, fluency, empathy, initiative, clarity, safety, overall, and reason.
- Labels should stay compact:
  - `Continuar`
  - `Enfriar`
  - `Rechazo`

### Session Summary And History

Only work on these after Block 1 end-to-end chat works:

- session summary UI
- list past sessions
- progression/history screen
- aggregate feedback trends

## UX Copy Rules

- Use Spanish for user-facing mobile text.
- Prefer concrete state text over generic placeholders.
- Keep errors actionable:
  - connectivity: suggest retry/check connection
  - auth: ask user to sign in again
  - backend: say the server could not complete the action
- Do not expose internal terms such as SSE, DTO, provider, or OpenAI in user-facing text.

## Validation

For UI or copy changes, ask the implementation agent to run:

- `flutter test`
- targeted widget tests under `apps/flutter_app/test/features/**`
- `flutter analyze` when Dart structure changes

If the local environment cannot run Flutter, report the exact missing tool and the remaining risk.
