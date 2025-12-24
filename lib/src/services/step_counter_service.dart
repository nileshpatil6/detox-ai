import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';

class StepCounterService extends ChangeNotifier {
  final _storage = StorageService();

  Stream<StepCount>? _stepCountStream;
  StreamSubscription<StepCount>? _stepCountSubscription;

  int _totalSteps = 0;
  int _sessionStartSteps = 0;
  int _sessionSteps = 0;
  bool _isTracking = false;

  int get totalSteps => _totalSteps;
  int get sessionSteps => _sessionSteps;
  bool get isTracking => _isTracking;

  Future<void> init() async {
    await _loadSavedSteps();
  }

  Future<void> _loadSavedSteps() async {
    // Load saved step count from storage
    // This helps maintain continuity across app restarts
    _totalSteps = 0; // Would load from storage in production
  }

  Future<bool> requestPermission() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  Future<void> startTracking() async {
    if (_isTracking) return;

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('Activity recognition permission not granted');
    }

    try {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountSubscription = _stepCountStream!.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      _isTracking = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting step counter: $e');
      throw Exception('Failed to start step counter: $e');
    }
  }

  void _onStepCount(StepCount event) {
    if (_sessionStartSteps == 0) {
      _sessionStartSteps = event.steps;
    }

    _totalSteps = event.steps;
    _sessionSteps = _totalSteps - _sessionStartSteps;

    notifyListeners();
  }

  void _onStepCountError(dynamic error) {
    debugPrint('Step counter error: $error');
    // Handle error gracefully - maybe show notification to user
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;

    await _stepCountSubscription?.cancel();
    _stepCountSubscription = null;
    _isTracking = false;

    notifyListeners();
  }

  void resetSession() {
    _sessionStartSteps = _totalSteps;
    _sessionSteps = 0;
    notifyListeners();
  }

  int calculateMinutesFromSteps(int steps) {
    // Default: 10 steps = 1 minute
    // Can be made configurable per user profile
    return (steps / 10).floor();
  }

  Future<void> saveProgress() async {
    // Save current step count to storage
    // This would persist across app restarts
    // Implementation depends on storage strategy
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

class WalkingTaskTracker {
  final StepCounterService _stepService;
  final int _targetSteps;
  final Function(int minutesEarned) _onComplete;

  int _startSteps = 0;
  StreamSubscription? _subscription;

  WalkingTaskTracker({
    required StepCounterService stepService,
    required int targetSteps,
    required Function(int minutesEarned) onComplete,
  })  : _stepService = stepService,
        _targetSteps = targetSteps,
        _onComplete = onComplete;

  void start() {
    _startSteps = _stepService.sessionSteps;
    _subscription = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      _checkProgress();
    });
  }

  void _checkProgress() {
    final currentSteps = _stepService.sessionSteps;
    final stepsWalked = currentSteps - _startSteps;

    if (stepsWalked >= _targetSteps) {
      final minutesEarned = _stepService.calculateMinutesFromSteps(stepsWalked);
      _onComplete(minutesEarned);
      stop();
    }
  }

  int getProgress() {
    final currentSteps = _stepService.sessionSteps;
    final stepsWalked = currentSteps - _startSteps;
    return ((stepsWalked / _targetSteps) * 100).clamp(0, 100).toInt();
  }

  int getStepsRemaining() {
    final currentSteps = _stepService.sessionSteps;
    final stepsWalked = currentSteps - _startSteps;
    return (_targetSteps - stepsWalked).clamp(0, _targetSteps);
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
