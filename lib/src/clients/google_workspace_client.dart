import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/services/auth_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/constants.dart';
import 'package:expense_and_net_worth_automation/src/utils/snackbar_service.dart';
import 'package:http/http.dart' as http;

/// Result type for Google Workspace API calls.
class WorkspaceResult {
  final String? data;
  final String? errorMessage;

  const WorkspaceResult.success(this.data) : errorMessage = null;
  const WorkspaceResult.failure(this.errorMessage) : data = null;

  bool get isSuccess => errorMessage == null;
}

/// Client for Google Workspace APIs (Drive).
class GoogleWorkspaceClient {
  final AuthService _authService;
  GoogleWorkspaceClient() : _authService = getIt<AuthService>();

  /// Helper to determine MIME type from file extension.
  static String lookupMimeType(String fileName, [String? path]) {
    final target = (path != null && path.contains('.')) ? path : fileName;
    final ext = target.contains('.')
        ? target.substring(target.lastIndexOf('.')).toLowerCase()
        : '';
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.webp':
        return 'image/webp';
      case '.csv':
        return 'text/csv';
      default:
        return 'application/octet-stream';
    }
  }

  /// Uploads a document to Google Drive using RFC 2387 multipart/related.
  Future<WorkspaceResult> uploadDocumentToDrive({
    required String path,
    required String fileName,
    required String folderId,
  }) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        final errorMsg = 'File not found at path: $path';
        SnackbarService.showSnackBar('Drive Upload Error: $errorMsg');
        return WorkspaceResult.failure(errorMsg);
      }

      final fileBytes = await file.readAsBytes();
      final mimeType = lookupMimeType(fileName, path);
      final boundary = 'boundary_${DateTime.now().millisecondsSinceEpoch}';

      final uri = Uri.parse(AppConstants.uploadDocumentToDriveUri);

      final metadataJson = jsonEncode({
        'name': fileName,
        'parents': [folderId],
      });

      // Construct multipart/related payload:
      // Part 1: Metadata (application/json; charset=UTF-8)
      // Part 2: Media (actual file MIME type and binary bytes)
      final prefix = utf8.encode(
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '$metadataJson\r\n'
        '--$boundary\r\n'
        'Content-Type: $mimeType\r\n\r\n',
      );
      final postfix = utf8.encode('\r\n--$boundary--\r\n');

      final bodyBytes =
          Uint8List(prefix.length + fileBytes.length + postfix.length);
      bodyBytes.setRange(0, prefix.length, prefix);
      bodyBytes.setRange(
          prefix.length, prefix.length + fileBytes.length, fileBytes);
      bodyBytes.setRange(
          prefix.length + fileBytes.length, bodyBytes.length, postfix);

      final token = await _authService.getAccessToken();
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/related; boundary=$boundary',
        'Content-Length': bodyBytes.length.toString(),
      };

      final response = await http.post(uri, headers: headers, body: bodyBytes);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return WorkspaceResult.success(jsonResponse['id']);
      } else {
        final errorMsg =
            'Drive Upload Error [HTTP ${response.statusCode}]: ${response.body}';
        SnackbarService.showSnackBar(errorMsg);
        return WorkspaceResult.failure(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Drive Upload Exception: $e';
      SnackbarService.showSnackBar(errorMsg);
      return WorkspaceResult.failure(errorMsg);
    }
  }
}
