import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/scenario.dart';
import '../providers/scenarios_providers.dart';
import '../../sessions/providers/sessions_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scenariosAsync = ref.watch(scenariosProvider);

    ref.listen(createSessionProvider, (_, next) {
      next.whenOrNull(
        data: (session) {
          if (session != null) {
            final scenario = ref.read(selectedScenarioProvider);
            ref.read(selectedScenarioProvider.notifier).state = null;
            context.go('/chat/${session.id}', extra: scenario);
          }
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', '')),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        },
      );
    });

    final isCreating = ref.watch(
      createSessionProvider.select((s) => s.isLoading),
    );

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('DateSim'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  // TODO: navegar a perfil
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola! 👋',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elige un escenario para practicar',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: scenariosAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _ErrorView(
                      message:
                          error.toString().replaceFirst('Exception: ', ''),
                      onRetry: () => ref.invalidate(scenariosProvider),
                    ),
                    data: (scenarios) => scenarios.isEmpty
                        ? const Center(
                            child: Text('No hay escenarios disponibles.'))
                        : ListView.separated(
                            itemCount: scenarios.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final scenario = scenarios[index];
                              return _ScenarioCard(
                                scenario: scenario,
                                isLoading: isCreating,
                                onTap: () {
                                  ref
                                      .read(selectedScenarioProvider.notifier)
                                      .state = scenario;
                                  ref
                                      .read(createSessionProvider.notifier)
                                      .create(
                                        scenario.id,
                                        scenario.difficulty.name,
                                      );
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isCreating)
          const ModalBarrier(dismissible: false, color: Colors.black26),
        if (isCreating) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          FilledButton.tonal(
              onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.scenario,
    required this.onTap,
    required this.isLoading,
  });

  final Scenario scenario;
  final VoidCallback onTap;
  final bool isLoading;

  static const _difficultyColors = {
    Difficulty.easy: Colors.green,
    Difficulty.medium: Colors.orange,
    Difficulty.hard: Colors.red,
  };

  static const _difficultyIcons = {
    Difficulty.easy: Icons.coffee,
    Difficulty.medium: Icons.restaurant,
    Difficulty.hard: Icons.celebration,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _difficultyColors[scenario.difficulty] ?? Colors.grey;
    final icon = _difficultyIcons[scenario.difficulty] ?? Icons.star;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scenario.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  scenario.difficulty.label,
                  style: TextStyle(color: color),
                ),
                backgroundColor: color.withValues(alpha: 0.1),
                side: BorderSide.none,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
