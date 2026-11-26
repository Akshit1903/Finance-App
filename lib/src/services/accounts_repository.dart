import 'dart:convert';

import 'package:expense_and_net_worth_automation/src/clients/home_server_client.dart';
import 'package:expense_and_net_worth_automation/src/models/account.dart';
import 'package:expense_and_net_worth_automation/src/services/prefs_service.dart';

class AccountsRepository {
  final PrefsService _prefsService;
  final HomeServerClient _homeServerClient;

  List<Account> _cachedAccounts = [];

  AccountsRepository(this._prefsService, this._homeServerClient) {
    _cachedAccounts = loadFromPrefs();
  }

  List<Account> get accounts => _cachedAccounts;

  List<Account> loadFromPrefs() {
    final jsonStr = _prefsService.getAccounts();
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((item) => Account.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveToPrefs(List<Account> accounts) async {
    final list = accounts.map((a) => a.toJson()).toList();
    await _prefsService.setAccounts(jsonEncode(list));
    _cachedAccounts = accounts;
  }

  Future<List<Account>> fetchAndSaveAccounts() async {
    final accounts = await _homeServerClient.getAccounts();
    await saveToPrefs(accounts);
    return accounts;
  }

  String getAccountName(String accountId) {
    try {
      final account = _cachedAccounts.firstWhere((a) => a.accountId == accountId);
      return account.accountName;
    } catch (_) {
      return accountId;
    }
  }
}
