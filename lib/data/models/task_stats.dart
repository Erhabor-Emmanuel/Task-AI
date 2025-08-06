class TaskStats {
  final int total;
  final int completed;
  final int pending;
  final int overdue;
  final int today;

  TaskStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.today,
  });

  double get completionRate {
    if (total == 0) return 0;
    return completed / total;
  }
}