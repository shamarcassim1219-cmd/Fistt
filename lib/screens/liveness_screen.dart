import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../main.dart';

enum _Challenge { blink, smile, turn }

/// Live face check. The user must complete 3 random actions
/// (blink / smile / turn head), then a selfie is captured.
/// Pops with the selfie file path when successful, or null if cancelled.
class LivenessScreen extends StatefulWidget {
  final String title;
  const LivenessScreen({super.key, this.title = 'Face Liveness'});

  @override
  State<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends State<LivenessScreen> {
  CameraController? _controller;
  CameraDescription? _camera;
  late final FaceDetector _detector;

  bool _initializing = true;
  String? _error;
  bool _busy = false;
  bool _done = false;
  bool _capturing = false;
  DateTime _lastProcessed = DateTime.fromMillisecondsSinceEpoch(0);

  late List<_Challenge> _challenges;
  int _index = 0;
  bool _finalStage = false; // look straight + capture
  int _stableFrames = 0;

  // blink state
  bool _eyesWereOpen = false;
  bool _eyesClosed = false;

  Timer? _timeout;

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  bool _webCountdownStarted = false;
  int _webSecondsLeft = 3;

  @override
  void initState() {
    super.initState();
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.3,
      ),
    );
    _resetChallenges();
    _initCamera();
  }

  void _startWebCountdown() {
    if (_webCountdownStarted) return;
    _webCountdownStarted = true;
    _webSecondsLeft = 3;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _done) {
        timer.cancel();
        return;
      }
      setState(() => _webSecondsLeft--);
      if (_webSecondsLeft <= 0) {
        timer.cancel();
        _capture();
      }
    });
  }

  void _resetChallenges() {
    _challenges = List.of(_Challenge.values)..shuffle(Random.secure());
    _index = 0;
    _finalStage = false;
    _stableFrames = 0;
    _eyesWereOpen = false;
    _eyesClosed = false;
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      _camera = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      final controller = CameraController(
        _camera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await controller.initialize();
      try {
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } catch (_) {}
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      setState(() => _initializing = false);
      if (kIsWeb) {
        _startWebCountdown();
      } else {
        _startStream();
      }
      _startTimeout();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Could not open the camera. Please allow camera permission and try again.';
      });
    }
  }

  void _startTimeout() {
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 60), () {
      if (!mounted || _done) return;
      _stopStream();
      setState(() => _error = 'Time is up. Please try again.');
    });
  }

  void _startStream() {
    final c = _controller;
    if (c == null || c.value.isStreamingImages) return;
    c.startImageStream(_onFrame);
  }

  Future<void> _stopStream() async {
    final c = _controller;
    if (c != null && c.value.isStreamingImages) {
      try {
        await c.stopImageStream();
      } catch (_) {}
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _camera;
    final controller = _controller;
    if (camera == null || controller == null) return null;

    var rotationCompensation = _orientations[controller.value.deviceOrientation];
    if (rotationCompensation == null) return null;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (camera.sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationCompensation = (camera.sensorOrientation - rotationCompensation + 360) % 360;
    }
    final rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format != InputImageFormat.nv21) return null;
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format!,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy || _done || _capturing || _error != null) return;
    final now = DateTime.now();
    if (now.difference(_lastProcessed).inMilliseconds < 120) return;
    _lastProcessed = now;
    _busy = true;
    try {
      final input = _toInputImage(image);
      if (input == null) return;
      final faces = await _detector.processImage(input);
      if (!mounted || _done) return;
      if (faces.length != 1) {
        _stableFrames = 0;
        if (mounted) setState(() {});
        return;
      }
      _evaluate(faces.first);
    } catch (_) {
      // ignore single-frame failures
    } finally {
      _busy = false;
    }
  }

  void _evaluate(Face face) {
    final yaw = face.headEulerAngleY ?? 0;
    final left = face.leftEyeOpenProbability ?? -1;
    final right = face.rightEyeOpenProbability ?? -1;
    final smile = face.smilingProbability ?? -1;

    if (_finalStage) {
      final straight = yaw.abs() < 10 && left > 0.6 && right > 0.6;
      _stableFrames = straight ? _stableFrames + 1 : 0;
      if (_stableFrames >= 5) _capture();
      return;
    }

    if (_index >= _challenges.length) return;
    bool passed = false;
    switch (_challenges[_index]) {
      case _Challenge.blink:
        final open = left > 0.7 && right > 0.7;
        final closed = left >= 0 && right >= 0 && left < 0.25 && right < 0.25;
        if (open && !_eyesClosed) _eyesWereOpen = true;
        if (_eyesWereOpen && closed) _eyesClosed = true;
        if (_eyesClosed && open) passed = true;
        break;
      case _Challenge.smile:
        passed = smile > 0.75;
        break;
      case _Challenge.turn:
        passed = yaw.abs() > 22;
        break;
    }

    if (passed) {
      HapticFeedback.lightImpact();
      _eyesWereOpen = false;
      _eyesClosed = false;
      _index++;
      if (_index >= _challenges.length) {
        _finalStage = true;
        _stableFrames = 0;
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _capture() async {
    if (_capturing || _done) return;
    _capturing = true;
    if (mounted) setState(() {});
    try {
      await _stopStream();
      await Future.delayed(const Duration(milliseconds: 150));
      final file = await _controller!.takePicture();
      _done = true;
      _timeout?.cancel();
      if (mounted) Navigator.of(context).pop(file.path);
    } catch (e) {
      _capturing = false;
      if (mounted) {
        setState(() => _error = 'Could not capture the photo. Please try again.');
      }
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _capturing = false;
      _done = false;
      _resetChallenges();
    });
    _startStream();
    _startTimeout();
  }

  String get _instruction {
    if (kIsWeb) {
      return 'Look straight at the camera, capturing in $_webSecondsLeft...';
    }
    if (_finalStage) return 'Look straight at the camera and hold still';
    switch (_challenges[_index]) {
      case _Challenge.blink:
        return 'Blink your eyes';
      case _Challenge.smile:
        return 'Smile 😊';
      case _Challenge.turn:
        return 'Slowly turn your head to one side';
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    final c = _controller;
    _controller = null;
    () async {
      try {
        if (c != null && c.value.isStreamingImages) await c.stopImageStream();
      } catch (_) {}
      await c?.dispose();
    }();
    _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              if (_controller != null && _controller!.value.isInitialized)
                ElevatedButton(onPressed: _retry, child: const Text('Try again')),
              const SizedBox(height: 8),
              OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel')),
            ],
          ),
        ),
      );
    }

    final c = _controller!;
    final total = kIsWeb ? 1 : _challenges.length;
    final progress = kIsWeb ? (_webCountdownStarted ? 1 : 0) : (_finalStage ? total : _index);

    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            final ok = i < progress;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 28,
              height: 6,
              decoration: BoxDecoration(
                color: ok ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        Expanded(
          child: Center(
            child: LayoutBuilder(builder: (context, box) {
              final size = min(box.maxWidth, box.maxHeight) - 32;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _finalStage ? Colors.greenAccent : AppColors.primary,
                      width: 4),
                ),
                child: ClipOval(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: c.value.previewSize?.height ?? size,
                      height: c.value.previewSize?.width ?? size,
                      child: CameraPreview(c),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Text(
            _capturing
                ? 'Capturing...'
                : 'Keep your face inside the circle in good light. Only one person should be visible.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.hint, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
