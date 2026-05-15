import 'package:flutter/material.dart';

import '../models/scorecard.dart';

class ScorecardDisplay extends StatelessWidget {
  final Scorecard scorecard;
  final VoidCallback? onDismiss;

  const ScorecardDisplay({
    super.key,
    required this.scorecard,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Evaluacion del mensaje',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _DecisionBadge(decision: scorecard.decision),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    tooltip: 'Ocultar scorecard',
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _MetricRow(label: 'Fluidez', value: scorecard.fluency),
            _MetricRow(label: 'Empatia', value: scorecard.empathy),
            _MetricRow(label: 'Iniciativa', value: scorecard.initiative),
            _MetricRow(label: 'Claridad', value: scorecard.clarity),
            _MetricRow(label: 'Seguridad', value: scorecard.safety),
            const SizedBox(height: 8),
            Text(
              'Total: ${scorecard.overall.toStringAsFixed(1)}/10',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              scorecard.reason,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedValue = value.clamp(0, 10).toDouble();
    final progress = clampedValue / 10;
    final color = _scoreColor(theme, clampedValue);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                '${clampedValue.toStringAsFixed(1)}/10',
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              color: color,
              backgroundColor: theme.colorScheme.surface,
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(ThemeData theme, double value) {
    if (value <= 3) return theme.colorScheme.error;
    if (value <= 6) return theme.colorScheme.tertiary;
    return theme.colorScheme.primary;
  }
}

class _DecisionBadge extends StatelessWidget {
  final ScorecardDecision decision;

  const _DecisionBadge({required this.decision});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (text, color) = switch (decision) {
      ScorecardDecision.continueDecision =>
        ('Continuar', theme.colorScheme.primary),
      ScorecardDecision.coolDown => ('Enfriar', theme.colorScheme.tertiary),
      ScorecardDecision.reject => ('Rechazo', theme.colorScheme.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
