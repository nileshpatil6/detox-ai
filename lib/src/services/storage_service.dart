import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';
import '../models/session.dart';
import '../models/task.dart';

class StorageService {
  static const String _userProfileBox = 'user_profile';
  static const String _sessionBox = 'session';
  static const String _tasksBox = 'tasks';
  static const String _appUsageBox = 'app_usage';
  static const String _settingsBox = 'settings';

  final _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    // Open Hive boxes
    await Hive.openBox(_userProfileBox);
    await Hive.openBox(_sessionBox);
    await Hive.openBox(_tasksBox);
    await Hive.openBox(_appUsageBox);
    await Hive.openBox(_settingsBox);
  }

  // User Profile
  Future<void> saveUserProfile(UserProfile profile) async {
    final box = Hive.box(_userProfileBox);
    await box.put('profile', json.encode(profile.toJson()));
  }

  Future<UserProfile?> getUserProfile() async {
    final box = Hive.box(_userProfileBox);
    final data = box.get('profile');
    if (data == null) return null;
    return UserProfile.fromJson(json.decode(data));
  }

  // Session
  Future<void> saveCurrentSession(Session session) async {
    final box = Hive.box(_sessionBox);
    await box.put('current_session', json.encode(session.toJson()));
  }

  Future<Session?> getCurrentSession() async {
    final box = Hive.box(_sessionBox);
    final data = box.get('current_session');
    if (data == null) return null;
    return Session.fromJson(json.decode(data));
  }

  Future<void> saveSessionHistory(Session session) async {
    final box = Hive.box(_sessionBox);
    final history =
        box.get('session_history', defaultValue: <String>[]) as List;
    history.add(json.encode(session.toJson()));
    await box.put('session_history', history);
  }

  // Tasks
  Future<void> saveTask(Task task) async {
    final box = Hive.box(_tasksBox);
    await box.put(task.id, json.encode(task.toJson()));
  }

  Future<Task?> getTask(String id) async {
    final box = Hive.box(_tasksBox);
    final data = box.get(id);
    if (data == null) return null;
    return Task.fromJson(json.decode(data));
  }

  Future<List<Task>> getAllTasks() async {
    final box = Hive.box(_tasksBox);
    final tasks = <Task>[];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        tasks.add(Task.fromJson(json.decode(data)));
      }
    }
    return tasks;
  }

  Future<void> deleteTask(String id) async {
    final box = Hive.box(_tasksBox);
    await box.delete(id);
  }

  // App Usage
  Future<void> saveAppUsage(AppUsage usage) async {
    final box = Hive.box(_appUsageBox);
    final key = '${usage.appPackage}_${usage.timestamp.millisecondsSinceEpoch}';
    await box.put(key, json.encode(usage.toJson()));
  }

  Future<List<AppUsage>> getAppUsageHistory({DateTime? since}) async {
    final box = Hive.box(_appUsageBox);
    final usages = <AppUsage>[];

    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final usage = AppUsage.fromJson(json.decode(data));
        if (since == null || usage.timestamp.isAfter(since)) {
          usages.add(usage);
        }
      }
    }

    return usages;
  }

  // Settings
  Future<bool> isOnboardingComplete() async {
    final box = Hive.box(_settingsBox);
    return box.get('onboarding_complete', defaultValue: false);
  }

  Future<void> setOnboardingComplete(bool complete) async {
    final box = Hive.box(_settingsBox);
    await box.put('onboarding_complete', complete);
  }

  Future<bool> isLockMode() async {
    final box = Hive.box(_settingsBox);
    return box.get('lock_mode', defaultValue: false);
  }

  Future<void> setLockMode(bool locked) async {
    final box = Hive.box(_settingsBox);
    await box.put('lock_mode', locked);
  }

  Future<void> setLockEndTime(DateTime endTime) async {
    final box = Hive.box(_settingsBox);
    await box.put('lock_end_time', endTime.millisecondsSinceEpoch);
  }

  Future<DateTime?> getLockEndTime() async {
    final box = Hive.box(_settingsBox);
    final timestamp = box.get('lock_end_time');
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> clearLockEndTime() async {
    final box = Hive.box(_settingsBox);
    await box.delete('lock_end_time');
  }

  Future<String?> getGeminiApiKey() async {
    return await _secureStorage.read(key: 'gemini_api_key');
  }

  Future<void> setGeminiApiKey(String apiKey) async {
    await _secureStorage.write(key: 'gemini_api_key', value: apiKey);
  }

  // Clear all data
  Future<void> clearAllData() async {
    await Hive.box(_userProfileBox).clear();
    await Hive.box(_sessionBox).clear();
    await Hive.box(_tasksBox).clear();
    await Hive.box(_appUsageBox).clear();
    await Hive.box(_settingsBox).clear();
    await _secureStorage.deleteAll();
  }
}
