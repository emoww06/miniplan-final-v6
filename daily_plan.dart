import 'goal.dart';

class DailyPlan {
  final String id;
  final DateTime date;
  final List<Goal> goals;
  final String? aiFeedback;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  DailyPlan({
    required this.id,
    required this.date,
    required this.goals,
    this.aiFeedback,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'goals': goals.map((goal) => goal.toMap()).toList(),
      'aiFeedback': aiFeedback,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory DailyPlan.fromMap(Map<String, dynamic> map) {
    return DailyPlan(
      id: map['id'],
      date: DateTime.parse(map['date']),
      goals: (map['goals'] as List)
          .map((goalMap) => Goal.fromMap(goalMap))
          .toList(),
      aiFeedback: map['aiFeedback'],
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null 
          ? DateTime.parse(map['completedAt']) 
          : null,
    );
  }

  DailyPlan copyWith({
    String? id,
    DateTime? date,
    List<Goal>? goals,
    String? aiFeedback,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return DailyPlan(
      id: id ?? this.id,
      date: date ?? this.date,
      goals: goals ?? this.goals,
      aiFeedback: aiFeedback ?? this.aiFeedback,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  int get completedGoalsCount => goals.where((goal) => goal.isCompleted).length;
  int get totalGoalsCount => goals.length;
  double get completionRate => totalGoalsCount > 0 ? completedGoalsCount / totalGoalsCount : 0.0;
} 