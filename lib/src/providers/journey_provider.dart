import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:expense_and_net_worth_automation/src/clients/home_server_client.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/models/document_upload.dart';
import 'package:expense_and_net_worth_automation/src/models/eanw_details.dart';
import 'package:expense_and_net_worth_automation/src/models/journey.dart';
import 'package:expense_and_net_worth_automation/src/services/accounts_repository.dart';
import 'package:expense_and_net_worth_automation/src/services/auth_service.dart';
import 'package:flutter/material.dart';

/// Central state management for the finance journey.
class JourneyProvider extends ChangeNotifier {
  final HomeServerClient _homeServerClient = getIt<HomeServerClient>();
  final AuthService _authService = getIt<AuthService>();
  final AccountsRepository _accountsRepository = getIt<AccountsRepository>();

  final List<JourneyStep> _steps = [
    JourneyStep(
      id: 'document_upload',
      title: 'Document Upload',
      stepStatus: StepStatus.pending,
    ),
    JourneyStep(
      id: 'eanw_script',
      title: 'EANW Automation',
      stepStatus: StepStatus.pending,
    ),
  ];

  bool _isEvaluating = false;
  bool _isTabBarVisible = true;
  bool _isJourneyComplete = false;
  String? _error;
  PageController? _pageController;

  DocumentUploadResponse? _documentStatus;
  CompletionEanwResponse? _completionData;

  late final ConfettiController confettiController;
  StreamSubscription? _authSub;

  JourneyProvider() {
    confettiController =
        ConfettiController(duration: const Duration(seconds: 4));

    _authSub = _authService.onUserChanged.listen((account) {
      if (account != null) {
        initStartup();
      } else {
        _reset();
      }
    });

    _authService.isSignedIn().then((signedIn) {
      if (signedIn) {
        initStartup();
      }
    });
  }

  List<JourneyStep> get steps => _steps;
  bool get isEvaluating => _isEvaluating;
  bool get isLoading => _isEvaluating;
  bool get isTabBarVisible => _isTabBarVisible;
  bool get isJourneyComplete => _isJourneyComplete;
  String? get error => _error;
  DocumentUploadResponse? get documentStatus => _documentStatus;
  CompletionEanwResponse? get completionData => _completionData;

  Journey? get journey => Journey(steps: _steps, complete: _isJourneyComplete);

  JourneyStep? get inProgressStep {
    try {
      return _steps.firstWhere((s) => s.stepStatus == StepStatus.inProgress);
    } catch (_) {
      return null;
    }
  }

  void attachPageController(PageController controller) {
    _pageController = controller;
  }

  void detachPageController() {
    _pageController = null;
  }

  void _reset() {
    _steps[0].stepStatus = StepStatus.pending;
    _steps[0].isEvaluating = false;
    _steps[1].stepStatus = StepStatus.pending;
    _steps[1].isEvaluating = false;
    _isEvaluating = false;
    _isTabBarVisible = true;
    _isJourneyComplete = false;
    _error = null;
    _documentStatus = null;
    _completionData = null;
    notifyListeners();
  }

  /// Initial app startup: fetches accounts and evaluates journey.
  Future<void> initStartup() async {
    try {
      await _accountsRepository.fetchAndSaveAccounts();
    } catch (_) {
      // Continue even if network error on accounts fetch
    }
    await evaluateJourney();
  }

  /// Legacy trigger for manual refresh.
  Future<void> fetchJourney() async {
    await evaluateJourney();
  }

  /// Full journey evaluation framework with animated transitions.
  Future<void> evaluateJourney() async {
    if (_isEvaluating) return;
    _isEvaluating = true;
    _error = null;

    // 1. Swiftly hide bottom tab bar
    _isTabBarVisible = false;
    notifyListeners();

    // 2. Smoothly animate to page 1 (Journey tab)
    if (_pageController != null && _pageController!.hasClients) {
      await _pageController!.animateToPage(
        1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }

    await Future.delayed(const Duration(milliseconds: 200));

    // 3. Evaluate Step 1: Document Upload
    _steps[0].isEvaluating = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 350));

    bool step1Complete = false;
    try {
      final docRes = await _homeServerClient.getDocuments();
      _documentStatus = docRes;
      step1Complete = docRes.stepCompleted;
    } catch (e) {
      step1Complete = false;
      _error = e.toString();
    }

    if (!step1Complete) {
      // Step 1 is in progress
      _steps[0].stepStatus = StepStatus.inProgress;
      _steps[0].isEvaluating = false;
      _steps[1].stepStatus = StepStatus.pending;
      _steps[1].isEvaluating = false;
      _isEvaluating = false;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 400));

      // Move left to Action tab and restore tab bar
      if (_pageController != null && _pageController!.hasClients) {
        await _pageController!.animateToPage(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
      }
      _isTabBarVisible = true;
      notifyListeners();
      return;
    }

    // Step 1 completed!
    _steps[0].stepStatus = StepStatus.completed;
    _steps[0].isEvaluating = false;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 350));

    // 4. Evaluate Step 2: EANW Automation
    _steps[1].isEvaluating = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 350));

    bool step2Complete = false;
    try {
      final completionRes = await _homeServerClient.getCompletionEanw();
      _completionData = completionRes;
      step2Complete = completionRes.stepCompleted;
    } catch (_) {
      step2Complete = false;
    }

    if (step2Complete) {
      // Entire journey complete!
      _steps[1].stepStatus = StepStatus.completed;
      _steps[1].isEvaluating = false;
      _isJourneyComplete = true;
      _isEvaluating = false;
      _isTabBarVisible = true;
      notifyListeners();

      confettiController.play();
      return;
    }

    // Step 2 in progress
    _steps[1].stepStatus = StepStatus.inProgress;
    _steps[1].isEvaluating = false;
    _isEvaluating = false;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));

    // Move left to Action tab and restore tab bar
    if (_pageController != null && _pageController!.hasClients) {
      await _pageController!.animateToPage(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
    _isTabBarVisible = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    confettiController.dispose();
    super.dispose();
  }
}
