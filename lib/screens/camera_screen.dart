import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
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
  List<Map<String, dynamic>> _dogJson = [];
  bool _isLoading = false;
  bool _isModelReady = false;
  bool _isCameraReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadJson();
    _initializeApp();
  }

  Future<void> _loadJson() async {
    final jsonString = await rootBundle.loadString('assets/dog_breeds.json');
    final List<dynamic> data = json.decode(jsonString);
    setState(() {
      _dogJson = data.cast<Map<String, dynamic>>();
    });
  }

  Future<void> _initializeApp() async {
    try {
      _initializeCamera();
      setState(() => _isModelReady = true);
    } catch (e) {
      setState(() {
        _errorMessage = "Initialization error: $e";
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = "No cameras available");
        return;
      }

      _cameraController = CameraController(
        cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _initializeControllerFuture = _cameraController.initialize();
      await _initializeControllerFuture;

      if (!mounted) return;
      setState(() => _isCameraReady = true);
    } catch (e) {
      setState(() => _errorMessage = "Camera error: $e");
    }
  }


  Future<void> _captureImage() async {
    try {
      setState(() {
        _isLoading = true;
        _predictions = null;
        _errorMessage = null;
      });

      final image = await _cameraController.takePicture();
      setState(() {
        _capturedImage = File(image.path);
      });

      if (_isModelReady) await _sendToModel();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Capture error: $e";
      });
    }
  }

  Future<void> _sendToModel() async {
    if (_capturedImage == null) return;

    try {
      setState(() => _isLoading = true);

      final result = await MLService().predictBreed(_capturedImage!);

      if (result == null || !result.containsKey('predictions')) {
        setState(() {
          _errorMessage = "No predictions returned.";
          _isLoading = false;
        });
        return;
      }

      // Extragem lista de predicții
      final List<dynamic> rawPredictions = result['predictions'];
      final List<Prediction> predictions = rawPredictions.map((p) {
        return Prediction(
          breed: p['breed'],
          confidence: (p['confidence'] as num).toDouble(),
        );
      }).toList();

      // Îmbogățim predicțiile cu date din JSON
      final enriched = predictions.map((p) {
        final displayName = p.getDisplayName();
        final match = _dogJson.firstWhere(
              (dog) => dog['name'].toLowerCase() == displayName.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );

        if (match.isNotEmpty) {
          return Prediction(
            breed: p.breed,
            confidence: p.confidence,
            formattedBreed: match['name'],
            imageUrl: match['image_url'],
          );
        } else {
          return p;
        }
      }).toList();

      setState(() {
        _predictions = enriched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Prediction error: $e";
      });
    }
  }

  void _retakePhoto() async {
    setState(() {
      _capturedImage = null;
      _predictions = null;
      _errorMessage = null;
      _isCameraReady = false;
    });

    await _initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Identificare rasă',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: _buildBody(),
      ),
      floatingActionButton: _capturedImage == null ? _buildCaptureButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }


  Widget _buildBody() {
    if (_errorMessage != null) return Center(child: Text(_errorMessage!));
    if (!_isCameraReady) return const Center(child: CircularProgressIndicator());
    if (_capturedImage != null) return _buildResults();
    return FutureBuilder(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return CameraPreview(_cameraController);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildResults() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(_capturedImage!, fit: BoxFit.cover),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              children: [
                const Text(
                  "Results",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(child: _buildPredictionsList()),
                const SizedBox(height: 10),
                _buildRetakeButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRetakeButton() {
    return ElevatedButton.icon(
      onPressed: _retakePhoto,
      icon: const Icon(Icons.refresh, color: Colors.white),
      label: const Text("Retake", style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 4,
      ),
    );
  }

  Widget _buildPredictionsList() {
    if (_predictions == null || _predictions!.isEmpty) {
      return const Center(child: Text("No predictions"));
    }

    return ListView.builder(
      itemCount: _predictions!.length,
      itemBuilder: (context, index) {
        final p = _predictions![index];
        final breedData = _dogJson.firstWhere(
              (dog) => dog['name'].toLowerCase() == p.getDisplayName().toLowerCase(),
          orElse: () => <String, dynamic>{},
        );

        if (breedData == null) return const SizedBox();

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/dog_details',
              arguments: {
                'breed': breedData['name'],
                'description': breedData['description'],
                'imageUrl': breedData['image_url'],
                'attributes': breedData['attributes'],
              },
            );
          },
          child:
          Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              leading: p.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        p.imageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.pets, size: 40, color: Colors.grey),
              title: Text(
                p.getDisplayName(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: p.confidence,
                    color: _getConfidenceColor(p.confidence),
                    backgroundColor: Colors.grey[300],
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
              trailing: Text(
                "${(p.confidence * 100).toStringAsFixed(1)}%",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) return Colors.green;
    if (confidence > 0.4) return Colors.orange;
    return Colors.red;
  }

  Widget _buildCaptureButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 65),
      width: 70,
      height: 70,
      child: FloatingActionButton(
        onPressed: _isCameraReady && !_isLoading ? _captureImage : null,
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
        elevation: 6,
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
      ),
    );
  }

}
