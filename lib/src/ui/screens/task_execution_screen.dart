import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/task.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/detox_controller.dart';
import '../../ai/gemini_service.dart';
import '../theme/app_theme.dart';

class TaskExecutionScreen extends StatefulWidget {
  final Task task;

  const TaskExecutionScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskExecutionScreen> createState() => _TaskExecutionScreenState();
}

class _TaskExecutionScreenState extends State<TaskExecutionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _capturedFilePath;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('No camera available');
        return;
      }

      _cameraController = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: widget.task.type == TaskType.videoVerification,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _showError('Failed to initialize camera: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        title: Text(widget.task.title),
        backgroundColor: AppTheme.primaryBlack,
      ),
      body: _isInitialized
          ? _buildCameraView()
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }

  Widget _buildCameraView() {
    if (_capturedFilePath != null) {
      return _buildPreviewView();
    }

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),

        // Top info overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.title,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.task.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Reward: +${widget.task.minutesReward} minutes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.task.type == TaskType.videoVerification) ...[
                  // Video recording button
                  GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isRecording ? Colors.red : Colors.transparent,
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.videocam,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ] else ...[
                  // Photo capture button
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const Icon(
                        Icons.camera,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Processing overlay
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewView() {
    final isVideo = widget.task.type == TaskType.videoVerification;

    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: isVideo
                  ? const Icon(Icons.video_library, size: 100, color: Colors.white)
                  : Image.file(File(_capturedFilePath!)),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.softGrey,
          child: Column(
            children: [
              Text(
                'Review your ${isVideo ? 'video' : 'photo'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _capturedFilePath = null;
                        });
                      },
                      child: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _submitTask,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _capturePhoto() async {
    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final image = await _cameraController!.takePicture();
      await image.saveTo(path);

      setState(() {
        _capturedFilePath = path;
      });
    } catch (e) {
      _showError('Failed to capture photo: ${e.toString()}');
    }
  }

  Future<void> _startRecording() async {
    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      _showError('Failed to start recording: ${e.toString()}');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final video = await _cameraController!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _capturedFilePath = video.path;
      });
    } catch (e) {
      _showError('Failed to stop recording: ${e.toString()}');
    }
  }

  Future<void> _submitTask() async {
    if (_capturedFilePath == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final geminiService = GeminiService();
      await geminiService.init();

      VerificationResult? verificationResult;

      if (widget.task.type == TaskType.videoVerification) {
        verificationResult = await geminiService.verifyVideoTask(
          videoPath: _capturedFilePath!,
          taskType: widget.task.metadata['verificationType'] ?? 'video',
        );
      } else if (widget.task.type == TaskType.reading) {
        // For reading tasks, go to Q&A screen
        verificationResult = await geminiService.verifyReadingTask(
          imagePath: _capturedFilePath!,
        );

        if (verificationResult.verified && verificationResult.questions != null) {
          // Navigate to Q&A screen
          if (mounted) {
            final answers = await Navigator.push<List<String>>(
              context,
              MaterialPageRoute(
                builder: (context) => ReadingQAScreen(
                  extractedText: verificationResult!.extractedText ?? '',
                  questions: verificationResult.questions ?? [],
                ),
              ),
            );

            if (answers != null) {
              final answersCorrect = await geminiService.verifyReadingAnswers(
                extractedText: verificationResult.extractedText ?? '',
                questions: verificationResult.questions ?? [],
                userAnswers: answers,
              );

              verificationResult = verificationResult.copyWith(
                verified: answersCorrect,
                userAnswers: answers,
              );
            } else {
              // User cancelled
              setState(() {
                _isProcessing = false;
              });
              return;
            }
          }
        }
      } else {
        verificationResult = await geminiService.verifyPhotoTask(
          imagePath: _capturedFilePath!,
          taskType: widget.task.metadata['verificationType'] ?? 'photo',
        );
      }

      if (!mounted) return;

      final taskController = context.read<TaskController>();
      final detoxController = context.read<DetoxController>();

      if (verificationResult.verified) {
        // Task verified successfully
        await taskController.completeTask(
          widget.task.id,
          verificationResult: verificationResult,
        );

        await detoxController.addMinutes(
          widget.task.minutesReward,
          widget.task.id,
        );

        if (mounted) {
          _showSuccess(
            'Task completed! You earned ${widget.task.minutesReward} minutes.',
          );
          Navigator.pop(context);
        }
      } else {
        // Task failed verification
        await taskController.rejectTask(
          widget.task.id,
          reason: verificationResult.reason,
        );

        if (mounted) {
          _showError(
            'Verification failed: ${verificationResult.reason ?? "Please try again"}',
          );
        }
      }
    } catch (e) {
      _showError('Error submitting task: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Extension to add copyWith for VerificationResult
extension VerificationResultExtension on VerificationResult {
  VerificationResult copyWith({
    bool? verified,
    double? confidence,
    String? reason,
    List<String>? questions,
    List<String>? userAnswers,
    String? extractedText,
    DateTime? verifiedAt,
  }) {
    return VerificationResult(
      verified: verified ?? this.verified,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
      questions: questions ?? this.questions,
      userAnswers: userAnswers ?? this.userAnswers,
      extractedText: extractedText ?? this.extractedText,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}

class ReadingQAScreen extends StatefulWidget {
  final String extractedText;
  final List<String> questions;

  const ReadingQAScreen({
    super.key,
    required this.extractedText,
    required this.questions,
  });

  @override
  State<ReadingQAScreen> createState() => _ReadingQAScreenState();
}

class _ReadingQAScreenState extends State<ReadingQAScreen> {
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.questions.length; i++) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        title: const Text('Answer Questions'),
        backgroundColor: AppTheme.primaryBlack,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.softUICard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Extracted Text:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.extractedText,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Comprehension Questions:',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            ...List.generate(widget.questions.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${index + 1}: ${widget.questions[index]}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controllers[index],
                      decoration: const InputDecoration(
                        hintText: 'Your answer...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitAnswers,
                child: const Text('Submit Answers'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitAnswers() {
    final answers = _controllers.map((c) => c.text.trim()).toList();

    // Check if all answers are provided
    if (answers.any((answer) => answer.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context, answers);
  }
}
