import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/goals_provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import 'goal_setup_screen.dart';
import 'goal_tracking_screen.dart';
import 'feedback_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);

    // Sign in anonymously if not authenticated
    if (!authProvider.isAuthenticated) {
      await authProvider.signInAnonymously();
    }

    // Load today's plan
    await goalsProvider.loadTodayPlan();

    // Schedule notifications
    await NotificationService().scheduleDailyNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiniPlan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
          ),
        ],
      ),
      body: Consumer<GoalsProvider>(
        builder: (context, goalsProvider, child) {
          if (goalsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final currentPlan = goalsProvider.currentPlan;
          final today = DateTime.now();
          final isToday = currentPlan != null && 
              currentPlan.date.year == today.year &&
              currentPlan.date.month == today.month &&
              currentPlan.date.day == today.day;

          if (!isToday) {
            return _buildWelcomeScreen();
          }

          if (currentPlan!.isCompleted) {
            return _buildCompletedDayScreen(currentPlan);
          }

          return GoalTrackingScreen(plan: currentPlan);
        },
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events,
            size: 80,
            color: Color(0xFF2196F3),
          ),
          const SizedBox(height: 24),
          const Text(
            'Günaydın! 🌅',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bugün için 3 hedefinizi belirleyin ve güne başlayın!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToGoalSetup(),
            icon: const Icon(Icons.add),
            label: const Text('Hedeflerimi Belirle'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedDayScreen(dynamic plan) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            'Günü Tamamladınız! 🎉',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${plan.completedGoalsCount}/${plan.totalGoalsCount} hedef tamamlandı',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          if (plan.aiFeedback != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    'AI Geri Bildirimi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.aiFeedback!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          ElevatedButton(
            onPressed: () => _navigateToGoalSetup(),
            child: const Text('Yarın İçin Yeni Hedefler'),
          ),
        ],
      ),
    );
  }

  void _navigateToGoalSetup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GoalSetupScreen(),
      ),
    );
  }

  void _showHistory(BuildContext context) {
    // TODO: Implement history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geçmiş planlar yakında eklenecek!')),
    );
  }
} 