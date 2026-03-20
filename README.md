# DateSim — Simulador de Conversaciones de Citas

Monorepo para la app de simulación de conversaciones centrada en citas.

## Estructura

```
apps/
  flutter_app/     # App móvil (Flutter)
  backend/         # API REST (NestJS)
packages/
  contracts/       # JSON Schema + tipos compartidos
  llm-client/      # Cliente OpenAI con streaming SSE
  scoring/         # Motor de scoring por turno
  evals/           # Tests de prompts y regresión
infra/             # IaC y scripts de deploy
docs/              # ADRs, guías de prompts
.github/workflows/ # CI/CD
```

## Stack

| Capa | Tecnología |
|------|-----------|
| Móvil | Flutter |
| Backend | NestJS (TypeScript) |
| Auth | Firebase Auth |
| LLM | OpenAI (GPT-4o-mini) |
| DB | PostgreSQL (Cloud SQL) |
| Pagos | RevenueCat + IAP nativo |
| Cloud | GCP (Cloud Run) |
| CI/CD | GitHub Actions + Fastlane |

## Fases MVP

- **Fase 0** (semanas 1-2): Auth + estructura + deploy básico
- **MVP Core** (semanas 3-6): Chat con scoring, 1 escenario, streaming SSE
- **MVP Completo** (semanas 7-10): Múltiples escenarios, dificultades, pagos, progreso
