class MonthlySearchCount {
  final int month;
  final String monthLabel;
  final int searches;

  const MonthlySearchCount({
    required this.month,
    required this.monthLabel,
    required this.searches,
  });

  factory MonthlySearchCount.fromJson(Map<String, dynamic> json) {
    return MonthlySearchCount(
      month: json['month'] as int,
      monthLabel: json['monthLabel'] as String,
      searches: json['searches'] as int,
    );
  }
}
