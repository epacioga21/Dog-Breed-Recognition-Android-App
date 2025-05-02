import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/prediction.dart';
import 'dart:math' as math;

class MLService {
  static Interpreter? _interpreter;
  static List<String> _labels = [];
  static bool get isReady => _interpreter != null && _labels.isNotEmpty;

  // Dimensiuni imagine pentru modelul antrenat
  static const int IMAGE_SIZE = 224;

  static Future<void> init() async {
    try {
      // Încărcarea modelului
      _interpreter = await Interpreter.fromAsset(
        'assets/models/dog_breed_model.tflite',
        options: InterpreterOptions()..threads = 4,
      );

      // Verificarea structurii modelului
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      print("Model input shape: ${inputTensors[0].shape}");
      print("Model output shape: ${outputTensors[0].shape}");

      // Încărcarea etichetelor
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      print("Loaded ${_labels.length} labels");
      print("Model loaded successfully");
    } catch (e) {
      print("Model initialization failed: $e");
      rethrow;
    }
  }

  static Future<List<Prediction>> predict(File imageFile) async {
    if (!isReady) throw Exception("Model not initialized");

    try {
      // 1. Citirea și decodificarea imaginii
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception("Failed to decode image");
      }

      // 2. Preprocesarea imaginii
      final processedImage = _preprocessImage(image);

      // 3. Pregătirea tensorului de ieșire
      // Folosește corect formatul de ieșire bazat pe numărul de clase
      final outputShape = [1, _labels.length];
      final output = List<double>.filled(outputShape[0] * outputShape[1], 0)
          .reshape(outputShape);

      // 4. Rularea inferenței
      _interpreter!.run(processedImage, output);

      // 5. Procesarea rezultatelor
      return _processOutputs(output[0]);
    } catch (e) {
      print("Prediction error: $e");
      rethrow;
    }
  }

  // Preprocesarea imaginii conform pipeline-ului din notebook
  static List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    // 1. Redimensionarea imaginii la dimensiunea necesară modelului
    final resizedImage = img.copyResize(
        image,
        width: IMAGE_SIZE,
        height: IMAGE_SIZE,
        interpolation: img.Interpolation.linear
    );

    // 2. Crearea și popularea tensor-ului de intrare [1, 224, 224, 3]
    final input = List.generate(
      1,
          (_) => List.generate(
        IMAGE_SIZE,
            (_) => List.generate(
          IMAGE_SIZE,
              (_) => List<double>.filled(3, 0),
        ),
      ),
    );

    // 3. Popularea tensor-ului cu valorile de pixeli normalizate
    for (int y = 0; y < IMAGE_SIZE; y++) {
      for (int x = 0; x < IMAGE_SIZE; x++) {
        final pixel = resizedImage.getPixel(x, y);

        // Extragerea valorilor RGB
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        // Normalizarea valorilor la [-1, 1] ca în notebook
        // (valoare - 127.5) / 127.5
        input[0][y][x][0] = (r - 127.5) / 127.5;
        input[0][y][x][1] = (g - 127.5) / 127.5;
        input[0][y][x][2] = (b - 127.5) / 127.5;
      }
    }

    return input;
  }

  // Procesarea rezultatelor și returnarea predicțiilor sortate
  static List<Prediction> _processOutputs(List<double> outputs) {
    // Aplicarea softmax pentru a obține probabilități
    final softmaxOutputs = _applySoftmax(outputs);

    // Crearea unei liste de perechi (index, probabilitate)
    final indexedOutputs = List<MapEntry<int, double>>.generate(
      softmaxOutputs.length,
          (i) => MapEntry(i, softmaxOutputs[i]),
    );

    // Sortarea după probabilitate în ordine descrescătoare
    indexedOutputs.sort((a, b) => b.value.compareTo(a.value));

    // Returnarea primelor 3 predicții
    return indexedOutputs.take(3).map((entry) {
      final index = entry.key;
      final confidence = entry.value;

      return Prediction(
        breed: _formatBreedName(_labels[index]),
        confidence: confidence,
      );
    }).toList();
  }

  // Aplicarea funcției softmax pentru a transforma logits în probabilități
  static List<double> _applySoftmax(List<double> logits) {
    // Găsirea valorii maxime pentru stabilitate numerică
    double maxLogit = logits.reduce(math.max);

    // Aplicarea exponențialei și normalizarea
    double sumExp = 0.0;
    List<double> exps = List<double>.filled(logits.length, 0);

    for (int i = 0; i < logits.length; i++) {
      exps[i] = math.exp(logits[i] - maxLogit);
      sumExp += exps[i];
    }

    // Normalizarea pentru a obține probabilități
    for (int i = 0; i < exps.length; i++) {
      exps[i] /= sumExp;
    }

    return exps;
  }

  // Formatarea numelui rasei pentru afișare
  static String _formatBreedName(String rawName) {
    // Înlocuirea underscore-urilor cu spații și capitalizarea cuvintelor
    return rawName
        .split('_')
        .map((word) => word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1)}'
        : '')
        .join(' ');
  }
}