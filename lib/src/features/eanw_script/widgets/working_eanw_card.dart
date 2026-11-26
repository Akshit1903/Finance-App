import 'dart:async';

import 'package:expense_and_net_worth_automation/src/features/eanw_script/eanw_script_viewmodel.dart';
import 'package:expense_and_net_worth_automation/src/features/eanw_script/widgets/eanw_details_view.dart';
import 'package:expense_and_net_worth_automation/src/utils/snackbar_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/transform_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class WorkingEanwCard extends StatefulWidget {
  final EanwScriptViewModel viewModel;

  const WorkingEanwCard({
    super.key,
    required this.viewModel,
  });

  @override
  State<WorkingEanwCard> createState() => _WorkingEanwCardState();
}

class _WorkingEanwCardState extends State<WorkingEanwCard> {
  StreamSubscription? _intentSub;

  @override
  void initState() {
    super.initState();
    // Listen for shared CSV files from other apps
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      if (value.length == 1 &&
          value[0].path.split('.').last.toLowerCase() == 'csv') {
        final path = value[0].path;
        _uploadCsv(path);
      }
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.length == 1 &&
          value[0].path.split('.').last.toLowerCase() == 'csv') {
        final path = value[0].path;
        _uploadCsv(path);
      }
      ReceiveSharingIntent.instance.reset();
    });
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  Future<void> _pickAndUploadCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null || !path.toLowerCase().endsWith('.csv')) {
      if (mounted) {
        SnackbarService.showSnackBar(
            'Please select a valid .csv file', context);
      }
      return;
    }
    await _uploadCsv(path);
  }

  Future<void> _uploadCsv(String path) async {
    try {
      await widget.viewModel.createEanwFromCsv(path);
      if (mounted) {
        SnackbarService.showSnackBar('EANW created successfully!', context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showSnackBar('Failed to create EANW: $e', context);
      }
    }
  }

  Future<void> _copySheetsLink(String sheetId) async {
    final url = TransformUtils.getGoogleSheetsUrl(sheetId);
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      SnackbarService.showSnackBar('Sheets link copied to clipboard', context);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Working EANW?'),
        content: const Text(
          'Are you sure you want to delete the working EANW sheet? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.viewModel.deleteWorkingEanw();
        if (mounted) {
          SnackbarService.showSnackBar('Working EANW deleted', context);
        }
      } catch (e) {
        if (mounted) {
          SnackbarService.showSnackBar('Failed to delete: $e', context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final theme = Theme.of(context);
    final workingRes = vm.workingEanwResponse;
    final hasSheet = workingRes?.hasWorkingSheet ?? false;
    final sheetId = workingRes?.workingEANWSheetsId ?? '';

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
            if ((vm.isCreatingEanw || vm.isDeletingWorkingEanw) &&
                !vm.isLoadingWorking)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            if (vm.isLoadingWorking) ...[
              Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.amber.shade800,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Finding Working EANW',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                color: Colors.amber.shade800,
                backgroundColor: Colors.amber.withValues(alpha: 0.2),
              ),
            ] else if (!hasSheet) ...[
              // Option to upload CSV ONLY
              Text(
                'Working EANW',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a CSV file to create the working Expenses and Net Worth sheet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: (vm.isCreatingEanw || vm.isLoadingWorking)
                    ? null
                    : _pickAndUploadCsv,
                icon: const Icon(Icons.upload_file),
                label: Text(
                  vm.isCreatingEanw ? 'Uploading CSV...' : 'Select CSV File',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ] else ...[
              // Uploaded status with 2 primary options: copy link and delete
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'Working EANW: Uploaded',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copySheetsLink(sheetId),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Link'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          vm.isDeletingWorkingEanw ? null : _confirmDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(
                        vm.isDeletingWorkingEanw ? 'Deleting...' : 'Delete',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (workingRes?.workingEANWSheet != null) ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EanwDetailsView(
                          title: 'Working EANW',
                          details: workingRes!.workingEANWSheet!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('View Working EANW Breakdown'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
