import 'dart:convert';

import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/models/account.dart';
import 'package:expense_and_net_worth_automation/src/models/document_upload.dart';
import 'package:expense_and_net_worth_automation/src/models/eanw_details.dart';
import 'package:expense_and_net_worth_automation/src/models/transaction.dart';
import 'package:expense_and_net_worth_automation/src/models/validation.dart';
import 'package:expense_and_net_worth_automation/src/services/auth_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/snackbar_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class HomeServerClient {
  final AuthService _authService;
  final String _host;

  HomeServerClient()
      : _host = dotenv.get('HOME_SERVER_HOST'),
        _authService = getIt<AuthService>();

  /// Helper to parse response body and extract error message if formatted as:
  /// { "errorCode": "...", "message": "...", "context": { "message": "..." } }
  void _validateResponse(http.Response response, {int expectedStatusCode = 200}) {
    validateResponse(response, expectedStatusCode: expectedStatusCode);
  }

  @visibleForTesting
  static void validateResponse(http.Response response, {int expectedStatusCode = 200}) {
    if (response.statusCode != expectedStatusCode &&
        !(expectedStatusCode == 200 && response.statusCode == 204)) {
      String errorMessage = response.reasonPhrase ?? 'Request failed';
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          final rawMain = body['message']?.toString().trim();
          final mainMessage =
              (rawMain != null && rawMain.isNotEmpty) ? rawMain : null;

          String? contextMessage;
          final contextData = body['context'];
          if (contextData is Map && contextData['message'] != null) {
            final rawCtx = contextData['message'].toString().trim();
            if (rawCtx.isNotEmpty) {
              contextMessage = rawCtx;
            }
          }

          if (mainMessage != null && contextMessage != null) {
            if (mainMessage != contextMessage) {
              errorMessage = '$mainMessage: $contextMessage';
            } else {
              errorMessage = mainMessage;
            }
          } else if (mainMessage != null) {
            errorMessage = mainMessage;
          } else if (contextMessage != null) {
            errorMessage = contextMessage;
          }
        }
      } catch (_) {
        // Fall back to default error message or response body
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }
      throw Exception('HTTP ${response.statusCode} - $errorMessage');
    }
  }

  /// Executes an API action and triggers a SnackBar if any error occurs.
  Future<T> _execute<T>(String method, String endpoint, Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      final errorDetail =
          e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
      final message = 'API Error [$method $endpoint]: $errorDetail';
      SnackbarService.showSnackBar(message);
      rethrow;
    }
  }

  /// GET finance/documents
  Future<DocumentUploadResponse> getDocuments() async {
    return _execute('GET', '/finance/documents', () async {
      final uri = _getUri('/finance/documents');
      final headers = await _getRequestHeaders();
      final response = await http.get(uri, headers: headers);
      _validateResponse(response);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return DocumentUploadResponse.fromJson(json);
    });
  }

  /// GET finance/accounts
  Future<List<Account>> getAccounts() async {
    return _execute('GET', '/finance/accounts', () async {
      final uri = _getUri('/finance/accounts');
      final headers = await _getRequestHeaders();
      final response = await http.get(uri, headers: headers);
      _validateResponse(response);
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((item) => Account.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  /// GET finance/scripts/eanw/working
  Future<WorkingEanwResponse> getWorkingEanw() async {
    return _execute('GET', '/finance/scripts/eanw/working', () async {
      final uri = _getUri('/finance/scripts/eanw/working');
      final headers = await _getRequestHeaders();
      final response = await http.get(uri, headers: headers);
      _validateResponse(response);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return WorkingEanwResponse.fromJson(json);
    });
  }

  /// POST finance/scripts/eanw/creations (multipart upload with CSV file)
  Future<void> createEanw(String csvFilePath) async {
    return _execute('POST', '/finance/scripts/eanw/creations', () async {
      final uri = _getUri('/finance/scripts/eanw/creations');
      final request = http.MultipartRequest('POST', uri);

      final accessToken = await _authService.getAccessToken();
      final idToken = await _authService.getIDToken();
      request.headers['Authorization'] = 'Bearer $idToken';
      request.headers['X-ACCESS-TOKEN'] = accessToken;

      request.files.add(await http.MultipartFile.fromPath('file', csvFilePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      _validateResponse(response, expectedStatusCode: 200);
    });
  }

  /// PATCH finance/scripts/eanw/evaluations
  Future<void> evaluateEanw(List<Transaction> externalTransactions) async {
    return _execute('PATCH', '/finance/scripts/eanw/evaluations', () async {
      final uri = _getUri('/finance/scripts/eanw/evaluations');
      final headers = await _getRequestHeaders();
      final body = jsonEncode({
        'externalTransactions':
            externalTransactions.map((t) => t.toJson()).toList(),
      });
      final response = await http.patch(uri, headers: headers, body: body);
      _validateResponse(response, expectedStatusCode: 200);
    });
  }

  /// GET finance/external-transactions
  Future<List<Transaction>> getExternalTransactions() async {
    return _execute('GET', '/finance/external-transactions', () async {
      final uri = _getUri('/finance/external-transactions');
      final headers = await _getRequestHeaders();
      final response = await http.get(uri, headers: headers);
      _validateResponse(response);
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((item) => Transaction.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  /// DELETE finance/scripts/eanw/working
  Future<void> deleteWorkingEanw() async {
    return _execute('DELETE', '/finance/scripts/eanw/working', () async {
      final uri = _getUri('/finance/scripts/eanw/working');
      final headers = await _getRequestHeaders();
      final response = await http.delete(uri, headers: headers);
      _validateResponse(response, expectedStatusCode: 204);
    });
  }

  /// GET finance/validations
  Future<List<Validation>> getValidations() async {
    return _execute('GET', '/finance/validations', () async {
      final uri = _getUri('/finance/validations');
      final headers = await _getRequestHeaders();
      final response = await http.get(uri, headers: headers);
      _validateResponse(response);
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((item) => Validation.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  /// POST finance/scripts/eanw/commits
  Future<void> commitEanw() async {
    return _execute('POST', '/finance/scripts/eanw/commits', () async {
      final uri = _getUri('/finance/scripts/eanw/commits');
      final headers = await _getRequestHeaders();
      final response = await http.post(uri, headers: headers);
      _validateResponse(response, expectedStatusCode: 200);
    });
  }

  /// GET finance/scripts/eanw/completion
  Future<CompletionEanwResponse> getCompletionEanw() async {
    return _execute('GET', '/finance/scripts/eanw/completion', () async {
      final uri = _getUri('/finance/scripts/eanw/completion');
      final headers = await _getRequestHeaders();
      final response = await http.get(uri, headers: headers);
      _validateResponse(response);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return CompletionEanwResponse.fromJson(json);
    });
  }

  Uri _getUri(String endpoint) {
    return Uri.https(_host, endpoint);
  }

  Future<Map<String, String>> _getRequestHeaders() async {
    final accessToken = await _authService.getAccessToken();
    final idToken = await _authService.getIDToken();
    return {
      'Authorization': 'Bearer $idToken',
      'X-ACCESS-TOKEN': accessToken,
      'Content-Type': 'application/json',
    };
  }
}
