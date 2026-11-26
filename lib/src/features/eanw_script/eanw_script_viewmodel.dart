import 'package:expense_and_net_worth_automation/src/clients/home_server_client.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/features/external_transactions/external_transaction_repository.dart';
import 'package:expense_and_net_worth_automation/src/models/eanw_details.dart';
import 'package:expense_and_net_worth_automation/src/models/journey.dart';
import 'package:expense_and_net_worth_automation/src/models/validation.dart';
import 'package:flutter/material.dart';

/// ViewModel for the EANW Script journey step.
class EanwScriptViewModel extends ChangeNotifier {
  final HomeServerClient _homeServerClient = getIt<HomeServerClient>();
  final ExternalTransactionRepository _externalTxnRepository =
      getIt<ExternalTransactionRepository>();

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  WorkingEanwResponse? workingEanwResponse;
  ValidationResponse? validationResponse;

  bool isLoadingWorking = false;
  bool isCreatingEanw = false;
  bool isDeletingWorkingEanw = false;
  bool isEvaluatingEanw = false;
  bool isLoadingValidations = false;
  bool isCommitting = false;

  String? error;
  Future<void>? initFuture;

  EanwScriptViewModel({JourneyStep? step}) {
    initFuture = fetchWorkingEanw();
  }

  bool get hasWorkingSheet =>
      workingEanwResponse?.hasWorkingSheet ?? false;

  bool get allValidationsPassed =>
      validationResponse?.isSuccess ?? false;

  bool get canCommit =>
      allValidationsPassed &&
      !isCommitting &&
      !isEvaluatingEanw &&
      !isLoadingValidations;

  /// Fetches working EANW sheet details.
  Future<void> fetchWorkingEanw() async {
    isLoadingWorking = true;
    error = null;
    notifyListeners();

    try {
      workingEanwResponse = await _homeServerClient.getWorkingEanw();
      if (workingEanwResponse?.hasWorkingSheet == true) {
        // Automatically load validations for the uploaded sheet
        await fetchValidations();
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingWorking = false;
      notifyListeners();
    }
  }

  /// Automatically uploads CSV, evaluates EANW, and fetches validations in series:
  /// 1. Upload (createEanw)
  /// 2. Evaluate (evaluateEanw)
  /// 3. Get validations (fetchValidations)
  Future<void> createEanwFromCsv(String csvFilePath) async {
    isCreatingEanw = true;
    error = null;
    notifyListeners();

    try {
      // 1. Upload CSV to create working EANW sheet
      await _homeServerClient.createEanw(csvFilePath);
      workingEanwResponse = await _homeServerClient.getWorkingEanw();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isCreatingEanw = false;
      notifyListeners();
    }

    try {
      await _externalTxnRepository.fetchFromApi();
    } catch (_) {
      // Fallback to local cache if offline
    }

    // 2. Evaluate & 3. Get validations (in series)
    await evaluateEanw();
  }

  /// Deletes the working EANW sheet.
  Future<void> deleteWorkingEanw() async {
    isDeletingWorkingEanw = true;
    error = null;
    notifyListeners();

    try {
      await _homeServerClient.deleteWorkingEanw();
      validationResponse = null;
      await fetchWorkingEanw();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isDeletingWorkingEanw = false;
      notifyListeners();
    }
  }

  /// Calls PATCH finance/scripts/eanw/evaluations and then fetches validations in series.
  Future<void> evaluateEanw() async {
    isEvaluatingEanw = true;
    error = null;
    notifyListeners();

    try {
      final transactions = _externalTxnRepository.loadFromPrefs();
      await _homeServerClient.evaluateEanw(transactions);
      await fetchValidations();
      workingEanwResponse = await _homeServerClient.getWorkingEanw();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isEvaluatingEanw = false;
      notifyListeners();
    }
  }

  /// Fetches validation items from GET finance/validations.
  Future<void> fetchValidations() async {
    isLoadingValidations = true;
    error = null;
    notifyListeners();

    try {
      final list = await _homeServerClient.getValidations();
      validationResponse = ValidationResponse(validations: list);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingValidations = false;
      notifyListeners();
    }
  }

  /// Commits EANW via POST finance/scripts/eanw/commits.
  Future<void> commitEanw(VoidCallback onComplete) async {
    if (!canCommit) return;

    isCommitting = true;
    error = null;
    notifyListeners();

    try {
      await _homeServerClient.commitEanw();
      await _externalTxnRepository.clear();
      onComplete();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      if (!_isDisposed) {
        isCommitting = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }
}
