import 'package:expense_and_net_worth_automation/src/clients/google_workspace_client.dart';
import 'package:expense_and_net_worth_automation/src/clients/home_server_client.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/models/document_upload.dart';
import 'package:expense_and_net_worth_automation/src/providers/journey_provider.dart';
import 'package:expense_and_net_worth_automation/src/utils/pdf_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/snackbar_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/upload_status.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// ViewModel for Document Upload step.
/// Fetches statuses from GET finance/documents.
class DocumentUploadViewModel extends ChangeNotifier {
  final JourneyProvider _journeyProvider;
  final HomeServerClient _homeServerClient = getIt<HomeServerClient>();
  final GoogleWorkspaceClient _workspaceClient = getIt<GoogleWorkspaceClient>();

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  List<UploadDocument> documents = [];
  bool isLoadingDocuments = false;
  final List<String> errors = [];

  DocumentUploadViewModel({
    required JourneyProvider journeyProvider,
  }) : _journeyProvider = journeyProvider {
    fetchDocuments();
  }

  Future<void> fetchDocuments() async {
    isLoadingDocuments = true;
    notifyListeners();

    try {
      final response = await _homeServerClient.getDocuments();
      if (_isDisposed) return;
      documents = response.documents;
    } catch (e) {
      if (_isDisposed) return;
      errors.add('Failed to load documents: $e');
    } finally {
      if (!_isDisposed) {
        isLoadingDocuments = false;
        notifyListeners();
      }
    }
  }

  bool isAlreadyUploaded(UploadDocument doc) => doc.isUploaded;

  bool get isLoading =>
      isLoadingDocuments ||
      documents.any((d) =>
          d.uploadStatus == UploadStatus.QUEUED ||
          d.uploadStatus == UploadStatus.DECRYPTING ||
          d.uploadStatus == UploadStatus.RESOLVE_FOLDER_ID ||
          d.uploadStatus == UploadStatus.UPLOADING);

  bool get hasSelectedDocuments =>
      documents.any((d) => d.uploadStatus == UploadStatus.SELECTED);

  Future<void> pickDocument(UploadDocument doc) async {
    if (!doc.isPending) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (_isDisposed || result == null || result.files.isEmpty) return;

    final pickedPath = result.files.single.path;
    if (pickedPath != null) {
      doc.path = pickedPath;
      doc.uploadStatus = UploadStatus.SELECTED;
      notifyListeners();
    }
  }

  void deselectDocument(UploadDocument doc) {
    doc.reset();
    notifyListeners();
  }

  /// Uploads all selected documents in parallel to Google Drive.
  Future<void> uploadAllDocuments() async {
    errors.clear();

    for (final doc in documents) {
      if (doc.uploadStatus == UploadStatus.SELECTED) {
        doc.uploadStatus = UploadStatus.QUEUED;
      }
    }
    notifyListeners();

    final futures = documents
        .where((d) => d.uploadStatus == UploadStatus.QUEUED)
        .map((d) => _uploadSingleDocument(d))
        .toList();

    await Future.wait(futures);

    // Evaluate the journey after uploads complete
    await _journeyProvider.evaluateJourney();
    if (_isDisposed) return;
    notifyListeners();
  }

  Future<void> _uploadSingleDocument(UploadDocument doc) async {
    try {
      // Step 1: Decryption if needed
      doc.uploadStatus = UploadStatus.DECRYPTING;
      notifyListeners();
      await _handleDecryption(doc);
      if (_isDisposed) return;

      // Step 2: Drive folder resolution
      doc.uploadStatus = UploadStatus.RESOLVE_FOLDER_ID;
      notifyListeners();
      final folderId = doc.driveFolderId;
      if (folderId == null || folderId.isEmpty) {
        final errorMsg = 'Drive Folder ID not provided for ${doc.name}';
        SnackbarService.showSnackBar(errorMsg);
        throw errorMsg;
      }

      // Step 3: Upload to Google Drive
      doc.uploadStatus = UploadStatus.UPLOADING;
      notifyListeners();

      final now = DateTime.now();
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      final ext = (doc.path != null && doc.path!.contains('.'))
          ? doc.path!.substring(doc.path!.lastIndexOf('.')).toLowerCase()
          : '.pdf';
      final fileName =
          '${prevMonth.year}-${prevMonth.month.toString().padLeft(2, '0')}$ext';

      final uploadResult = await _workspaceClient.uploadDocumentToDrive(
        path: doc.path!,
        fileName: fileName,
        folderId: folderId,
      );
      if (_isDisposed) return;

      if (uploadResult.isSuccess && uploadResult.data != null) {
        doc.uploadStatus = UploadStatus.SUCCESS;
      } else {
        throw uploadResult.errorMessage ?? 'Upload failed';
      }
    } catch (e) {
      if (_isDisposed) return;
      doc.uploadStatus = UploadStatus.FAILURE;
      errors.add('${doc.name}: $e');
      SnackbarService.showSnackBar('Upload failed for ${doc.name}: $e');
    }
    notifyListeners();
  }

  Future<void> _handleDecryption(UploadDocument doc) async {
    final path = doc.path;
    if (path == null) return;

    final password = doc.filePassword;

    if (path.toLowerCase().endsWith('.zip')) {
      try {
        doc.path = await PdfService.extractPdfFromZip(path);
      } catch (_) {
        if (password != null && password.isNotEmpty) {
          doc.path = await PdfService.extractPdfFromZip(path, password: password);
        } else {
          rethrow;
        }
      }
    } else if (path.toLowerCase().endsWith('.pdf') &&
        await PdfService.isPdfEncrypted(path)) {
      if (password != null && password.isNotEmpty) {
        doc.path = await PdfService.getDecryptedPdf(path, password);
      } else {
        final errorMsg = 'Password required for encrypted PDF: ${doc.name}';
        SnackbarService.showSnackBar(errorMsg);
        throw errorMsg;
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    PdfService.cleanupTempFiles();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }
}
