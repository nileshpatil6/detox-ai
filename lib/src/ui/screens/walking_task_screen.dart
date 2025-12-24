import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/detox_controller.dart';
import '../../services/step_counter_service.dart';
import '../theme/app_theme.dart';

class WalkingTaskScreen extends StatefulWidget {
  final Task task;

  const WalkingTaskScreen({
    super.key,
    required this.task,
  });

  @override
  State<WalkingTaskScreen> createState() => _WalkingTaskScreenState();
}

class _WalkingTaskScreenState extends State<WalkingTaskScreen> {
  late StepCounterService _stepService;
  late WalkingTaskTracker _tracker;
  bool _isStarted = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _stepService = StepCounterService();
    _initStepCounter();
  }

  Future<void> _initStepCounter() async {
    try {
      await _stepService.init();
      await _stepService.startTracking();

      _tracker = WalkingTaskTracker(
        stepService: _stepService,
        targetSteps: widget.task.stepsRequired,
        onComplete: _onTaskComplete,
      );

      setState(() {});
    } catch (e) {
      _showError('Failed to initialize step counter: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _tracker.stop();
    _stepService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        title: Text(widget.task.title),
        backgroundColor: AppTheme.primaryBlack,
      ),
      body: _isCompleted ? _buildCompletedView() : _buildTrackingView(),
    );
  }

  Widget _buildTrackingView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Task info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.softUICard,
            child: Column(
              children: [
                const Icon(
                  Icons.directions_walk,
                  size: 64,
                  color: AppTheme.primaryWhite,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.task.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Reward: +${widget.task.minutesReward} minutes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Step counter display
          if (_isStarted) ...[
            Text(
              'Steps Walked',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                final currentSteps = _stepService.sessionSteps;
                final progress = _tracker.getProgress();
                final stepsRemaining = _tracker.getStepsRemaining();

                return Column(
                  children: [
                    // Large step count
                    Text(
                      '$currentSteps',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 72,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Target: ${widget.task.stepsRequired} steps',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),

                    // Progress bar
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 12,
                            backgroundColor: AppTheme.mediumGrey,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$progress% complete',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Steps remaining
                    Text(
                      '$stepsRemaining steps to go!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.green,
                          ),
                    ),
                  ],
                );
              },
            ),
          ],

          const Spacer(),

          // Start/Cancel buttons
          if (!_isStarted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Start Walking'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _cancelTask,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompletedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'Task Completed!',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'You walked ${widget.task.stepsRequired} steps',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.softUICard,
              child: Column(
                children: [
                  const Icon(
                    Icons.timer,
                    size: 48,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '+${widget.task.minutesReward} minutes',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.green,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Added to your balance',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startTask() {
    setState(() {
      _isStarted = true;
    });
    _stepService.resetSession();
    _tracker.start();

    final taskController = context.read<TaskController>();
    taskController.startTask(widget.task.id);
  }

  void _cancelTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.softGrey,
        title: const Text('Cancel Task?'),
        content: const Text(
          'Are you sure you want to cancel this walking task? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Walking', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close task screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Task'),
          ),
        ],
      ),
    );
  }

  Future<void> _onTaskComplete(int minutesEarned) async {
    _tracker.stop();

    final taskController = context.read<TaskController>();
    final detoxController = context.read<DetoxController>();

    // Mark task as completed
    final verificationResult = VerificationResult(
      verified: true,
      confidence: 1.0,
      reason: 'Steps completed: ${widget.task.stepsRequired}',
      verifiedAt: DateTime.now(),
    );

    await taskController.completeTask(
      widget.task.id,
      verificationResult: verificationResult,
    );

    // Add minutes to balance
    await detoxController.addMinutes(minutesEarned, widget.task.id);

    setState(() {
      _isCompleted = true;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
