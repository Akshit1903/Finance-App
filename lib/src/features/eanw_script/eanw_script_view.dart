import 'package:expense_and_net_worth_automation/src/features/eanw_script/eanw_script_viewmodel.dart';
import 'package:expense_and_net_worth_automation/src/features/eanw_script/widgets/shimmer_validation_card.dart';
import 'package:expense_and_net_worth_automation/src/features/eanw_script/widgets/submit_section.dart';
import 'package:expense_and_net_worth_automation/src/features/eanw_script/widgets/validation_section.dart';
import 'package:expense_and_net_worth_automation/src/features/eanw_script/widgets/working_eanw_card.dart';
import 'package:expense_and_net_worth_automation/src/features/external_transactions/external_transactions_page.dart';
import 'package:expense_and_net_worth_automation/src/models/journey.dart';
import 'package:flutter/material.dart';

/// Main view for the EANW Script journey step.
class EanwScriptView extends StatefulWidget {
  final JourneyStep step;
  final bool embedded;

  const EanwScriptView({
    super.key,
    required this.step,
    this.embedded = false,
  });

  @override
  State<EanwScriptView> createState() => _EanwScriptViewState();
}

class _EanwScriptViewState extends State<EanwScriptView> {
  late final EanwScriptViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EanwScriptViewModel(step: widget.step);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => _buildBody(context),
    );

    if (widget.embedded) return body;

    return Scaffold(
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final vr = _viewModel.validationResponse;

    return RefreshIndicator(
      onRefresh: () async {
        await _viewModel.fetchWorkingEanw();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error banner
            if (_viewModel.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MaterialBanner(
                    backgroundColor: theme.colorScheme.errorContainer,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    content: Text(
                      _viewModel.error!,
                      style: TextStyle(
                          color: theme.colorScheme.onErrorContainer),
                    ),
                    actions: [
                      TextButton(
                        onPressed: _viewModel.fetchWorkingEanw,
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 1. Working EANW Card (CSV upload / Sheets link / Delete / View breakdown)
            WorkingEanwCard(viewModel: _viewModel),

            const SizedBox(height: 12),

            // 2. Manage External Transactions button
            _buildManageExternalTransactionsButton(context),

            const SizedBox(height: 12),

            // 3. Validation banner & section
            if (_viewModel.isLoadingValidations) ...[
              const SizedBox(height: 8),
              Text(
                'Loading Validations...',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              const ShimmerValidationCard(),
              const ShimmerValidationCard(),
              const ShimmerValidationCard(),
            ] else if (vr != null) ...[
              _buildValidationBanner(theme, vr.isSuccess),
              if (vr.failedValidations.isNotEmpty)
                ValidationSection(
                  title: 'Failed Validations',
                  validations: vr.failedValidations,
                  initiallyExpanded: true,
                ),
              if (vr.passedValidations.isNotEmpty)
                ValidationSection(
                  title: 'Passed Validations',
                  validations: vr.passedValidations,
                  initiallyExpanded: false,
                ),
            ],

            const SizedBox(height: 12),

            // 4. Submit & Commit section
            SubmitSection(viewModel: _viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationBanner(ThemeData theme, bool isSuccess) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSuccess
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 26,
          ),
          const SizedBox(width: 12),
          Text(
            isSuccess ? 'All validations passed' : 'Some validations failed',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageExternalTransactionsButton(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        leading: const Icon(Icons.swap_horiz, color: Colors.deepPurple),
        title: const Text('Manage External Transactions'),
        subtitle: const Text('Review or modify external entries'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).pushNamed(ExternalTransactionsPage.routeName);
        },
      ),
    );
  }
}
