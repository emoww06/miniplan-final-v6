import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal.dart';
import '../models/daily_plan.dart';
import '../services/ai_service.dart';

class GoalsProvider with ChangeNotifier {
  DailyPlan? _currentPlan;
  List<DailyPlan> _pastPlans = [];
  bool _isLoading = false;

  DailyPlan? get currentPlan => _currentPlan;
  List<DailyPlan> get pastPlans => _pastPlans;
  bool get isLoading => _isLoading;

  Future<void> createDailyPlan(List<Goal> goals) async {
    _isLoading = true;
    notifyListeners();

    try {
      final today = DateTime.now();
      final planId = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final dailyPlan = DailyPlan(
        id: planId,
        date: today,
        goals: goals,
        createdAt: today,
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('daily_plans')
          .doc(planId)
          .set(dailyPlan.toMap());

      _currentPlan = dailyPlan;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadTodayPlan() async {
    _isLoading = true;
    notifyListeners();

    try {
      final today = DateTime.now();
      final planId = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final doc = await FirebaseFirestore.instance
          .collection('daily_plans')
          .doc(planId)
          .get();

      if (doc.exists) {
        _currentPlan = DailyPlan.fromMap(doc.data()!);
      } else {
        _currentPlan = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleGoalCompletion(String goalId) async {
    if (_currentPlan == null) return;

    try {
      final updatedGoals = _currentPlan!.goals.map((goal) {
        if (goal.id == goalId) {
          return goal.copyWith(
            isCompleted: !goal.isCompleted,
            completedAt: !goal.isCompleted ? DateTime.now() : null,
          );
        }
        return goal;
      }).toList();

      final updatedPlan = _currentPlan!.copyWith(goals: updatedGoals);

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('daily_plans')
          .doc(_currentPlan!.id)
          .update(updatedPlan.toMap());

      _currentPlan = updatedPlan;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> completeDay() async {
    if (_currentPlan == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Generate AI feedback
      final aiFeedback = await AIService.generateFeedback(_currentPlan!);

      final completedPlan = _currentPlan!.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        aiFeedback: aiFeedback,
      );

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('daily_plans')
          .doc(_currentPlan!.id)
          .update(completedPlan.toMap());

      _currentPlan = completedPlan;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadPastPlans() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('daily_plans')
          .where('isCompleted', isEqualTo: true)
          .orderBy('date', descending: true)
          .limit(30)
          .get();

      _pastPlans = querySnapshot.docs
          .map((doc) => DailyPlan.fromMap(doc.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void clearCurrentPlan() {
    _currentPlan = null;
    notifyListeners();
  }
} 