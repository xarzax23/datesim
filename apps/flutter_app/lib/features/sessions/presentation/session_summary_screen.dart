import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/session.dart';

class SessionSummaryArgs {
  const SessionSummaryArgs({
    required this.scenarioName,
    required this.status,
    this.overallScore,
    this.feedback,
  });

  final String scenarioName;
  final SessionStatus status;
  final double? overallScore;
  final String? feedback;
}

class SessionSummaryScreen extends StatelessWidget {
  const SessionSummaryScreen({super.key, required this.args});

  final SessionSummaryArgs args;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = args.status == SessionStatus.completed;
    final rejected = args.status == SessionStatus.rejected;
    final color = completed
        ? theme.colorScheme.primary
        : rejected
        ? theme.colorScheme.error
        : theme.colorScheme.secondary;
    final title = completed
        ? 'Práctica completada'
        : rejected
        ? 'La conversación terminó'
        : 'Resumen de la práctica';
    final description = completed
        ? 'Has guardado el resultado de esta práctica.'
        : rejected
        ? 'Revisa el feedback y vuelve a intentarlo cuando quieras.'
        : 'Aquí tienes el estado guardado de esta práctica.';

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              completed
                  ? Icons.check_circle_outline
                  : rejected
                  ? Icons.sentiment_dissatisfied_outlined
                  : Icons.insights_outlined,
              size: 72,
              color: color,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              args.scenarioName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (args.overallScore != null) ...[
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      args.overallScore!.toStringAsFixed(1),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Puntuación global / 10',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            if (args.feedback?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feedback',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(args.feedback!),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.replay),
              label: const Text('Practicar de nuevo'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.go('/history'),
              icon: const Icon(Icons.history),
              label: const Text('Ver historial'),
            ),
          ],
        ),
      ),
    );
  }
}
