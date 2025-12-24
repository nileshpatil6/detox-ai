import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/storage_service.dart';
import 'dart:math' as math;

class TaskController extends ChangeNotifier {
  final _storage = StorageService();
  final _uuid = const Uuid();
  final _random = math.Random();

  List<Task> _activeTasks = [];
  List<Task> _completedTasks = [];

  List<Task> get activeTasks => _activeTasks;
  List<Task> get completedTasks => _completedTasks;

  Future<void> init() async {
    await loadTasks();
    if (_activeTasks.isEmpty) {
      await generateDynamicTasks();
    }
  }

  Future<void> loadTasks() async {
    final allTasks = await _storage.getAllTasks();
    _activeTasks = allTasks
        .where((task) =>
            task.status == TaskStatus.pending ||
            task.status == TaskStatus.inProgress,)
        .toList();

    _completedTasks = allTasks
        .where((task) => task.status == TaskStatus.completed)
        .toList();

    notifyListeners();
  }

  Future<void> generateDynamicTasks({int count = 5}) async {
    final taskGenerators = [
      () => Task.walking(id: _uuid.v4(), stepsRequired: 1000 + _random.nextInt(4000)),
      () => Task.touchGrass(id: _uuid.v4()),
      () => Task.readBook(id: _uuid.v4()),
      () => Task.creativeDrawing(id: _uuid.v4()),
      () => Task.plantPlant(id: _uuid.v4()),
    ];

    // Shuffle and pick tasks
    taskGenerators.shuffle(_random);

    final tasksToCreate = taskGenerators.take(count).map((generator) => generator()).toList();

    for (var task in tasksToCreate) {
      await _storage.saveTask(task);
      _activeTasks.add(task);
    }

    notifyListeners();
  }

  Future<void> startTask(String taskId) async {
    final index = _activeTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _activeTasks[index].copyWith(
      status: TaskStatus.inProgress,
    );

    _activeTasks[index] = task;
    await _storage.saveTask(task);
    notifyListeners();
  }

  Future<void> completeTask(
    String taskId, {
    VerificationResult? verificationResult,
  }) async {
    final index = _activeTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _activeTasks[index].copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
      verificationResult: verificationResult,
    );

    _activeTasks.removeAt(index);
    _completedTasks.insert(0, task);

    await _storage.saveTask(task);
    notifyListeners();
  }

  Future<void> failTask(String taskId, {String? reason}) async {
    final index = _activeTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _activeTasks[index].copyWith(
      status: TaskStatus.failed,
      verificationResult: VerificationResult(
        verified: false,
        confidence: 0.0,
        reason: reason,
        verifiedAt: DateTime.now(),
      ),
    );

    _activeTasks[index] = task;
    await _storage.saveTask(task);
    notifyListeners();
  }

  Future<void> rejectTask(String taskId, {String? reason}) async {
    final index = _activeTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _activeTasks[index].copyWith(
      status: TaskStatus.rejected,
      verificationResult: VerificationResult(
        verified: false,
        confidence: 0.0,
        reason: reason ?? 'Task rejected',
        verifiedAt: DateTime.now(),
      ),
    );

    _activeTasks.removeAt(index);
    await _storage.saveTask(task);

    // Generate a new task to replace the rejected one
    await generateDynamicTasks(count: 1);
    notifyListeners();
  }

  Task? getTask(String taskId) {
    try {
      return _activeTasks.firstWhere((t) => t.id == taskId);
    } catch (e) {
      try {
        return _completedTasks.firstWhere((t) => t.id == taskId);
      } catch (e) {
        return null;
      }
    }
  }

  int getTotalMinutesEarned() {
    return _completedTasks
        .where((task) => task.verificationResult?.verified ?? false)
        .fold(0, (sum, task) => sum + task.minutesReward);
  }

  void clear() {
    _activeTasks.clear();
    _completedTasks.clear();
    notifyListeners();
  }
}
