import 'dart:convert';

import 'package:expense_and_net_worth_automation/src/clients/home_server_client.dart';
import 'package:expense_and_net_worth_automation/src/models/transaction.dart';
import 'package:expense_and_net_worth_automation/src/services/prefs_service.dart';

class ExternalTransactionRepository {
  final PrefsService _prefsService;
  final HomeServerClient _homeServerClient;

  ExternalTransactionRepository(this._prefsService, this._homeServerClient);

  List<Transaction> loadFromPrefs() {
    final String? jsonStr = _prefsService.getExternalTransactions();
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveToPrefs(List<Transaction> transactions) async {
    final List<Map<String, dynamic>> list =
        transactions.map((t) => t.toJson()).toList();
    final String jsonStr = jsonEncode(list);
    await _prefsService.setExternalTransactions(jsonStr);
  }

  Future<List<Transaction>> fetchFromApi() async {
    final fetched = await _homeServerClient.getExternalTransactions();
    await saveToPrefs(fetched);
    return fetched;
  }

  Future<void> initializeIfEmpty() async {
    final List<Transaction> existing = loadFromPrefs();
    if (existing.isEmpty) {
      try {
        await fetchFromApi();
      } catch (e) {
        // Don't crash app startup on network failure
      }
    }
  }

  Future<void> clear() async {
    await _prefsService.removeExternalTransactions();
  }
}
