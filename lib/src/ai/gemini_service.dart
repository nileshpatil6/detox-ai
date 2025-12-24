import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/task.dart';
import '../services/storage_service.dart';

class GeminiService {
  final _storage = StorageService();
  GenerativeModel? _model;

  // Using provided API key
  static const String _apiKey = 'YOUR_API_KEY';

  // Singleton instance
  static final GeminiService _instance = GeminiService._internal();

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal();

  static const String _modelName = 'gemini-2.5-flash';

  Future<void> init() async {
    // using the static key directly
    _model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
    );
  }

  bool get isInitialized => _model != null;

  Future<void> setApiKey(String apiKey) async {
    // No-op for now as we hardcode
  }

  /// Verify a photo task (e.g., touching grass, planting)
  Future<VerificationResult> verifyPhotoTask({
    required String imagePath,
    required String taskType,
    String? additionalContext,
  }) async {
    if (!isInitialized) {
      throw Exception('Gemini service not initialized. Please set API key.');
    }

    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();

      final prompt = _buildPromptForTaskType(taskType, additionalContext);

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await _model!.generateContent(content);
      final text = response.text ?? '';

      return _parseVerificationResponse(text);
    } catch (e) {
      return VerificationResult(
        verified: false,
        confidence: 0.0,
        reason: 'Error during verification: ${e.toString()}',
        verifiedAt: DateTime.now(),
      );
    }
  }

  /// Verify a book reading task with OCR and comprehension questions
  Future<VerificationResult> verifyReadingTask({
    required String imagePath,
  }) async {
    if (!isInitialized) {
      throw Exception('Gemini service not initialized. Please set API key.');
    }

    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();

      const prompt = '''
Analyze this image and determine if it shows a page from a book or printed text.

If it is a book page:
1. Extract the text from the page
2. Generate 2 simple comprehension questions based on the text
3. Return in this format:
VERIFIED: YES
TEXT: [extracted text]
QUESTION1: [question 1]
QUESTION2: [question 2]

If it is NOT a book page:
VERIFIED: NO
REASON: [explanation]
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await _model!.generateContent(content);
      final text = response.text ?? '';

      return _parseReadingVerificationResponse(text);
    } catch (e) {
      return VerificationResult(
        verified: false,
        confidence: 0.0,
        reason: 'Error during reading verification: ${e.toString()}',
        verifiedAt: DateTime.now(),
      );
    }
  }

  /// Verify answers to reading comprehension questions
  Future<bool> verifyReadingAnswers({
    required String extractedText,
    required List<String> questions,
    required List<String> userAnswers,
  }) async {
    if (!isInitialized) return false;

    try {
      final prompt = '''
Given this text:
$extractedText

And these question-answer pairs:
${_formatQAPairs(questions, userAnswers)}

Evaluate if the answers are reasonable and demonstrate comprehension.
Respond with just "CORRECT" or "INCORRECT".
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      return text.toUpperCase().contains('CORRECT');
    } catch (e) {
      return false;
    }
  }

  /// Verify a video task (e.g., planting, exercise)
  Future<VerificationResult> verifyVideoTask({
    required String videoPath,
    required String taskType,
  }) async {
    if (!isInitialized) {
      throw Exception('Gemini service not initialized. Please set API key.');
    }

    try {
      final videoFile = File(videoPath);
      final videoBytes = await videoFile.readAsBytes();

      final prompt = _buildPromptForTaskType(taskType, null);

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('video/mp4', videoBytes),
        ]),
      ];

      final response = await _model!.generateContent(content);
      final text = response.text ?? '';

      return _parseVerificationResponse(text);
    } catch (e) {
      return VerificationResult(
        verified: false,
        confidence: 0.0,
        reason: 'Error during video verification: ${e.toString()}',
        verifiedAt: DateTime.now(),
      );
    }
  }

  String _buildPromptForTaskType(String taskType, String? additionalContext) {
    final context = additionalContext ?? '';

    switch (taskType) {
      case 'grass':
        return '''
Analyze this image and determine if it shows a person touching real grass outdoors.

Requirements:
- Must show actual grass (green, natural)
- Must show a hand or person touching/near the grass
- Must appear to be outdoors

Respond in this format:
VERIFIED: YES or NO
CONFIDENCE: 0.0 to 1.0
REASON: [brief explanation]

$context
''';

      case 'plant':
        return '''
Analyze this image/video and determine if it shows someone planting a plant.

Requirements:
- Must show a plant or seedling
- Must show planting activity (digging, placing plant in soil, etc.)
- Must appear genuine

Respond in this format:
VERIFIED: YES or NO
CONFIDENCE: 0.0 to 1.0
REASON: [brief explanation]

$context
''';

      case 'drawing':
        return '''
Analyze this image and determine if it shows an original hand-drawn artwork.

Requirements:
- Must show clear evidence of drawing/sketching
- Should appear hand-made (not digital or printed)
- Should show creative effort

Respond in this format:
VERIFIED: YES or NO
CONFIDENCE: 0.0 to 1.0
REASON: [brief explanation]

$context
''';

      default:
        return '''
Analyze this image and verify if it meets the task requirements.

Task type: $taskType
$context

Respond in this format:
VERIFIED: YES or NO
CONFIDENCE: 0.0 to 1.0
REASON: [brief explanation]
''';
    }
  }

  VerificationResult _parseVerificationResponse(String response) {
    final lines = response.split('\n');
    bool verified = false;
    double confidence = 0.0;
    String? reason;

    for (var line in lines) {
      if (line.toUpperCase().contains('VERIFIED:')) {
        verified = line.toUpperCase().contains('YES');
      } else if (line.toUpperCase().contains('CONFIDENCE:')) {
        final parts = line.split(':');
        if (parts.length > 1) {
          confidence = double.tryParse(parts[1].trim()) ?? 0.0;
        }
      } else if (line.toUpperCase().contains('REASON:')) {
        reason = line.substring(line.indexOf(':') + 1).trim();
      }
    }

    return VerificationResult(
      verified: verified,
      confidence: confidence,
      reason: reason,
      verifiedAt: DateTime.now(),
    );
  }

  VerificationResult _parseReadingVerificationResponse(String response) {
    final lines = response.split('\n');
    bool verified = false;
    String? extractedText;
    List<String> questions = [];

    for (var line in lines) {
      if (line.toUpperCase().contains('VERIFIED:')) {
        verified = line.toUpperCase().contains('YES');
      } else if (line.toUpperCase().contains('TEXT:')) {
        extractedText = line.substring(line.indexOf(':') + 1).trim();
      } else if (line.toUpperCase().contains('QUESTION1:')) {
        questions.add(line.substring(line.indexOf(':') + 1).trim());
      } else if (line.toUpperCase().contains('QUESTION2:')) {
        questions.add(line.substring(line.indexOf(':') + 1).trim());
      }
    }

    return VerificationResult(
      verified: verified,
      confidence: verified ? 0.9 : 0.0,
      extractedText: extractedText,
      questions: questions,
      verifiedAt: DateTime.now(),
    );
  }

  String _formatQAPairs(List<String> questions, List<String> answers) {
    final buffer = StringBuffer();
    for (int i = 0; i < questions.length && i < answers.length; i++) {
      buffer.writeln('Q${i + 1}: ${questions[i]}');
      buffer.writeln('A${i + 1}: ${answers[i]}');
      buffer.writeln();
    }
    return buffer.toString();
  }
}
