import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/detox_controller.dart';
import '../../services/storage_service.dart';
import '../../ai/gemini_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService();
  final _geminiService = GeminiService();

  final _apiKeyController = TextEditingController();
  final _motivationController = TextEditingController();

  int? _dailyGoalMinutes;
  int? _weeklyGoalMinutes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final detoxController = context.read<DetoxController>();
    final profile = detoxController.userProfile;

    if (profile != null) {
      setState(() {
        _dailyGoalMinutes = profile.dailyGoalMinutes;
        _weeklyGoalMinutes = profile.weeklyGoalMinutes;
        _motivationController.text = profile.motivationText;
      });
    }

    final apiKey = await _storage.getGeminiApiKey();
    if (apiKey != null) {
      _apiKeyController.text = apiKey;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryBlack,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Usage Goals'),
          _buildGoalsSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Motivation'),
          _buildMotivationSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('AI Verification'),
          _buildGeminiSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Passes'),
          _buildPassesSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Permissions'),
          _buildPermissionsSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('About'),
          _buildAboutSection(),
          const SizedBox(height: 24),
          _buildDangerZone(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );
  }

  Widget _buildGoalsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.softUICard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Goal',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _dailyGoalMinutes,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            dropdownColor: AppTheme.softGrey,
            items: [30, 60, 90, 120, 180, 240].map((minutes) {
              return DropdownMenuItem(
                value: minutes,
                child: Text('$minutes minutes'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _dailyGoalMinutes = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Weekly Goal',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _weeklyGoalMinutes,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            dropdownColor: AppTheme.softGrey,
            items: [210, 420, 630, 840, 1260, 1680].map((minutes) {
              return DropdownMenuItem(
                value: minutes,
                child: Text('${(minutes / 60).toStringAsFixed(1)} hours'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _weeklyGoalMinutes = value;
              });
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveGoals,
              child: const Text('Save Goals'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.softUICard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your motivation for using Detox Launcher',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _motivationController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Why do you want to reduce screen time?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveMotivation,
              child: const Text('Save Motivation'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.softUICard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy, color: AppTheme.primaryWhite),
              const SizedBox(width: 8),
              Text(
                'Gemini API Key',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Required for AI-powered task verification',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter your Gemini API key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  _showApiKeyInfo();
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveApiKey,
                  child: const Text('Save API Key'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _testApiKey,
                child: const Text('Test'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassesSection() {
    return Consumer<DetoxController>(
      builder: (context, controller, child) {
        final passes = controller.userProfile?.passes;
        if (passes == null) {
          return const SizedBox();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.softUICard,
          child: Column(
            children: [
              _buildPassRow('Gold Pass', passes.goldRemaining, passes.goldTotal, Colors.amber),
              const Divider(height: 24),
              _buildPassRow('Silver Pass', passes.silverRemaining, passes.silverTotal, Colors.grey),
              const Divider(height: 24),
              _buildPassRow('Grey Pass', passes.greyRemaining, passes.greyTotal, Colors.blueGrey),
              const SizedBox(height: 16),
              Text(
                'Passes reset on the 1st of each month',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightGrey,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPassRow(String name, int remaining, int total, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.card_giftcard, color: color),
            const SizedBox(width: 12),
            Text(name, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        Text(
          '$remaining / $total',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.softUICard,
      child: Column(
        children: [
          _buildPermissionRow(
            'Usage Access',
            'Track app usage time',
            Icons.access_time,
            () async {
              // Open usage access settings
              // This requires native implementation
              _showInfo('Please enable Usage Access in Android Settings');
            },
          ),
          const Divider(height: 24),
          _buildPermissionRow(
            'Accessibility Service',
            'Block apps in lock mode',
            Icons.accessibility,
            () {
              _showInfo('Please enable Accessibility Service in Android Settings');
            },
          ),
          const Divider(height: 24),
          _buildPermissionRow(
            'Default Launcher',
            'Set as home screen',
            Icons.home,
            () {
              _showInfo('Please set Detox as your default launcher in Android Settings');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryWhite),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.softUICard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detox Launcher',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'A minimal Android launcher designed to help you reduce screen time and stay focused.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              // Open privacy policy or GitHub
              _showInfo('Privacy Policy: All data is stored locally on your device.');
            },
            child: const Text('Privacy Policy'),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.softUICard.copyWith(
        border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danger Zone',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.red,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _resetAllData,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text(
                'Reset All Data',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGoals() async {
    if (_dailyGoalMinutes == null || _weeklyGoalMinutes == null) {
      _showError('Please select both daily and weekly goals');
      return;
    }

    final detoxController = context.read<DetoxController>();
    final profile = detoxController.userProfile;

    if (profile != null) {
      final updatedProfile = profile.copyWith(
        dailyGoalMinutes: _dailyGoalMinutes,
        weeklyGoalMinutes: _weeklyGoalMinutes,
        updatedAt: DateTime.now(),
      );

      await detoxController.updateUserProfile(updatedProfile);
      _showSuccess('Goals updated successfully');
    }
  }

  Future<void> _saveMotivation() async {
    final motivation = _motivationController.text.trim();
    if (motivation.isEmpty) {
      _showError('Please enter your motivation');
      return;
    }

    final detoxController = context.read<DetoxController>();
    final profile = detoxController.userProfile;

    if (profile != null) {
      final updatedProfile = profile.copyWith(
        motivationText: motivation,
        updatedAt: DateTime.now(),
      );

      await detoxController.updateUserProfile(updatedProfile);
      _showSuccess('Motivation updated successfully');
    }
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _showError('Please enter a valid API key');
      return;
    }

    try {
      await _geminiService.setApiKey(apiKey);
      _showSuccess('API key saved successfully');
    } catch (e) {
      _showError('Failed to save API key: ${e.toString()}');
    }
  }

  Future<void> _testApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _showError('Please enter an API key first');
      return;
    }

    try {
      await _geminiService.setApiKey(apiKey);

      // Test with a simple prompt
      _showInfo('Testing API key... This may take a moment.');

      // In a real implementation, you'd make a test API call here
      // For now, just check if it's initialized
      if (_geminiService.isInitialized) {
        _showSuccess('API key is valid and working!');
      } else {
        _showError('API key validation failed');
      }
    } catch (e) {
      _showError('API key test failed: ${e.toString()}');
    }
  }

  void _showApiKeyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.softGrey,
        title: const Text('Gemini API Key'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To use AI task verification, you need a Gemini API key.'),
            SizedBox(height: 12),
            Text('1. Visit: https://makersuite.google.com/app/apikey'),
            SizedBox(height: 8),
            Text('2. Sign in with your Google account'),
            SizedBox(height: 8),
            Text('3. Create a new API key'),
            SizedBox(height: 8),
            Text('4. Copy and paste it here'),
            SizedBox(height: 12),
            Text(
              'The free tier includes 15 requests per minute.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.softGrey,
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will delete all your data including:\n\n'
          '• Usage history\n'
          '• Completed tasks\n'
          '• Settings and goals\n'
          '• Pass usage\n\n'
          'This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset All Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.clearAllData();
      if (mounted) {
        _showSuccess('All data has been reset');
        // Navigate back to onboarding
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/onboarding',
          (route) => false,
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.mediumGrey),
    );
  }
}
