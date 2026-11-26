import 'package:expense_and_net_worth_automation/src/models/validation.dart';
import 'package:flutter/material.dart';

/// Renders a single validation item with pass/fail styling and failure message.
class ValidationCard extends StatelessWidget {
  final Validation validation;

  const ValidationCard({super.key, required this.validation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passed = validation.passed;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: passed
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: passed ? Colors.green : Colors.red,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                passed ? Icons.check_circle : Icons.cancel,
                color: passed ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      validation.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!passed &&
                        validation.failureMessage != null &&
                        validation.failureMessage!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        validation.failureMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
