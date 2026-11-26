import 'package:expense_and_net_worth_automation/src/models/finance_log.dart';
import 'package:expense_and_net_worth_automation/src/utils/transform_utils.dart';

Map<String, dynamic> _safeMap(dynamic val) {
  if (val is Map) {
    return val.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

/// A single financial section (e.g., income, recurring_expenses).
/// Contains a total and a split of named categories.
class EanwSection {
  final String total;
  final Map<String, String> split;

  const EanwSection({required this.total, required this.split});

  factory EanwSection.fromJson(dynamic json) {
    final map = _safeMap(json);
    final splitMap = _safeMap(map['split']);
    final sortedMap = Map.fromEntries(splitMap.entries.toList()
      ..sort((a, b) {
        final aVal = double.tryParse(a.value.toString().replaceAll(',', '')) ?? 0.0;
        final bVal = double.tryParse(b.value.toString().replaceAll(',', '')) ?? 0.0;
        return bVal.compareTo(aVal);
      }));
    return EanwSection(
      total: TransformUtils.formatMoneyString(map['total']?.toString() ?? '0',
          decimalDigits: 0),
      split: sortedMap.map((k, v) => MapEntry(
          k, TransformUtils.formatMoneyString(v.toString(), decimalDigits: 0))),
    );
  }
}

/// Full EANW financial details (working or main sheet).
class EanwDetails {
  final EanwSection recurringExpenses;
  final EanwSection oneTimeExpenses;
  final String totalExpenses;
  final EanwSection investment;
  final EanwSection income;
  final String growth;
  final EanwSection netWorth;

  const EanwDetails({
    required this.income,
    required this.recurringExpenses,
    required this.netWorth,
    required this.oneTimeExpenses,
    required this.investment,
    required this.growth,
    required this.totalExpenses,
  });

  factory EanwDetails.fromJson(dynamic json) {
    final map = _safeMap(json);
    return EanwDetails(
      income: EanwSection.fromJson(map['income']),
      recurringExpenses: EanwSection.fromJson(map['recurring_expenses']),
      netWorth: EanwSection.fromJson(map['net_worth']),
      oneTimeExpenses: EanwSection.fromJson(map['one_time_expenses']),
      investment: EanwSection.fromJson(map['investment']),
      growth: TransformUtils.formatMoneyString(
          map['growth']?.toString() ?? '0',
          decimalDigits: 0),
      totalExpenses: TransformUtils.formatMoneyString(
          map['total_expenses']?.toString() ?? '0',
          decimalDigits: 0),
    );
  }

  /// All sections as a list of (label, section) pairs for iteration.
  List<MapEntry<String, EanwSection>> get allSections => [
        MapEntry('Recurring Expenses', recurringExpenses),
        MapEntry('One-Time Expenses', oneTimeExpenses),
        MapEntry('Investment', investment),
        MapEntry('Income', income),
        MapEntry('Net Worth', netWorth),
      ];
}

/// Response from GET finance/scripts/eanw/working
class WorkingEanwResponse {
  final String? workingEANWSheetsId;
  final EanwDetails? workingEANWSheet;

  const WorkingEanwResponse({
    this.workingEANWSheetsId,
    this.workingEANWSheet,
  });

  factory WorkingEanwResponse.fromJson(dynamic json) {
    final map = _safeMap(json);
    return WorkingEanwResponse(
      workingEANWSheetsId: map['workingEANWSheetsId'] as String?,
      workingEANWSheet: map['workingEANWSheet'] != null
          ? EanwDetails.fromJson(map['workingEANWSheet'])
          : null,
    );
  }

  bool get hasWorkingSheet =>
      workingEANWSheetsId != null && workingEANWSheetsId!.isNotEmpty;
}

/// Response from GET finance/scripts/eanw/completion
class CompletionEanwResponse {
  final bool stepCompleted;
  final EanwDetails? mainEANWSheet;
  final FinanceLog? financeLog;

  const CompletionEanwResponse({
    required this.stepCompleted,
    this.mainEANWSheet,
    this.financeLog,
  });

  factory CompletionEanwResponse.fromJson(dynamic json) {
    final map = _safeMap(json);
    return CompletionEanwResponse(
      stepCompleted: map['stepCompleted'] as bool? ?? false,
      mainEANWSheet: map['mainEANWSheet'] != null
          ? EanwDetails.fromJson(map['mainEANWSheet'])
          : null,
      financeLog: map['financeLog'] != null
          ? FinanceLog.fromJson(map['financeLog'])
          : null,
    );
  }
}
