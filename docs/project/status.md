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
- chat service with SSE streaming design
- scoring service with structured JSON result
- sessions module to create and list sessions

Partial:
- scoring dimensions are simpler than the longer product vision
- scene direction logic exists only as lightweight steering in chat flow
- contracts package is not yet acting as the real source of truth

Missing:
- stronger schema-based shared contracts
- richer post-session feedback
- progression/history features
- production-grade moderation path

### Mobile App

Implemented:
- Flutter app structure with feature-first organization
- auth flow scaffold with Firebase providers
- login screen
- home screen scaffold
- chat screen scaffold
- router with auth redirects
- theme system

Partial:
- chat screen is still partly mock-oriented
- backend integration is not complete end-to-end
- scenario loading and session creation are not fully connected to live backend data

Missing:
- real SSE integration in chat flow
- real session lifecycle in UI
- scorecard display in easy mode
- rejected/completed session UX
- profile and progress surfaces

### Repo / Tooling

Implemented:
- workspace customization structure for Copilot is in progress / partially present depending on branch state
- CI workflow exists
- project PDFs and higher-level planning have informed architecture decisions

Missing:
- fully operational shared contracts workflow
- evals pipeline for prompts
- release automation maturity

## MVP Phase

The project is in the stage between:
- architecture and repo setup completed enough to start integration work
- MVP feature completion still pending

The current practical phase is:
**connect the mobile app to the real backend and complete the first usable end-to-end conversation flow**.

## Immediate Next Step

Highest-value next block:

### Block: Mobile ↔ Backend integration

Goals:
- load real scenarios from backend
- create real sessions from mobile
- send real messages from mobile
- consume SSE response stream
- render scorecard when applicable

Suggested order:
1. scenarios service in Flutter
2. sessions service in Flutter
3. chat API/SSE service in Flutter
4. Riverpod providers for those services
5. connect home screen to scenarios endpoint
6. connect scenario selection to session creation
7. connect chat screen to streaming endpoint
8. handle done / rejected / scorecard events

## Current Risks

- product docs are ahead of the implementation in scoring sophistication
- mobile UX can move faster than backend integration if not sequenced carefully
- contracts can drift between backend and mobile if `packages/contracts` is not strengthened soon

## Questions This File Should Answer Quickly

- Where are we right now?
- What is already built?
- What is the next priority?
- What is blocked or partial?
- Which subsystem should be worked on next?

## Update Rule

Update this file whenever one of these changes:
- a major feature moves from partial to implemented
- the current MVP block changes
- a new blocker appears
- priorities change
