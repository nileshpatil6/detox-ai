import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_apps/device_apps.dart';
import '../../controllers/detox_controller.dart';
import '../../controllers/task_controller.dart';
import '../../models/task.dart';
import '../widgets/robot_avatar.dart';
import '../widgets/minutes_indicator.dart';
import '../widgets/app_icon_widget.dart';
import '../theme/app_theme.dart';
import 'walking_task_screen.dart';
import 'task_execution_screen.dart';
import 'settings_screen.dart';

import 'package:google_fonts/google_fonts.dart';

class LauncherHomeScreen extends StatefulWidget {
  const LauncherHomeScreen({super.key});

  @override
  State<LauncherHomeScreen> createState() => _LauncherHomeScreenState();
}

class _LauncherHomeScreenState extends State<LauncherHomeScreen> {
  List<Application> _allApps = [];
  List<Application> _allowedApps = [];
  bool _isLoading = true;
  late String _currentQuote;

  final List<String> _quotes = [
    "\"Breathe in, breathe out.\"",
    "\"Disconnect to reconnect.\"",
    "\"Focus on what matters.\"",
    "\"Digital minimalism.\"",
    "\"Live in the moment.\"",
    "\"Less screen, more life.\"",
    "\"Be present.\"",
    "\"Unplug and recharge.\"",
    "\"Create, don't consume.\"",
    "\"Your time is precious.\""
  ];

  @override
  void initState() {
    super.initState();
    _currentQuote = _quotes[DateTime.now().second % _quotes.length];
    _loadApps();
    _initControllers();
  }

  Future<void> _initControllers() async {
    final detoxController = context.read<DetoxController>();
    final taskController = context.read<TaskController>();

    await detoxController.init();
    await taskController.init();
  }

  Future<void> _loadApps() async {
    try {
      final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        onlyAppsWithLaunchIntent: true,
      );

      final detoxController = context.read<DetoxController>();
      final allowedPackages = detoxController.userProfile?.allowedApps ?? [];

      setState(() {
        _allApps = apps;
        _allowedApps = apps
            .where((app) => allowedPackages.contains(app.packageName))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _launchApp(Application app) {
    DeviceApps.openApp(app.packageName);
  }

  void _showLockNowDialog() {
    int selectedMinutes = 30; // Default 30 minutes

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.softGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.accentGreen.withOpacity(0.3)),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_clock, color: AppTheme.accentGreen),
              const SizedBox(width: 12),
              const Text('Lock Now', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How long do you want to lock your phone?',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Text(
                '$selectedMinutes minutes',
                style: TextStyle(
                  color: AppTheme.accentGreen,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: selectedMinutes.toDouble(),
                min: 5,
                max: 120,
                divisions: 23,
                activeColor: AppTheme.accentGreen,
                inactiveColor: AppTheme.mediumGrey,
                onChanged: (value) {
                  setDialogState(() {
                    selectedMinutes = value.round();
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('5 min',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text('2 hours',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              // Quick select buttons
              Wrap(
                spacing: 8,
                children: [15, 30, 60, 90]
                    .map(
                      (mins) => ChoiceChip(
                        label: Text('${mins}m'),
                        selected: selectedMinutes == mins,
                        selectedColor: AppTheme.accentGreen,
                        backgroundColor: AppTheme.mediumGrey,
                        labelStyle: TextStyle(
                          color: selectedMinutes == mins
                              ? Colors.black
                              : Colors.white,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              selectedMinutes = mins;
                            });
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final detoxController = context.read<DetoxController>();
                await detoxController.lockNow(selectedMinutes);
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/lock');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.black,
              ),
              child: const Text('Lock'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Column(
                children: [
                  // Top action bar with Lock Now and Settings
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Lock Now button
                        TextButton.icon(
                          onPressed: _showLockNowDialog,
                          icon: const Icon(Icons.lock_clock,
                              color: AppTheme.accentGreen),
                          label: const Text(
                            'Lock Now',
                            style: TextStyle(color: AppTheme.accentGreen),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                AppTheme.accentGreen.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                  color: AppTheme.accentGreen.withOpacity(0.3)),
                            ),
                          ),
                        ),
                        // Settings button
                        IconButton(
                          icon: const Icon(Icons.settings,
                              color: AppTheme.primaryWhite),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Top status bar with minutes
                  const MinutesIndicator(),

                  const SizedBox(height: 24),

                  // Robot Avatar (center)
                  const RobotAvatar(),

                  const SizedBox(height: 16),

                  // Motivational Quote
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _currentQuote,
                      style: GoogleFonts.outfit(
                        color: AppTheme.accentGreen,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Important/Allowed Apps Row
                  if (_allowedApps.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Important Apps',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _allowedApps.length,
                        itemBuilder: (context, index) {
                          final app = _allowedApps[index];
                          return AppIconWidget(
                            app: app,
                            onTap: () => _launchApp(app),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // All Apps List (monochrome, long scrolling)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'All Apps',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: Container(
                      color: Colors.black, // Explicit black
                      child: _allApps.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.apps_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No apps found',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _allApps.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                      height: 1, color: Color(0xFF333333)),
                              itemBuilder: (context, index) {
                                final app = _allApps[index];
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                        0xFF111111), // Very dark grey, almost black
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFF333333)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFF333333)),
                                      ),
                                      child: app is ApplicationWithIcon
                                          ? Image.memory(
                                              app.icon,
                                              width: 40,
                                              height: 40,
                                            )
                                          : const Icon(Icons.android,
                                              color: Colors.white),
                                    ),
                                    title: Text(
                                      app.appName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    onTap: () => _launchApp(app),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accentGreen, Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGreen.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            _showTasksBottomSheet();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.task_alt,
              color: AppTheme.primaryBlack, size: 28),
        ),
      ),
    );
  }

  void _showTasksBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.softGrey,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<TaskController>(
              builder: (context, taskController, child) {
                final tasks = taskController.activeTasks;

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.mediumGrey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Available Tasks',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.softGrey,
                                  AppTheme.mediumGrey.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.accentGreen.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                task.title,
                                style: const TextStyle(
                                  color: AppTheme.primaryWhite,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  task.description,
                                  style: const TextStyle(
                                    color: AppTheme.veryLightGrey,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.accentGreen,
                                      Color(0xFF66BB6A)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppTheme.accentGreen.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '+${task.minutesReward}m',
                                  style: const TextStyle(
                                    color: AppTheme.primaryBlack,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _startTask(task.id);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _startTask(String taskId) {
    final taskController = context.read<TaskController>();
    final task = taskController.getTask(taskId);

    if (task == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
}
