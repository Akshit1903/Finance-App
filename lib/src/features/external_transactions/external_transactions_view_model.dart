import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/features/external_transactions/external_transaction_repository.dart';
import 'package:expense_and_net_worth_automation/src/models/transaction.dart';
import 'package:flutter/material.dart';

class ExternalTransactionsViewModel extends ChangeNotifier {
  final ExternalTransactionRepository _repository =
      getIt<ExternalTransactionRepository>();

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadTransactions() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = _repository.loadFromPrefs();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    _transactions.add(transaction);
    await _repository.saveToPrefs(_transactions);
    notifyListeners();
  }

  Future<void> updateTransaction(int index, Transaction transaction) async {
    if (index >= 0 && index < _transactions.length) {
      _transactions[index] = transaction;
      await _repository.saveToPrefs(_transactions);
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(int index) async {
    if (index >= 0 && index < _transactions.length) {
      _transactions.removeAt(index);
      await _repository.saveToPrefs(_transactions);
      notifyListeners();
    }
  }

  Future<void> refreshFromApi() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _repository.fetchFromApi();
      _transactions = fetched;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Color getTransactionColor(Transaction tx) {
    if (tx.expense) {
      return Colors.red;
    } else if (tx.income) {
      return Colors.green;
    } else {
      return tx.drcr == 'CR' ? Colors.green : Colors.red;
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
