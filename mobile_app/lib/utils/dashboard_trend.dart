class DashboardTrendBucket {
  const DashboardTrendBucket({
    required this.date,
    required this.total,
    required this.labelDate,
    this.drilldown = const [],
  });

  final String date;
  final double total;
  final String labelDate;
  final List<DashboardTrendBucket> drilldown;

  bool get canExpand => drilldown.length > 1;

  factory DashboardTrendBucket.fromJson(Map<String, dynamic> json) {
    final nested = (json['drilldown'] as List? ?? const [])
        .map(
          (entry) => DashboardTrendBucket.fromJson(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList();

    final date = json['date']?.toString() ?? '';
    return DashboardTrendBucket(
      date: date,
      labelDate: json['label_date']?.toString() ?? date,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      drilldown: nested,
    );
  }

  static List<DashboardTrendBucket> fromList(dynamic rawTrend) {
    final source = rawTrend as List? ?? const [];
    return source
        .map(
          (entry) => DashboardTrendBucket.fromJson(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList();
  }
}

bool supportsTrendDrilldown(String? drilldownPeriod) {
  return drilldownPeriod != null && drilldownPeriod.trim().isNotEmpty;
}
