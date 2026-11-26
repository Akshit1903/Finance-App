import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  final SharedPreferences _prefs;
  PrefsService(this._prefs);

  static const String _externalTransactionsKey = 'external_transactions';
  static const String _workingEANWSheetsIdKey = 'working_eanw_sheets_id';
  static const String _accountsKey = 'accounts';

  String? getAccounts() {
    return _prefs.getString(_accountsKey);
  }

  Future<void> setAccounts(String jsonStr) async {
    await _prefs.setString(_accountsKey, jsonStr);
  }

  String? getExternalTransactions() {
    return _prefs.getString(_externalTransactionsKey);
  }

  Future<void> setExternalTransactions(String value) async {
    await _prefs.setString(_externalTransactionsKey, value);
  }

  Future<void> removeExternalTransactions() async {
    await _prefs.remove(_externalTransactionsKey);
  }

  String? getWorkingEANWSheetsId() {
    return _prefs.getString(_workingEANWSheetsIdKey);
  }

  Future<void> setWorkingEANWSheetsId(String value) async {
    await _prefs.setString(_workingEANWSheetsIdKey, value);
  }

  Future<void> removeWorkingEANWSheetsId() async {
    await _prefs.remove(_workingEANWSheetsIdKey);
  }
}
