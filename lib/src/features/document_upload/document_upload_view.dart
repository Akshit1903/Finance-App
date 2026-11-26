import 'dart:io';

import 'package:expense_and_net_worth_automation/src/features/document_upload/document_upload_viewmodel.dart';
import 'package:expense_and_net_worth_automation/src/models/document_upload.dart';
import 'package:expense_and_net_worth_automation/src/models/journey.dart';
import 'package:expense_and_net_worth_automation/src/providers/journey_provider.dart';
import 'package:expense_and_net_worth_automation/src/utils/snackbar_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/transform_utils.dart';
import 'package:expense_and_net_worth_automation/src/utils/upload_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// View for the document upload journey step.
class DocumentUploadView extends StatefulWidget {
  final JourneyStep step;
  final bool embedded;

  const DocumentUploadView({
    super.key,
    required this.step,
    this.embedded = false,
  });

  @override
  State<DocumentUploadView> createState() => _DocumentUploadViewState();
}

class _DocumentUploadViewState extends State<DocumentUploadView> {
  late final DocumentUploadViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DocumentUploadViewModel(
      journeyProvider: context.read<JourneyProvider>(),
    );
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
    if (_viewModel.isLoadingDocuments && _viewModel.documents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_viewModel.isLoading) const LinearProgressIndicator(),
        if (_viewModel.errors.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Text(
              _viewModel.errors.join('\n'),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _viewModel.fetchDocuments,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _viewModel.documents.length + 1,
              itemBuilder: (context, index) {
                if (index < _viewModel.documents.length) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildDocumentCard(
                        context, _viewModel.documents[index]),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: FilledButton.icon(
                    onPressed: (!_viewModel.hasSelectedDocuments ||
                            _viewModel.isLoading)
                        ? null
                        : _viewModel.uploadAllDocuments,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Upload All'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(BuildContext context, UploadDocument doc) {
    final isUploaded = doc.isUploaded;
    final isSelected = doc.uploadStatus == UploadStatus.SELECTED;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: isUploaded
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          doc.icon,
          color: isUploaded
              ? Colors.green
              : isSelected
                  ? Colors.teal
                  : theme.colorScheme.primary,
        ),
        title: Text(
          doc.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isUploaded ? theme.colorScheme.outline : null,
          ),
        ),
        subtitle: Text(
          _resolveSubtitle(doc),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isUploaded ? Colors.green.shade700 : null,
          ),
        ),
        trailing: isUploaded
            ? IconButton(
                icon: const Icon(Icons.link),
                tooltip: 'Copy Drive Link',
                onPressed: () => _copyDriveLink(doc),
              )
            : doc.uploadStatus.icon,
        onTap: () => _handleTap(doc),
      ),
    );
  }

  String _resolveSubtitle(UploadDocument doc) {
    if (doc.isUploaded) return 'Uploaded';
    switch (doc.uploadStatus) {
      case UploadStatus.NOT_INITIATED:
        return 'Pending';
      case UploadStatus.SELECTED:
        return doc.path?.split(Platform.pathSeparator).last ?? 'File selected';
      case UploadStatus.QUEUED:
        return 'Queued...';
      case UploadStatus.DECRYPTING:
        return 'Decrypting...';
      case UploadStatus.RESOLVE_FOLDER_ID:
        return 'Resolving folder...';
      case UploadStatus.UPLOADING:
        return 'Uploading...';
      case UploadStatus.SUCCESS:
        return 'Uploaded successfully';
      case UploadStatus.FAILURE:
        return 'Upload failed';
    }
  }

  Future<void> _copyDriveLink(UploadDocument doc) async {
    final url = TransformUtils.resolveDriveFileUrl(doc.uploadedFileId);
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      SnackbarService.showSnackBar('Drive link copied to clipboard', context);
    }
  }

  void _handleTap(UploadDocument doc) async {
    if (doc.isUploaded) {
      await _copyDriveLink(doc);
      return;
    }

    switch (doc.uploadStatus) {
      case UploadStatus.NOT_INITIATED || UploadStatus.FAILURE:
        _viewModel.pickDocument(doc);
      case UploadStatus.SELECTED:
        _viewModel.deselectDocument(doc);
      default:
        break;
    }
  }
}
