class Account {
  final String accountId;
  final String accountName;
  final String accountType;

  const Account({
    required this.accountId,
    required this.accountName,
    required this.accountType,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      accountId: json['accountId'] as String? ?? '',
      accountName: json['accountName'] as String? ?? '',
      accountType: json['accountType'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'accountName': accountName,
      'accountType': accountType,
    };
  }
}
