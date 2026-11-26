/// A group of metrics within a finance log period (e.g., "[M] Net Worth").
class FinanceLogGroup {
  final String name;
  final Map<String, String> metrics;

  const FinanceLogGroup({required this.name, required this.metrics});

  /// Returns metrics sorted by numeric value descending.
  /// Non-numeric values sort to the bottom.
  List<MapEntry<String, String>> get sortedMetrics {
    final entries = metrics.entries.toList();
    entries.sort((a, b) {
      final aVal = double.tryParse(a.value);
      final bVal = double.tryParse(b.value);
      if (aVal != null && bVal != null) return bVal.compareTo(aVal);
      if (aVal == null && bVal != null) return 1;
      if (aVal != null && bVal == null) return -1;
      return a.key.compareTo(b.key);
    });
    return entries;
  }
}

Map<String, dynamic> _safeLogMap(dynamic val) {
  if (val is Map) {
    return val.map((k, v) => MapEntry(k.toString(), v));
  }
  return <String, dynamic>{};
}

/// Finance log with period-based categories.
class FinanceLog {
  final List<FinanceLogGroup> month;
  final List<FinanceLogGroup> quarter;
  final List<FinanceLogGroup> year;

  const FinanceLog({
    required this.month,
    required this.quarter,
    required this.year,
  });

  factory FinanceLog.fromJson(dynamic json) {
    final map = _safeLogMap(json);
    return FinanceLog(
      month: _parseGroups(map['month']),
      quarter: _parseGroups(map['quarter']),
      year: _parseGroups(map['year']),
    );
  }

  static List<FinanceLogGroup> _parseGroups(dynamic periodJson) {
    final map = _safeLogMap(periodJson);
    return map.entries.map((entry) {
      final metricsRaw = _safeLogMap(entry.value);
      return FinanceLogGroup(
        name: entry.key,
        metrics: metricsRaw.map((k, v) => MapEntry(k, v.toString())),
      );
    }).toList();
  }

  /// Whether all periods are empty.
  bool get isEmpty => month.isEmpty && quarter.isEmpty && year.isEmpty;
}
