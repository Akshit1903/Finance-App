import 'package:expense_and_net_worth_automation/src/utils/constants.dart';
import 'package:flutter/material.dart';

/// Centralized snackbar display and history tracking.
///
/// Separates UI notification concerns from business logic utilities.
/// History is capped at [AppConstants.maxSnackbarHistorySize] entries
/// to prevent unbounded memory growth (SEC-7).
class SnackbarService {
  SnackbarService._(); 

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static final ValueNotifier<List<String>> snackbarHistory =
      ValueNotifier<List<String>>([]);

  /// Shows a snackbar message and records it in history.
  /// If [context] is provided and mounted, uses it;
  /// otherwise falls back to [scaffoldMessengerKey] so snackbars
  /// can be displayed from anywhere (e.g. API clients, background services).
  static void showSnackBar(String message, [BuildContext? context]) {
    _addToHistory(message);

    ScaffoldMessengerState? messenger;
    if (context != null && context.mounted) {
      messenger = ScaffoldMessenger.of(context);
    } else {
      try {
        messenger = scaffoldMessengerKey.currentState;
      } catch (_) {
        // Safe fallback when Flutter bindings are not initialized (e.g. headless unit tests)
        messenger = null;
      }
    }

    if (messenger != null) {
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  static void _addToHistory(String message) {
    final history = List<String>.from(snackbarHistory.value);
    history.add(message);

    if (history.length > AppConstants.maxSnackbarHistorySize) {
      history.removeRange(
          0, history.length - AppConstants.maxSnackbarHistorySize);
    }

    snackbarHistory.value = history;
  }
}
