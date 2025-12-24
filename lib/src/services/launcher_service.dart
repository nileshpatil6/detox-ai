import 'package:flutter/services.dart';

class LauncherService {
  static const MethodChannel _channel = MethodChannel('com.detox.launcher/native');

  /// Check if this app is set as the default launcher
  Future<bool> isDefaultLauncher() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDefaultLauncher');
      return result ?? false;
    } catch (e) {
      print('Error checking default launcher: $e');
      return false;
    }
  }

  /// Request to set this app as the default launcher
  /// Opens system settings where user can select the launcher
  Future<void> requestDefaultLauncher() async {
    try {
      await _channel.invokeMethod('requestDefaultLauncher');
    } catch (e) {
      print('Error requesting default launcher: $e');
    }
  }

  /// Check if the app has Usage Stats permission
  Future<bool> hasUsageStatsPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasUsageStatsPermission');
      return result ?? false;
    } catch (e) {
      print('Error checking usage stats permission: $e');
      return false;
    }
  }

  /// Request Usage Stats permission
  /// Opens system settings where user can grant the permission
  Future<void> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
    } catch (e) {
      print('Error requesting usage stats permission: $e');
    }
  }

  /// Check if the app has Accessibility permission
  Future<bool> hasAccessibilityPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasAccessibilityPermission');
      return result ?? false;
    } catch (e) {
      print('Error checking accessibility permission: $e');
      return false;
    }
  }

  /// Request Accessibility permission
  /// Opens accessibility settings where user can enable the service
  Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } catch (e) {
      print('Error requesting accessibility permission: $e');
    }
  }

  /// Start the foreground service for persistence
  Future<void> startForegroundService() async {
    try {
      await _channel.invokeMethod('startForegroundService');
    } catch (e) {
      print('Error starting foreground service: $e');
    }
  }

  /// Stop the foreground service
  Future<void> stopForegroundService() async {
    try {
      await _channel.invokeMethod('stopForegroundService');
    } catch (e) {
      print('Error stopping foreground service: $e');
    }
  }

  /// Launch an app by package name
  Future<bool> launchApp(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'launchApp',
        {'packageName': packageName},
      );
      return result ?? false;
    } catch (e) {
      print('Error launching app: $e');
      return false;
    }
  }

  /// Check all critical permissions
  Future<Map<String, bool>> checkAllPermissions() async {
    final isDefaultLauncher = await this.isDefaultLauncher();
    final hasUsageStats = await hasUsageStatsPermission();
    final hasAccessibility = await hasAccessibilityPermission();

    return {
      'defaultLauncher': isDefaultLauncher,
      'usageStats': hasUsageStats,
      'accessibility': hasAccessibility,
    };
  }

  /// Get missing permissions list
  Future<List<String>> getMissingPermissions() async {
    final permissions = await checkAllPermissions();
    final missing = <String>[];

    if (!permissions['defaultLauncher']!) {
      missing.add('Default Launcher');
    }
    if (!permissions['usageStats']!) {
      missing.add('Usage Stats');
    }
    if (!permissions['accessibility']!) {
      missing.add('Accessibility Service');
    }

    return missing;
  }
}
