import 'package:equatable/equatable.dart';

enum TaskType {
  walking,
  photoVerification,
  reading,
  creative,
  videoVerification,
}

enum TaskStatus {
  pending,
  inProgress,
  completed,
  failed,
  rejected,
}

class Task extends Equatable {
  final String id;
  final TaskType type;
  final String title;
  final String description;
  final int minutesReward;
  final int stepsRequired; // For walking tasks
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final VerificationResult? verificationResult;
  final Map<String, dynamic> metadata;

  const Task({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.minutesReward,
    this.stepsRequired = 0,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.verificationResult,
    this.metadata = const {},
  });

  factory Task.walking({
    required String id,
    required int stepsRequired,
  }) {
    return Task(
      id: id,
      type: TaskType.walking,
      title: 'Take a Walk',
      description: 'Walk $stepsRequired steps to earn ${(stepsRequired / 10).round()} minutes',
      minutesReward: (stepsRequired / 10).round(),
      stepsRequired: stepsRequired,
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  factory Task.touchGrass({required String id}) {
    return Task(
      id: id,
      type: TaskType.photoVerification,
      title: 'Touch Grass',
      description: 'Take a photo of yourself touching grass outdoors',
      minutesReward: 15,
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      metadata: const {'verificationType': 'grass'},
    );
  }

  factory Task.plantPlant({required String id}) {
    return Task(
      id: id,
      type: TaskType.videoVerification,
      title: 'Plant Something',
      description: 'Record a video of yourself planting a plant',
      minutesReward: 60,
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      metadata: const {'verificationType': 'plant'},
    );
  }

  factory Task.readBook({required String id}) {
    return Task(
      id: id,
      type: TaskType.reading,
      title: 'Read a Book',
      description: 'Take a photo of a book page and answer questions',
      minutesReward: 20,
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      metadata: const {'verificationType': 'book'},
    );
  }

  factory Task.creativeDrawing({required String id}) {
    return Task(
      id: id,
      type: TaskType.creative,
      title: 'Draw Something',
      description: 'Create a drawing and take a photo',
      minutesReward: 10,
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      metadata: const {'verificationType': 'drawing'},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'minutesReward': minutesReward,
      'stepsRequired': stepsRequired,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'verificationResult': verificationResult?.toJson(),
      'metadata': metadata,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      type: TaskType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      minutesReward: json['minutesReward'] as int,
      stepsRequired: json['stepsRequired'] as int? ?? 0,
      status: TaskStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      verificationResult: json['verificationResult'] != null
          ? VerificationResult.fromJson(
              json['verificationResult'] as Map<String, dynamic>,)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Task copyWith({
    String? id,
    TaskType? type,
    String? title,
    String? description,
    int? minutesReward,
    int? stepsRequired,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    VerificationResult? verificationResult,
    Map<String, dynamic>? metadata,
  }) {
    return Task(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      minutesReward: minutesReward ?? this.minutesReward,
      stepsRequired: stepsRequired ?? this.stepsRequired,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      verificationResult: verificationResult ?? this.verificationResult,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        description,
        minutesReward,
        stepsRequired,
        status,
        createdAt,
        completedAt,
        verificationResult,
        metadata,
      ];
}

class VerificationResult extends Equatable {
  final bool verified;
  final double confidence;
  final String? reason;
  final List<String>? questions;
  final List<String>? userAnswers;
  final String? extractedText;
  final DateTime verifiedAt;

  const VerificationResult({
    required this.verified,
    required this.confidence,
    this.reason,
    this.questions,
    this.userAnswers,
    this.extractedText,
    required this.verifiedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'verified': verified,
      'confidence': confidence,
      'reason': reason,
      'questions': questions,
      'userAnswers': userAnswers,
      'extractedText': extractedText,
      'verifiedAt': verifiedAt.toIso8601String(),
    };
  }

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      verified: json['verified'] as bool,
      confidence: (json['confidence'] as num).toDouble(),
      reason: json['reason'] as String?,
      questions: json['questions'] != null
          ? List<String>.from(json['questions'] as List)
          : null,
      userAnswers: json['userAnswers'] != null
          ? List<String>.from(json['userAnswers'] as List)
          : null,
      extractedText: json['extractedText'] as String?,
      verifiedAt: DateTime.parse(json['verifiedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        verified,
        confidence,
        reason,
        questions,
        userAnswers,
        extractedText,
        verifiedAt,
      ];
}
