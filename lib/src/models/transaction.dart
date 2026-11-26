class Transaction {
  final String name;
  final double amount;
  final String drcr; // "DR" or "CR"
  final String accountId;
  final bool expense;
  final bool income;
  final String? category;
  final String? tags;

  Transaction({
    required this.name,
    required this.amount,
    required this.drcr,
    required this.accountId,
    required this.expense,
    required this.income,
    this.category,
    this.tags,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      drcr: json['drcr'] as String? ?? 'DR',
      accountId: json['accountId'] as String? ?? '',
      expense: json['expense'] as bool? ?? false,
      income: json['income'] as bool? ?? false,
      category: json['category'] as String?,
      tags: json['tags'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'drcr': drcr,
      'accountId': accountId,
      'expense': expense,
      'income': income,
      'category': category,
      'tags': tags,
    };
  }

  Transaction copyWith({
    String? name,
    double? amount,
    String? drcr,
    String? accountId,
    bool? expense,
    bool? income,
    String? category,
    String? tags,
  }) {
    return Transaction(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      drcr: drcr ?? this.drcr,
      accountId: accountId ?? this.accountId,
      expense: expense ?? this.expense,
      income: income ?? this.income,
      category: category ?? this.category,
      tags: tags ?? this.tags,
    );
  }
}
