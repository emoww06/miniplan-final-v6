import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/daily_plan.dart';
import '../providers/goals_provider.dart';
import 'feedback_screen.dart';

class GoalTrackingScreen extends StatelessWidget {
  final DailyPlan plan;

  const GoalTrackingScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${DateFormat('dd MMMM yyyy', 'tr_TR').format(plan.date)}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () => _showCompleteDayDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressCard(),
          Expanded(
            child: _buildGoalsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final completedCount = plan.completedGoalsCount;
    final totalCount = plan.totalGoalsCount;
    final progress = plan.completionRate;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Günlük İlerleme',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$completedCount/$totalCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% tamamlandı',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: plan.goals.length,
      itemBuilder: (context, index) {
        final goal = plan.goals[index];
        return _buildGoalCard(goal, index);
      },
    );
  }

  Widget _buildGoalCard(dynamic goal, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Consumer<GoalsProvider>(
        builder: (context, goalsProvider, child) {
          return ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: GestureDetector(
              onTap: () => _toggleGoal(context, goal.id),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: goal.isCompleted 
                      ? Colors.green 
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  goal.isCompleted ? Icons.check : Icons.circle_outlined,
                  color: goal.isCompleted ? Colors.white : Colors.grey,
                  size: 24,
                ),
              ),
            ),
            title: Text(
              goal.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                decoration: goal.isCompleted 
                    ? TextDecoration.lineThrough 
                    : null,
                color: goal.isCompleted 
                    ? Colors.grey 
                    : Colors.black87,
              ),
            ),
            subtitle: goal.description != goal.title
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      goal.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  )
                : null,
            trailing: goal.isCompleted
                ? const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  )
                : null,
          );
        },
      ),
    );
  }

  void _toggleGoal(BuildContext context, String goalId) {
    final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
    goalsProvider.toggleGoalCompletion(goalId);
  }

  void _showCompleteDayDialog(BuildContext context) {
    final completedCount = plan.completedGoalsCount;
    final totalCount = plan.totalGoalsCount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Günü Tamamla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bugün $completedCount/$totalCount hedefinizi tamamladınız.'),
            const SizedBox(height: 16),
            const Text(
              'Günü tamamlamak istediğinizden emin misiniz? AI geri bildiriminiz hazırlanacak.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeDay(context);
            },
            child: const Text('Tamamla'),
          ),
        ],
      ),
    );
  }

  void _completeDay(BuildContext context) async {
    try {
      final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
      await goalsProvider.completeDay();

      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FeedbackScreen(plan: plan),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 