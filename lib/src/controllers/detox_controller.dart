import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/session.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class DetoxController extends ChangeNotifier {
  final _storage = StorageService();
  final _notifications = NotificationService();
  final _uuid = const Uuid();

  UserProfile? _userProfile;
  Session? _currentSession;
  bool _isLocked = false;

  UserProfile? get userProfile => _userProfile;
  Session? get currentSession => _currentSession;
  bool get isLocked => _isLocked;

  int get minutesLeft => _currentSession?.minutesLeft ?? 0;
  int get minutesUsed => _currentSession?.minutesUsed ?? 0;
  double get usagePercentage => _currentSession?.usagePercentage ?? 0.0;

  Future<void> init() async {
    await _loadUserProfile();
    await _loadOrCreateSession();
    await checkLockStatus();
  }

  Future<void> _loadUserProfile() async {
    _userProfile = await _storage.getUserProfile();
    notifyListeners();
  }

  Future<void> _loadOrCreateSession() async {
    _currentSession = await _storage.getCurrentSession();

    // Create new session if none exists or if it's a new day
    if (_currentSession == null || !_isToday(_currentSession!.startTime)) {
      await _createNewSession();
    }

    notifyListeners();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _createNewSession() async {
    if (_userProfile == null) return;

    _currentSession = Session.create(
      id: _uuid.v4(),
      dailyGoalMinutes: _userProfile!.dailyGoalMinutes,
    );

    await _storage.saveCurrentSession(_currentSession!);
    notifyListeners();
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    _userProfile = profile;
    await _storage.saveUserProfile(profile);
    notifyListeners();
  }

  Future<void> addMinutes(int minutes, String taskId) async {
    if (_currentSession == null) return;

    _currentSession = _currentSession!.copyWith(
      minutesEarned: _currentSession!.minutesEarned + minutes,
      minutesLeft: _currentSession!.minutesLeft + minutes,
      tasksCompleted: [..._currentSession!.tasksCompleted, taskId],
    );

    await _storage.saveCurrentSession(_currentSession!);

    // Unlock if was locked
    if (_isLocked && _currentSession!.minutesLeft > 0) {
      await unlockMode();
    }

    await _notifications.showTaskCompletedNotification('Task', minutes);
    notifyListeners();
  }

  Future<void> consumeMinutes(int minutes) async {
    if (_currentSession == null) return;

    _currentSession = _currentSession!.copyWith(
      minutesUsed: _currentSession!.minutesUsed + minutes,
      minutesLeft: _currentSession!.minutesLeft - minutes,
    );

    await _storage.saveCurrentSession(_currentSession!);

    // Check if should lock
    if (_currentSession!.shouldLock) {
      await lockMode();
    } else if (_currentSession!.minutesLeft <= 10) {
      await _notifications
          .showMinutesLowNotification(_currentSession!.minutesLeft);
    }

    notifyListeners();
  }

  Future<bool> checkLockStatus() async {
    final locked = await _storage.isLockMode();
    _isLocked = locked || (_currentSession?.shouldLock ?? false);
    return _isLocked;
  }

  Future<void> lockMode() async {
    _isLocked = true;
    _currentSession = _currentSession?.copyWith(isLocked: true);

    await _storage.setLockMode(true);
    await _storage.saveCurrentSession(_currentSession!);
    await _notifications.showLockModeNotification();

    notifyListeners();
  }

  /// Lock the phone for a specific number of minutes
  Future<void> lockNow(int minutes) async {
    if (_currentSession == null) return;

    // Set minutes to 0 to trigger lock, and store the lock end time
    _currentSession = _currentSession!.copyWith(
      minutesLeft: 0,
      isLocked: true,
    );

    _isLocked = true;

    // Store lock duration for countdown (optional: can be used later)
    await _storage.setLockMode(true);
    await _storage
        .setLockEndTime(DateTime.now().add(Duration(minutes: minutes)));
    await _storage.saveCurrentSession(_currentSession!);
    await _notifications.showLockModeNotification();

    notifyListeners();
  }

  /// Check if lock period has expired
  Future<bool> checkLockExpired() async {
    final lockEndTime = await _storage.getLockEndTime();
    if (lockEndTime != null && DateTime.now().isAfter(lockEndTime)) {
      await unlockMode();
      return true;
    }
    return false;
  }

  Future<void> unlockMode() async {
    _isLocked = false;
    _currentSession = _currentSession?.copyWith(isLocked: false);

    await _storage.setLockMode(false);
    await _storage.saveCurrentSession(_currentSession!);
    await _notifications.cancel(2); // Cancel lock mode notification

    notifyListeners();
  }

  Future<void> useGoldPass() async {
    if (_userProfile == null) return;

    final passes = _userProfile!.passes;
    if (passes.goldRemaining <= 0) return;

    // Gold pass unlocks for the whole month
    final updatedPasses = passes.copyWith(
      goldUsed: passes.goldUsed + 1,
    );

    _userProfile = _userProfile!.copyWith(passes: updatedPasses);
    await _storage.saveUserProfile(_userProfile!);

    // Add significant minutes (e.g., 1440 minutes = 24 hours)
    await addMinutes(1440, 'gold_pass');

    notifyListeners();
  }

  Future<void> useSilverPass() async {
    if (_userProfile == null) return;

    final passes = _userProfile!.passes;
    if (passes.silverRemaining <= 0) return;

    final updatedPasses = passes.copyWith(
      silverUsed: passes.silverUsed + 1,
    );

    _userProfile = _userProfile!.copyWith(passes: updatedPasses);
    await _storage.saveUserProfile(_userProfile!);

    // Silver pass gives 10 minutes
    await addMinutes(10, 'silver_pass');

    notifyListeners();
  }

  Future<void> useGreyPass() async {
    if (_userProfile == null) return;

    final passes = _userProfile!.passes;
    if (passes.greyRemaining <= 0) return;

    final updatedPasses = passes.copyWith(
      greyUsed: passes.greyUsed + 1,
    );

    _userProfile = _userProfile!.copyWith(passes: updatedPasses);
    await _storage.saveUserProfile(_userProfile!);

    // Grey pass gives 2 minutes
    await addMinutes(2, 'grey_pass');

    notifyListeners();
  }

  Future<void> resetMonthlyPasses() async {
    if (_userProfile == null) return;

    final now = DateTime.now();
    final monthStart = _userProfile!.passes.monthStart;

    // Check if it's a new month
    if (now.month != monthStart.month || now.year != monthStart.year) {
      final newPasses = PassAllocation.initial();
      _userProfile = _userProfile!.copyWith(passes: newPasses);
      await _storage.saveUserProfile(_userProfile!);
      notifyListeners();
    }
  }
}
