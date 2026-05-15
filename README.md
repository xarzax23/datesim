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

## Scorecard En Chat (MVP Core)

La app móvil incluye scorecard por turno cuando la dificultad del escenario es **easy**.

- Parseo de evento SSE `scorecard` a modelo tipado.
- Validación de métricas en rango `0..10`.
- Visualización en UI con barras para Fluidez, Empatía, Iniciativa, Claridad y Seguridad.
- Badge de decisión (`Continuar`, `Enfriar`, `Rechazo`) y razón explicativa.
- Renderizado condicional para no interferir con dificultades medium/hard.

Archivos clave:

- `apps/flutter_app/lib/features/chat/models/scorecard.dart`
- `apps/flutter_app/lib/features/chat/models/chat_event.dart`
- `apps/flutter_app/lib/features/chat/providers/chat_providers.dart`
- `apps/flutter_app/lib/features/chat/widgets/scorecard_display.dart`
- `apps/flutter_app/lib/features/chat/presentation/chat_screen.dart`
