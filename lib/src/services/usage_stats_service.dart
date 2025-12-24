import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:usage_stats/usage_stats.dart' as usage_stats;
import '../models/session.dart';
import 'storage_service.dart';

class UsageStatsService extends ChangeNotifier {
  final _storage = StorageService();

  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  DateTime? _lastCheckTime;

  List<usage_stats.UsageInfo> _recentUsageInfo = [];
  final Map<String, int> _appUsageMinutes = {};

  bool get isMonitoring => _isMonitoring;
  Map<String, int> get appUsageMinutes => _appUsageMinutes;

  Future<bool> requestPermission() async {
    // For usage stats, we need to guide user to settings
    // as it can't be requested directly via permission_handler
    try {
      final granted = await UsageStats.checkUsagePermission() ?? false;
      if (!granted) {
        await UsageStats.grantUsagePermission();
      }
      return await UsageStats.checkUsagePermission() ?? false;
    } catch (e) {
      debugPrint('Error requesting usage permission: $e');
      return false;
    }
  }

  Future<void> startMonitoring({
    Duration checkInterval = const Duration(minutes: 1),
  }) async {
    if (_isMonitoring) return;

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('Usage stats permission not granted');
    }

    _isMonitoring = true;
    _lastCheckTime = DateTime.now();

    // Check usage stats periodically
    _monitoringTimer = Timer.periodic(checkInterval, (_) {
      _checkUsageStats();
    });

    // Initial check
    await _checkUsageStats();

    notifyListeners();
  }

  Future<void> _checkUsageStats() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Query usage stats for today
      final usageStats = await UsageStats.queryUsageStats(
        startOfDay,
        now,
      );

      if (usageStats == null || usageStats.isEmpty) {
        return;
      }

      _recentUsageInfo = usageStats;
      _updateAppUsageMap(usageStats);

      // Save to storage for persistence
      for (var stat in usageStats) {
        if (stat.packageName != null && stat.totalTimeInForeground != null) {
          final usage = AppUsage(
            appPackage: stat.packageName!,
            appName: stat.packageName!, // Would need package manager to get real name
            timeInForegroundMs: int.parse(stat.totalTimeInForeground ?? '0'),
            timestamp: DateTime.now(),
            isAllowed: false, // Would check against allowed list
          );

          await _storage.saveAppUsage(usage);
        }
      }

      _lastCheckTime = now;
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking usage stats: $e');
    }
  }

  void _updateAppUsageMap(List<usage_stats.UsageInfo> usageStats) {
    _appUsageMinutes.clear();

    for (var stat in usageStats) {
      if (stat.packageName != null && stat.totalTimeInForeground != null) {
        try {
          final milliseconds = int.parse(stat.totalTimeInForeground!);
          final minutes = (milliseconds / 60000).round();
          _appUsageMinutes[stat.packageName!] = minutes;
        } catch (e) {
          debugPrint('Error parsing usage time: $e');
        }
      }
    }
  }

  int getTotalUsageMinutesToday() {
    return _appUsageMinutes.values.fold(0, (sum, minutes) => sum + minutes);
  }

  int getAppUsageMinutes(String packageName) {
    return _appUsageMinutes[packageName] ?? 0;
  }

  List<MapEntry<String, int>> getTopUsedApps({int limit = 10}) {
    final sorted = _appUsageMinutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  Future<Map<String, int>> getUsageForPeriod({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final usageStats = await UsageStats.queryUsageStats(start, end);

      if (usageStats == null || usageStats.isEmpty) {
        return {};
      }

      final Map<String, int> usageMap = {};

      for (var stat in usageStats) {
        if (stat.packageName != null && stat.totalTimeInForeground != null) {
          try {
            final milliseconds = int.parse(stat.totalTimeInForeground!);
            final minutes = (milliseconds / 60000).round();
            usageMap[stat.packageName!] = minutes;
          } catch (e) {
            debugPrint('Error parsing usage time: $e');
          }
        }
      }

      return usageMap;
    } catch (e) {
      debugPrint('Error getting usage for period: $e');
      return {};
    }
  }

  Future<void> stopMonitoring() async {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isMonitoring = false;
    notifyListeners();
  }

  void clear() {
    _recentUsageInfo.clear();
    _appUsageMinutes.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}

class AppUsageMonitor {
  final UsageStatsService _usageService;
  final int _dailyLimitMinutes;
  final Function(int minutesUsed) _onUsageUpdate;
  final Function() _onLimitExceeded;

  Timer? _checkTimer;

  AppUsageMonitor({
    required UsageStatsService usageService,
    required int dailyLimitMinutes,
    required Function(int minutesUsed) onUsageUpdate,
    required Function() onLimitExceeded,
  })  : _usageService = usageService,
        _dailyLimitMinutes = dailyLimitMinutes,
        _onUsageUpdate = onUsageUpdate,
        _onLimitExceeded = onLimitExceeded;

  void start() {
    // Check usage every minute
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkUsage();
    });

    // Initial check
    _checkUsage();
  }

  void _checkUsage() {
    final totalMinutes = _usageService.getTotalUsageMinutesToday();
    _onUsageUpdate(totalMinutes);

    if (totalMinutes >= _dailyLimitMinutes) {
      _onLimitExceeded();
    }
  }

  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }
}

class UsageStats {
  // Wrapper methods for the usage_stats package

  static Future<bool?> checkUsagePermission() async {
    try {
      return await UsageStatsPackage.checkUsagePermission();
    } catch (e) {
      debugPrint('Error checking usage permission: $e');
      return false;
    }
  }

  static Future<void> grantUsagePermission() async {
    try {
      await UsageStatsPackage.grantUsagePermission();
    } catch (e) {
      debugPrint('Error granting usage permission: $e');
    }
  }

  static Future<List<usage_stats.UsageInfo>?> queryUsageStats(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await UsageStatsPackage.queryUsageStats(start, end);
    } catch (e) {
      debugPrint('Error querying usage stats: $e');
      return null;
    }
  }
}

// Alias to avoid naming conflict
class UsageStatsPackage {
  static Future<bool?> checkUsagePermission() async {
    return await usage_stats.UsageStats.checkUsagePermission();
  }

  static Future<void> grantUsagePermission() async {
    await usage_stats.UsageStats.grantUsagePermission();
  }

  static Future<List<usage_stats.UsageInfo>?> queryUsageStats(
    DateTime start,
    DateTime end,
  ) async {
    return await usage_stats.UsageStats.queryUsageStats(start, end);
  }
}
