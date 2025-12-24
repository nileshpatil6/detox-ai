import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/detox_controller.dart';
import '../../controllers/task_controller.dart';
import '../../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/robot_avatar.dart';
import 'walking_task_screen.dart';
import 'task_execution_screen.dart';

class LockModeScreen extends StatefulWidget {
  const LockModeScreen({super.key});

  @override
  State<LockModeScreen> createState() => _LockModeScreenState();
}

class _LockModeScreenState extends State<LockModeScreen> {
  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  Future<void> _initControllers() async {
    final detoxController = context.read<DetoxController>();
    final taskController = context.read<TaskController>();

    await detoxController.init();
    await taskController.init();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Lock icon
                const Icon(
                  Icons.lock,
                  size: 80,
                  color: Colors.red,
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'Phone Locked',
                  style: Theme.of(context).textTheme.displayLarge,
                ),

                const SizedBox(height: 12),

                // Message
                Consumer<DetoxController>(
                  builder: (context, controller, child) {
                    final profile = controller.userProfile;
                    return Text(
                      'You\'ve reached your daily limit of ${profile?.dailyGoalMinutes ?? 0} minutes.\nComplete tasks below to unlock more time.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Robot avatar
                const RobotAvatar(size: 100),

                const SizedBox(height: 32),

                // Motivation text
                Consumer<DetoxController>(
                  builder: (context, controller, child) {
                    final motivation = controller.userProfile?.motivationText;
                    if (motivation == null || motivation.isEmpty) {
                      return const SizedBox();
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.softUICard,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.format_quote,
                            color: AppTheme.lightGrey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            motivation,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Available tasks
                Text(
                  'Complete Tasks to Unlock',
                  style: Theme.of(context).textTheme.displaySmall,
                ),

                const SizedBox(height: 16),

                Consumer<TaskController>(
                  builder: (context, taskController, child) {
                    final tasks = taskController.activeTasks;

                    if (tasks.isEmpty) {
                      return Column(
                        children: [
                          const Text('No tasks available'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              await taskController.generateDynamicTasks();
                            },
                            child: const Text('Generate New Tasks'),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: tasks.map((task) => _buildTaskCard(task)).toList(),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Passes section
                const Divider(),
                const SizedBox(height: 16),

                Text(
                  'Or Use a Pass',
                  style: Theme.of(context).textTheme.displaySmall,
                ),

                const SizedBox(height: 16),

                Consumer<DetoxController>(
                  builder: (context, controller, child) {
                    final passes = controller.userProfile?.passes;
                    if (passes == null) return const SizedBox();

                    return Column(
                      children: [
                        _buildPassCard(
                          title: 'Gold Pass',
                          description: 'Unlock for the whole month',
                          remaining: passes.goldRemaining,
                          total: passes.goldTotal,
                          color: Colors.amber,
                          onUse: () => _usePass('gold', controller),
                        ),
                        const SizedBox(height: 12),
                        _buildPassCard(
                          title: 'Silver Pass',
                          description: '10 minutes',
                          remaining: passes.silverRemaining,
                          total: passes.silverTotal,
                          color: Colors.grey,
                          onUse: () => _usePass('silver', controller),
                        ),
                        const SizedBox(height: 12),
                        _buildPassCard(
                          title: 'Grey Pass',
                          description: '2 minutes',
                          remaining: passes.greyRemaining,
                          total: passes.greyTotal,
                          color: Colors.blueGrey,
                          onUse: () => _usePass('grey', controller),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Emergency access
                Text(
                  'Emergency?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'You can still make emergency calls',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.softUICard,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.mediumGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconForTaskType(task.type),
              color: AppTheme.primaryWhite,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${task.minutesReward}m',
                  style: const TextStyle(
                    color: AppTheme.primaryBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: () => _startTask(task),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassCard({
    required String title,
    required String description,
    required int remaining,
    required int total,
    required Color color,
    required VoidCallback onUse,
  }) {
    final isAvailable = remaining > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.softUICard.copyWith(
        border: Border.all(
          color: isAvailable ? color : AppTheme.mediumGrey,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.card_giftcard,
            color: isAvailable ? color : AppTheme.lightGrey,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '$remaining/$total remaining',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                      ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isAvailable ? onUse : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAvailable ? color : AppTheme.mediumGrey,
            ),
            child: const Text('Use'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTaskType(TaskType type) {
    switch (type) {
      case TaskType.walking:
        return Icons.directions_walk;
      case TaskType.photoVerification:
        return Icons.camera_alt;
      case TaskType.reading:
        return Icons.book;
      case TaskType.creative:
        return Icons.brush;
      case TaskType.videoVerification:
        return Icons.videocam;
    }
  }

  void _startTask(Task task) {
    // Navigate to appropriate task screen based on task type
    if (task.type == TaskType.walking) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WalkingTaskScreen(task: task),
        ),
      );
    } else {
      // For photo/video/reading/creative tasks, use camera screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskExecutionScreen(task: task),
        ),
      );
    }
  }

  Future<void> _usePass(String passType, DetoxController controller) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.softGrey,
        title: Text('Use $passType Pass?'),
        content: Text(
          'Are you sure you want to use a $passType pass? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Use Pass'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      switch (passType) {
        case 'gold':
          await controller.useGoldPass();
          break;
        case 'silver':
          await controller.useSilverPass();
          break;
        case 'grey':
          await controller.useGreyPass();
          break;
      }

      // Check if unlocked
      final isLocked = await controller.checkLockStatus();
      if (!isLocked && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }
}
