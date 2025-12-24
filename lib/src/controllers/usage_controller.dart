import 'package:flutter/foundation.dart';
import '../models/session.dart';
import '../services/storage_service.dart';

class UsageController extends ChangeNotifier {
  final _storage = StorageService();

  List<AppUsage> _recentUsage = [];
  final Map<String, int> _appTimeMap = {};

  List<AppUsage> get recentUsage => _recentUsage;
  Map<String, int> get appTimeMap => _appTimeMap;

  Future<void> init() async {
    await loadUsageHistory();
  }

  Future<void> loadUsageHistory({DateTime? since}) async {
    final startOfDay = since ?? _getStartOfDay();
    _recentUsage = await _storage.getAppUsageHistory(since: startOfDay);

    // Build app time map
    _appTimeMap.clear();
    for (var usage in _recentUsage) {
      _appTimeMap[usage.appPackage] =
          (_appTimeMap[usage.appPackage] ?? 0) + usage.timeInMinutes;
    }

    notifyListeners();
  }

  Future<void> recordAppUsage(AppUsage usage) async {
    await _storage.saveAppUsage(usage);
    _recentUsage.add(usage);

    _appTimeMap[usage.appPackage] =
        (_appTimeMap[usage.appPackage] ?? 0) + usage.timeInMinutes;

    notifyListeners();
  }

  int getTotalMinutesToday() {
    return _appTimeMap.values.fold(0, (sum, minutes) => sum + minutes);
  }

  int getAppMinutes(String packageName) {
    return _appTimeMap[packageName] ?? 0;
  }

  List<MapEntry<String, int>> getTopApps({int limit = 10}) {
    final sorted = _appTimeMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  DateTime _getStartOfDay() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void clear() {
    _recentUsage.clear();
    _appTimeMap.clear();
    notifyListeners();
  }
}
