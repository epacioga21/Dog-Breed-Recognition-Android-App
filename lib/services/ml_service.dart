import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/prediction.dart';

class MLService {
  static Interpreter? _interpreter;
  static List<String> _labels = [];
  static bool get isReady => _interpreter != null && _labels.isNotEmpty;

  static Future<void> init() async {
    try {
      // Load model
      _interpreter = await Interpreter.fromAsset(
        'assets/models/dog_breed_model.tflite',
        options: InterpreterOptions()..threads = 4,
      );

      // Verify model structure
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      // Load labels
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      // Log the successful model load
      print("Model loaded successfully");
    } catch (e) {
      print("Model initialization failed: $e");
      rethrow;
    }
  }

  static Future<List<Prediction>> predict(File imageFile) async {
    if (!isReady) throw Exception("Model not initialized");

    try {
      // 1. Preprocess the image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes)!;
      final resized = img.copyResize(image, width: 224, height: 224);  // Resize image to 224x224

      // 2. Convert the image to the required input format for the model
      final input = _imageToByteList(resized);  // Convert to a 4D tensor

      // 3. Prepare the output tensor
      final output = List.filled(1 * 120, 0.0).reshape([1, 120]);

      // 4. Run inference
      _interpreter!.run(input, output);

      // 5. Process the results and return top 3 predictions
      return _processOutput(output[0]);
    } catch (e) {
      // Handle errors
      print("Prediction error: $e");
      rethrow;
    }
  }


  static List<Prediction> _processOutput(List<double> output) {
    final sortedIndices = List.generate(output.length, (i) => i)
      ..sort((i, j) => output[j].compareTo(output[i]));

    return sortedIndices.take(5).map((i) {
      return Prediction(
        breed: _labels[i],
        confidence: output[i],
      );
    }).toList();
  }

  static Float32List _imageToByteList(img.Image image) {
    final buffer = Float32List(224 * 224 * 3);  // 224x224 image with 3 color channels
    int bufferIndex = 0;
    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        buffer[bufferIndex++] = (r - 127.5) / 127.5;  // Normalize to [-1, 1]
        buffer[bufferIndex++] = (g - 127.5) / 127.5;  // Normalize to [-1, 1]
        buffer[bufferIndex++] = (b - 127.5) / 127.5;  // Normalize to [-1, 1]
      }
    }

    // Return the input as a 4D tensor [1, 224, 224, 3]
    return buffer;
  }

}
