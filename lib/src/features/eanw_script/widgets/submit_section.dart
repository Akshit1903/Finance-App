import 'package:expense_and_net_worth_automation/src/features/eanw_script/eanw_script_viewmodel.dart';
import 'package:expense_and_net_worth_automation/src/providers/journey_provider.dart';
import 'package:expense_and_net_worth_automation/src/utils/snackbar_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Section providing Evaluate EANW and Commit EANW actions.
class SubmitSection extends StatelessWidget {
  final EanwScriptViewModel viewModel;

  const SubmitSection({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSheet = viewModel.hasWorkingSheet;
    final allPassed = viewModel.allValidationsPassed;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Actions & Commit',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Evaluate EANW button
            FilledButton.tonalIcon(
              onPressed: (!hasSheet ||
                      viewModel.isEvaluatingEanw ||
                      viewModel.isLoadingValidations ||
                      viewModel.isCommitting)
                  ? null
                  : () async {
                      try {
                        await viewModel.evaluateEanw();
                        if (context.mounted) {
                          SnackbarService.showSnackBar(
                            'Evaluation complete! Validations updated.',
                            context,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          SnackbarService.showSnackBar(
                            'Evaluation failed: $e',
                            context,
                          );
                        }
                      }
                    },
              icon: viewModel.isEvaluatingEanw
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                viewModel.isEvaluatingEanw
                    ? 'Evaluating EANW...'
                    : 'Evaluate EANW',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 12),

            // Commit button
            FilledButton.icon(
              onPressed: viewModel.canCommit
                  ? () async {
                      try {
                        await viewModel.commitEanw(() {
                          if (context.mounted) {
                            SnackbarService.showSnackBar(
                              'EANW committed successfully!',
                              context,
                            );
                            // Evaluate the journey after commit
                            context.read<JourneyProvider>().evaluateJourney();
                          }
                        });
                      } catch (e) {
                        if (context.mounted) {
                          SnackbarService.showSnackBar(
                            'Commit failed: $e',
                            context,
                          );
                        }
                      }
                    }
                  : null,
              icon: viewModel.isCommitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                viewModel.isCommitting ? 'Committing...' : 'Commit EANW',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor:
                    allPassed ? Colors.green.shade700 : null,
              ),
            ),

            if (!allPassed && hasSheet)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Commit is blocked until all validations pass.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
