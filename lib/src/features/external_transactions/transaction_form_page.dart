import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/models/account.dart';
import 'package:expense_and_net_worth_automation/src/models/transaction.dart';
import 'package:expense_and_net_worth_automation/src/services/accounts_repository.dart';
import 'package:expense_and_net_worth_automation/src/utils/snackbar_service.dart';
import 'package:flutter/material.dart';

class TransactionFormPage extends StatefulWidget {
  final Transaction? transaction;
  final int? index;

  const TransactionFormPage({
    super.key,
    this.transaction,
    this.index,
  });

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final AccountsRepository _accountsRepository = getIt<AccountsRepository>();

  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _tagsController;

  String? _selectedAccountId;
  late bool _expense;
  late bool _income;
  late String _drcr;
  late List<Account> _accounts;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _accounts = _accountsRepository.accounts;

    _nameController = TextEditingController(text: tx?.name ?? '');
    _amountController =
        TextEditingController(text: tx != null ? tx.amount.toString() : '');
    _categoryController = TextEditingController(text: tx?.category ?? '');
    _tagsController = TextEditingController(text: tx?.tags ?? '');
    _selectedAccountId = tx?.accountId.isNotEmpty == true
        ? tx!.accountId
        : (_accounts.isNotEmpty ? _accounts.first.accountId : null);
    _expense = tx?.expense ?? true;
    _income = tx?.income ?? false;
    _drcr = tx?.drcr ?? 'DR';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null || _selectedAccountId!.isEmpty) {
      SnackbarService.showSnackBar('Please select an account', context);
      return;
    }

    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final transaction = Transaction(
      name: _nameController.text.trim(),
      amount: amount,
      accountId: _selectedAccountId!,
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      tags: _tagsController.text.trim().isEmpty
          ? null
          : _tagsController.text.trim(),
      expense: _expense,
      income: _income,
      drcr: _drcr,
    );

    Navigator.pop(context, transaction);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _saveForm,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹)',
                          prefixIcon: Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Account Dropdown Menu
                      DropdownButtonFormField<String>(
                        initialValue: _accounts.any((a) => a.accountId == _selectedAccountId)
                            ? _selectedAccountId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Account',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                          border: OutlineInputBorder(),
                        ),
                        items: _accounts.map((account) {
                          return DropdownMenuItem<String>(
                            value: account.accountId,
                            child: Text(account.accountName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedAccountId = val;
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please select an account';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (e.g. #Online)',
                          prefixIcon: Icon(Icons.tag),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _drcr,
                        decoration: const InputDecoration(
                          labelText: 'Type (DR/CR)',
                          prefixIcon: Icon(Icons.swap_vert),
                          border: InputBorder.none,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'DR', child: Text('DR (Debit)')),
                          DropdownMenuItem(
                              value: 'CR', child: Text('CR (Credit)')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _drcr = value;
                              _expense = (value == 'DR');
                              _income = (value == 'CR');
                            });
                          }
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Is Expense?'),
                        value: _expense,
                        onChanged: (bool value) {
                          setState(() {
                            _expense = value;
                          });
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Is Income?'),
                        value: _income,
                        onChanged: (bool value) {
                          setState(() {
                            _income = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saveForm,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Save Changes' : 'Add Transaction'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
