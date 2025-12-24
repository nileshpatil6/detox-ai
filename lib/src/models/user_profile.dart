import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final int dailyGoalMinutes;
  final int weeklyGoalMinutes;
  final List<String> allowedApps;
  final List<String> focusHours; // e.g., ["09:00-12:00", "14:00-17:00"]
  final String motivationText;
  final PassAllocation passes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.dailyGoalMinutes,
    required this.weeklyGoalMinutes,
    required this.allowedApps,
    required this.focusHours,
    required this.motivationText,
    required this.passes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.create({
    required String id,
    required int dailyGoalMinutes,
    required int weeklyGoalMinutes,
    required List<String> allowedApps,
    required List<String> focusHours,
    required String motivationText,
  }) {
    return UserProfile(
      id: id,
      dailyGoalMinutes: dailyGoalMinutes,
      weeklyGoalMinutes: weeklyGoalMinutes,
      allowedApps: allowedApps,
      focusHours: focusHours,
      motivationText: motivationText,
      passes: PassAllocation.initial(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dailyGoalMinutes': dailyGoalMinutes,
      'weeklyGoalMinutes': weeklyGoalMinutes,
      'allowedApps': allowedApps,
      'focusHours': focusHours,
      'motivationText': motivationText,
      'passes': passes.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      dailyGoalMinutes: json['dailyGoalMinutes'] as int,
      weeklyGoalMinutes: json['weeklyGoalMinutes'] as int,
      allowedApps: List<String>.from(json['allowedApps'] as List),
      focusHours: List<String>.from(json['focusHours'] as List),
      motivationText: json['motivationText'] as String,
      passes: PassAllocation.fromJson(json['passes'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  UserProfile copyWith({
    String? id,
    int? dailyGoalMinutes,
    int? weeklyGoalMinutes,
    List<String>? allowedApps,
    List<String>? focusHours,
    String? motivationText,
    PassAllocation? passes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      weeklyGoalMinutes: weeklyGoalMinutes ?? this.weeklyGoalMinutes,
      allowedApps: allowedApps ?? this.allowedApps,
      focusHours: focusHours ?? this.focusHours,
      motivationText: motivationText ?? this.motivationText,
      passes: passes ?? this.passes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        dailyGoalMinutes,
        weeklyGoalMinutes,
        allowedApps,
        focusHours,
        motivationText,
        passes,
        createdAt,
        updatedAt,
      ];
}

class PassAllocation extends Equatable {
  final int goldUsed;
  final int silverUsed;
  final int greyUsed;
  final int goldTotal;
  final int silverTotal;
  final int greyTotal;
  final DateTime monthStart;

  const PassAllocation({
    required this.goldUsed,
    required this.silverUsed,
    required this.greyUsed,
    required this.goldTotal,
    required this.silverTotal,
    required this.greyTotal,
    required this.monthStart,
  });

  factory PassAllocation.initial() {
    return PassAllocation(
      goldUsed: 0,
      silverUsed: 0,
      greyUsed: 0,
      goldTotal: 2,
      silverTotal: 3,
      greyTotal: 5,
      monthStart: DateTime.now(),
    );
  }

  int get goldRemaining => goldTotal - goldUsed;
  int get silverRemaining => silverTotal - silverUsed;
  int get greyRemaining => greyTotal - greyUsed;

  Map<String, dynamic> toJson() {
    return {
      'goldUsed': goldUsed,
      'silverUsed': silverUsed,
      'greyUsed': greyUsed,
      'goldTotal': goldTotal,
      'silverTotal': silverTotal,
      'greyTotal': greyTotal,
      'monthStart': monthStart.toIso8601String(),
    };
  }

  factory PassAllocation.fromJson(Map<String, dynamic> json) {
    return PassAllocation(
      goldUsed: json['goldUsed'] as int,
      silverUsed: json['silverUsed'] as int,
      greyUsed: json['greyUsed'] as int,
      goldTotal: json['goldTotal'] as int,
      silverTotal: json['silverTotal'] as int,
      greyTotal: json['greyTotal'] as int,
      monthStart: DateTime.parse(json['monthStart'] as String),
    );
  }

  PassAllocation copyWith({
    int? goldUsed,
    int? silverUsed,
    int? greyUsed,
    int? goldTotal,
    int? silverTotal,
    int? greyTotal,
    DateTime? monthStart,
  }) {
    return PassAllocation(
      goldUsed: goldUsed ?? this.goldUsed,
      silverUsed: silverUsed ?? this.silverUsed,
      greyUsed: greyUsed ?? this.greyUsed,
      goldTotal: goldTotal ?? this.goldTotal,
      silverTotal: silverTotal ?? this.silverTotal,
      greyTotal: greyTotal ?? this.greyTotal,
      monthStart: monthStart ?? this.monthStart,
    );
  }

  @override
  List<Object?> get props => [
        goldUsed,
        silverUsed,
        greyUsed,
        goldTotal,
        silverTotal,
        greyTotal,
        monthStart,
      ];
}
