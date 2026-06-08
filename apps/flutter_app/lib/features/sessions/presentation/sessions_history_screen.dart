import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/models/scenario.dart';
import '../../home/providers/scenarios_providers.dart';
import '../models/session.dart';
import '../providers/sessions_providers.dart';
import 'session_summary_screen.dart';

class SessionsHistoryScreen extends ConsumerWidget {
  const SessionsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final scenarios = ref.watch(scenariosProvider).value ?? const <Scenario>[];
    final scenarioNames = {
      for (final scenario in scenarios) scenario.id: scenario.name,
    };

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Tu progreso'),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _HistoryError(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(sessionsProvider),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const _EmptyHistory();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sessionsProvider);
              await ref.read(sessionsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProgressOverview(sessions: sessions),
                const SizedBox(height: 24),
                Text(
                  'Prácticas recientes',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                for (final session in sessions) ...[
                  _SessionTile(
                    session: session,
                    scenarioName:
                        scenarioNames[session.scenarioId] ?? 'Escenario',
                    onTap:
                        session.status == SessionStatus.completed ||
                            session.status == SessionStatus.rejected
                        ? () => context.push(
                            '/summary',
                            extra: SessionSummaryArgs(
                              scenarioName:
                                  scenarioNames[session.scenarioId] ??
                                  'Escenario',
                              status: session.status,
                              overallScore: session.overallScore,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview({required this.sessions});

  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    final finished = sessions
        .where(
          (session) =>
              session.status == SessionStatus.completed ||
              session.status == SessionStatus.rejected,
        )
        .toList();
    final scores = finished
        .map((session) => session.overallScore)
        .whereType<double>()
        .toList();
    final average = scores.isEmpty
        ? null
        : scores.reduce((sum, score) => sum + score) / scores.length;
    final completed = finished
        .where((session) => session.status == SessionStatus.completed)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Prácticas',
                    value: '${finished.length}',
                  ),
                ),
                Expanded(
                  child: _Metric(label: 'Completadas', value: '$completed'),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Media',
                    value: average?.toStringAsFixed(1) ?? '--',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.scenarioName,
    this.onTap,
  });

  final Session session;
  final String scenarioName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _statusPresentation(session.status);

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: status.color.withValues(alpha: 0.12),
          child: Icon(status.icon, color: status.color),
        ),
        title: Text(scenarioName),
        subtitle: Text('${status.label} · ${_formatDate(session.createdAt)}'),
        trailing: session.overallScore == null
            ? (onTap == null ? null : const Icon(Icons.chevron_right))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    session.overallScore!.toStringAsFixed(1),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right),
                ],
              ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes prácticas guardadas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Empezar una práctica'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 52),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

({String label, IconData icon, Color color}) _statusPresentation(
  SessionStatus status,
) {
  return switch (status) {
    SessionStatus.active => (
      label: 'En curso',
      icon: Icons.play_arrow_rounded,
      color: Colors.blue,
    ),
    SessionStatus.completed => (
      label: 'Completada',
      icon: Icons.check_rounded,
      color: Colors.green,
    ),
    SessionStatus.rejected => (
      label: 'Terminada',
      icon: Icons.close_rounded,
      color: Colors.red,
    ),
    SessionStatus.abandoned => (
      label: 'Abandonada',
      icon: Icons.remove_rounded,
      color: Colors.grey,
    ),
  };
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}
