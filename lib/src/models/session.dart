import 'package:equatable/equatable.dart';

class Session extends Equatable {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int minutesUsed;
  final int minutesEarned;
  final int minutesLeft;
  final int dailyGoalMinutes;
  final bool isLocked;
  final List<String> tasksCompleted;

  const Session({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.minutesUsed,
    required this.minutesEarned,
    required this.minutesLeft,
    required this.dailyGoalMinutes,
    required this.isLocked,
    this.tasksCompleted = const [],
  });

  factory Session.create({
    required String id,
    required int dailyGoalMinutes,
  }) {
    return Session(
      id: id,
      startTime: DateTime.now(),
      minutesUsed: 0,
      minutesEarned: 0,
      minutesLeft: dailyGoalMinutes,
      dailyGoalMinutes: dailyGoalMinutes,
      isLocked: false,
    );
  }

  double get usagePercentage => minutesUsed / dailyGoalMinutes;

  bool get shouldLock => minutesLeft <= 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'minutesUsed': minutesUsed,
      'minutesEarned': minutesEarned,
      'minutesLeft': minutesLeft,
      'dailyGoalMinutes': dailyGoalMinutes,
      'isLocked': isLocked,
      'tasksCompleted': tasksCompleted,
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      minutesUsed: json['minutesUsed'] as int,
      minutesEarned: json['minutesEarned'] as int,
      minutesLeft: json['minutesLeft'] as int,
      dailyGoalMinutes: json['dailyGoalMinutes'] as int,
      isLocked: json['isLocked'] as bool,
      tasksCompleted: List<String>.from(json['tasksCompleted'] as List? ?? []),
    );
  }

  Session copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? minutesUsed,
    int? minutesEarned,
    int? minutesLeft,
    int? dailyGoalMinutes,
    bool? isLocked,
    List<String>? tasksCompleted,
  }) {
    return Session(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      minutesUsed: minutesUsed ?? this.minutesUsed,
      minutesEarned: minutesEarned ?? this.minutesEarned,
      minutesLeft: minutesLeft ?? this.minutesLeft,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      isLocked: isLocked ?? this.isLocked,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        startTime,
        endTime,
        minutesUsed,
        minutesEarned,
        minutesLeft,
        dailyGoalMinutes,
        isLocked,
        tasksCompleted,
      ];
}

class AppUsage extends Equatable {
  final String appPackage;
  final String appName;
  final int timeInForegroundMs;
  final DateTime timestamp;
  final bool isAllowed;

  const AppUsage({
    required this.appPackage,
    required this.appName,
    required this.timeInForegroundMs,
    required this.timestamp,
    required this.isAllowed,
  });

  int get timeInMinutes => (timeInForegroundMs / 60000).round();

  Map<String, dynamic> toJson() {
    return {
      'appPackage': appPackage,
      'appName': appName,
      'timeInForegroundMs': timeInForegroundMs,
      'timestamp': timestamp.toIso8601String(),
      'isAllowed': isAllowed,
    };
  }

  factory AppUsage.fromJson(Map<String, dynamic> json) {
    return AppUsage(
      appPackage: json['appPackage'] as String,
      appName: json['appName'] as String,
      timeInForegroundMs: json['timeInForegroundMs'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isAllowed: json['isAllowed'] as bool,
    );
  }

  @override
  List<Object?> get props => [
        appPackage,
        appName,
        timeInForegroundMs,
        timestamp,
        isAllowed,
      ];
}
