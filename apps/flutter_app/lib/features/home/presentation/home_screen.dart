import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
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
              child: ListView(
                children: [
                  _ScenarioCard(
                    title: 'Primera cita en cafetería',
                    description:
                        'Conoce a alguien nuevo en un ambiente relajado',
                    difficulty: 'Fácil',
                    icon: Icons.coffee,
                    color: Colors.green,
                    onTap: () {
                      // TODO: iniciar sesión de chat
                    },
                  ),
                  const SizedBox(height: 12),
                  _ScenarioCard(
                    title: 'Cena romántica',
                    description: 'Una cita más formal con expectativas altas',
                    difficulty: 'Media',
                    icon: Icons.restaurant,
                    color: Colors.orange,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _ScenarioCard(
                    title: 'Encuentro inesperado',
                    description:
                        'Te encuentras con alguien atractivo en una fiesta',
                    difficulty: 'Difícil',
                    icon: Icons.celebration,
                    color: Colors.red,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final String title;
  final String description;
  final String difficulty;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ScenarioCard({
    required this.title,
    required this.description,
    required this.difficulty,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(difficulty, style: TextStyle(color: color)),
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
