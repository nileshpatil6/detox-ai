import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../../controllers/detox_controller.dart';
import '../../models/user_profile.dart';
import '../../services/storage_service.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _uuid = const Uuid();
  int _currentPage = 0;

  // User inputs
  int _dailyGoalMinutes = 60;
  int _weeklyGoalMinutes = 420;
  String _motivationText = '';
  final List<String> _selectedApps = [];

  final List<int> _dailyGoalPresets = [30, 60, 90, 120, 180];
  final List<int> _weeklyGoalPresets = [210, 420, 630, 840, 1260];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 4,
              backgroundColor: AppTheme.mediumGrey,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryWhite),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildGoalsPage(),
                  _buildMotivationPage(),
                  _buildPermissionsPage(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    onPressed:
                        _currentPage == 3 ? _completeOnboarding : _nextPage,
                    child: Text(_currentPage == 3 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'welcome',
            child: Image.asset(
              'assets/images/onboarding_welcome.png',
              height: 200,
              width: 200,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Detox Launcher',
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'A minimal launcher designed to help you reduce screen time and stay focused on what matters.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.softUICard,
            child: Column(
              children: [
                _buildFeatureItem('Intentional friction on distracting apps'),
                const SizedBox(height: 12),
                _buildFeatureItem('Earn phone time through productive tasks'),
                const SizedBox(height: 12),
                _buildFeatureItem('AI-verified task completion'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppTheme.primaryWhite, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goals Image
          Center(
            child: Hero(
              tag: 'goals',
              child: Image.asset(
                'assets/images/onboarding_goals.png',
                height: 150,
                width: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Set Your Goals',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how much screen time you want each day and week',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),

          // Daily goal
          Text(
            'Daily Goal',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dailyGoalPresets.map((minutes) {
              final isSelected = _dailyGoalMinutes == minutes;
              return ChoiceChip(
                label: Text('$minutes min'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _dailyGoalMinutes = minutes;
                  });
                },
                selectedColor: AppTheme.primaryWhite,
                backgroundColor: AppTheme.softGrey,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryBlack
                      : AppTheme.primaryWhite,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Weekly goal
          Text(
            'Weekly Goal',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weeklyGoalPresets.map((minutes) {
              final isSelected = _weeklyGoalMinutes == minutes;
              return ChoiceChip(
                label: Text('${(minutes / 60).toStringAsFixed(1)}h'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _weeklyGoalMinutes = minutes;
                  });
                },
                selectedColor: AppTheme.primaryWhite,
                backgroundColor: AppTheme.softGrey,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryBlack
                      : AppTheme.primaryWhite,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Motivation Image
          Center(
            child: Hero(
              tag: 'motivation',
              child: Image.asset(
                'assets/images/onboarding_motivation.png',
                height: 150,
                width: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Motivation',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Why do you want to reduce your screen time?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          TextField(
            maxLines: 5,
            decoration: const InputDecoration(
              hintText:
                  'e.g., I want to spend more time with family, read books, exercise...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _motivationText = value;
            },
          ),
          const SizedBox(height: 24),
          Text(
            'This will remind you why you started when things get tough.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Permissions Image
          Center(
            child: Hero(
              tag: 'permissions',
              child: Image.asset(
                'assets/images/onboarding_permissions.png',
                height: 150,
                width: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Required Permissions',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'We need these permissions to make Detox Launcher work',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _buildPermissionCard(
            icon: Icons.home,
            title: 'Default Launcher',
            description:
                'Set Detox as your home screen to replace your current launcher',
            action: ElevatedButton(
              onPressed: () async {
                const intent = AndroidIntent(
                  action: 'android.settings.HOME_SETTINGS',
                );
                await intent.launch();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Set Default'),
            ),
          ),
          const SizedBox(height: 12),
          _buildPermissionCard(
            icon: Icons.camera_alt,
            title: 'Camera Access',
            description: 'Take photos to verify task completion',
          ),
          const SizedBox(height: 12),
          _buildPermissionCard(
            icon: Icons.directions_walk,
            title: 'Activity Recognition',
            description: 'Track your steps for walking tasks',
          ),
          const SizedBox(height: 12),
          _buildPermissionCard(
            icon: Icons.notifications,
            title: 'Notifications',
            description: 'Receive reminders and lock mode alerts',
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.softUICard,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(icon, color: AppTheme.primaryWhite, size: 32),
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
                if (action != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: action,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    // Request permissions
    await _requestPermissions();

    // Create user profile
    final profile = UserProfile.create(
      id: _uuid.v4(),
      dailyGoalMinutes: _dailyGoalMinutes,
      weeklyGoalMinutes: _weeklyGoalMinutes,
      allowedApps: _selectedApps,
      focusHours: const [],
      motivationText: _motivationText,
    );

    // Save to storage
    final storage = StorageService();
    await storage.saveUserProfile(profile);
    await storage.setOnboardingComplete(true);

    // Update controller
    if (mounted) {
      final detoxController = context.read<DetoxController>();
      await detoxController.updateUserProfile(profile);

      // Navigate to home
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.activityRecognition.request();
    await Permission.notification.request();

    // Note: Setting default launcher requires user action in system settings
    // We can't programmatically set it, but we can guide the user
  }
}
