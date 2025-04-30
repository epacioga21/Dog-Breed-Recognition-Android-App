import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/ml_service.dart';
import '../models/prediction.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  File? _capturedImage;
  List<Prediction>? _predictions;
  bool _isLoading = false;
  bool _isModelReady = false;
  bool _isCameraReady = false;
  bool _showDebugInfo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initializeCamera();
    await _initializeModel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initializeControllerFuture = _cameraController.initialize();
      await _initializeControllerFuture;

      if (!mounted) return;

      setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint("Camera error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Camera error: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _initializeModel() async {
    try {
      setState(() => _isLoading = true);
      await MLService.init();
      if (!mounted) return;

      setState(() {
        _isModelReady = true;
        _isLoading = false;
      });

      debugPrint("Model loaded successfully");
    } catch (e) {
      debugPrint("Model error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Model error: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _captureImage() async {
    try {
      setState(() {
        _isLoading = true;
        _predictions = null;
      });

      final image = await _cameraController.takePicture();
      if (!mounted) return;

      setState(() {
        _capturedImage = File(image.path);
        _isLoading = false;
      });

      // Auto-process the image if model is ready
      if (_isModelReady) {
        await _sendToModel();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Capture error: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _sendToModel() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No image captured")),
      );
      return;
    }

    if (!_isModelReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Model not ready")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Add more detailed error handling here
      final predictions = await MLService.predict(_capturedImage!);

      if (!mounted) return;

      setState(() => _predictions = predictions);

      if (predictions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No predictions returned")),
        );
      }
    } catch (e) {
      debugPrint("Prediction error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Prediction error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _predictions = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showDebugInfo) {
      debugPrint("""App State:
      - Camera: $_isCameraReady
      - Model: $_isModelReady
      - Image: ${_capturedImage != null}
      - Loading: $_isLoading""");
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dog Breed Identifier"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => setState(() => _showDebugInfo = !_showDebugInfo),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildCameraPreview(),
          ),
          _buildControlButtons(),
          if (_predictions != null) _buildResultsSection(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_capturedImage != null) {
      return Image.file(_capturedImage!, fit: BoxFit.cover);
    }
    return FutureBuilder(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return CameraPreview(_cameraController);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_capturedImage == null)
            ElevatedButton.icon(
              onPressed: _isCameraReady && !_isLoading ? _captureImage : null,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Capture"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          if (_capturedImage != null) ...[
            ElevatedButton.icon(
              onPressed: _isModelReady && !_isLoading ? _sendToModel : null,
              icon: const Icon(Icons.pets),
              label: const Text("Identify Breed"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _retakePhoto,
              icon: const Icon(Icons.refresh),
              label: const Text("Retake"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Detection Results:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._predictions!.map((prediction) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    prediction.breed,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Text(
                  "${(prediction.confidence * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
