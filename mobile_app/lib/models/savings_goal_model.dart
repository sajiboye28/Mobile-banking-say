import 'package:pocketbase/pocketbase.dart';

class SavingsGoalModel {
  final String goalId;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String icon;
  final String color;
  final DateTime? deadline;
  final bool isCompleted;
  final DateTime? createdAt;

  SavingsGoalModel({
    required this.goalId,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.icon,
    required this.color,
    this.deadline,
    this.isCompleted = false,
    this.createdAt,
  });

  factory SavingsGoalModel.fromRecord(RecordModel record) {
    final data = record.data;

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return SavingsGoalModel(
      goalId: record.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      targetAmount: (data['targetAmount'] ?? 0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0).toDouble(),
      icon: data['icon'] as String? ?? 'savings',
      color: data['color'] as String? ?? '1A237E',
      deadline: parseDate(data['deadline']),
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: parseDate(data['createdAt']) ?? parseDate(record.created),
    );
  }

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remaining => (targetAmount - currentAmount).clamp(0.0, double.infinity);
  int get progressPercent => (progress * 100).round();
  DateTime? get deadlineDate => deadline;
}
