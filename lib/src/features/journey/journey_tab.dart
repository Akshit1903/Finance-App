import 'package:expense_and_net_worth_automation/src/features/journey/step_registry.dart';
import 'package:expense_and_net_worth_automation/src/models/journey.dart';
import 'package:expense_and_net_worth_automation/src/providers/journey_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Journey tab: stepper overview of all journey steps with live evaluation states.
class JourneyTab extends StatelessWidget {
  const JourneyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final journeyProvider = context.watch<JourneyProvider>();
    final steps = journeyProvider.steps;

    // Centered stepper for evaluation or normal scrolling list
    return RefreshIndicator(
      onRefresh: journeyProvider.evaluateJourney,
      child: Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Journey Complete banner
              if (journeyProvider.isJourneyComplete)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Journey Complete',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                      ),
                    ],
                  ),
                ),

              // Step cards
              ...steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return _StepCard(
                  step: step,
                  stepNumber: index + 1,
                  isLast: index == steps.length - 1,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final JourneyStep step;
  final int stepNumber;
  final bool isLast;

  const _StepCard({
    required this.step,
    required this.stepNumber,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = step.stepStatus == StepStatus.pending;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stepper rail
        Column(
          children: [
            _buildStatusIcon(theme),
            if (!isLast)
              Container(
                width: 2,
                height: 64,
                color: step.stepStatus == StepStatus.completed
                    ? Colors.green
                    : theme.colorScheme.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 14),

        // Step card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 0,
              color: isPending
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: step.stepStatus == StepStatus.inProgress
                    ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                    : BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: Icon(StepRegistry.getIconForStep(step.id)),
                enabled: !isPending,
                title: Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isPending ? theme.colorScheme.outline : null,
                  ),
                ),
                subtitle: Text(
                  _statusText,
                  style: TextStyle(
                    color: isPending ? theme.colorScheme.outline : _statusColor,
                    fontSize: 12,
                  ),
                ),
                trailing: isPending ? null : const Icon(Icons.chevron_right),
                onTap: isPending ? null : () => _navigateToStep(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(ThemeData theme) {
    if (step.isEvaluating) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: Padding(
          padding: EdgeInsets.all(2.0),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    switch (step.stepStatus) {
      case StepStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green, size: 28);
      case StepStatus.inProgress:
        return Icon(Icons.play_circle_filled,
            color: theme.colorScheme.primary, size: 28);
      case StepStatus.pending:
        return Icon(Icons.circle_outlined,
            color: theme.colorScheme.outline, size: 28);
    }
  }

  String get _statusText {
    if (step.isEvaluating) return 'Checking status...';
    switch (step.stepStatus) {
      case StepStatus.completed:
        return 'Completed';
      case StepStatus.inProgress:
        return 'In Progress';
      case StepStatus.pending:
        return 'Pending';
    }
  }

  Color get _statusColor {
    switch (step.stepStatus) {
      case StepStatus.completed:
        return Colors.green;
      case StepStatus.inProgress:
        return Colors.amber.shade800;
      case StepStatus.pending:
        return Colors.grey;
    }
  }

  void _navigateToStep(BuildContext context) {
    final view = StepRegistry.getViewForStep(step);
    if (view == null) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => view,
    ));
  }
}
