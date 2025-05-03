/*
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

class TensorDebugUtils {
  /// Salvează o imagine din tensor pentru debugging
  static Future<void> saveTensorAsImage(
    List<List<List<List<double>>>> tensor,
    String fileName
  ) async {
    if (tensor.isEmpty || tensor[0].isEmpty || tensor[0][0].isEmpty || tensor[0][0][0].isEmpty) {
      print("Cannot save empty tensor as image");
      return;
    }

    final height = tensor[0].length;
    final width = tensor[0][0].length;
    final channels = tensor[0][0][0].length;

    if (channels != 3) {
      print("Can only save RGB tensors (3 channels)");
      return;
    }

    // Creăm o imagine nouă
    final image = img.Image(width: width, height: height);

    // Convertim din tensor [-1, 1] la pixeli [0, 255]
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Denormalizăm valorile
        final r = ((tensor[0][y][x][0] + 1) * 127.5).round().clamp(0, 255);
        final g = ((tensor[0][y][x][1] + 1) * 127.5).round().clamp(0, 255);
        final b = ((tensor[0][y][x][2] + 1) * 127.5).round().clamp(0, 255);

        // Setăm pixelul în imagine
        image.setPixelRgb(x, y, r, g, b);
      }
    }

    // Salvăm imaginea
    final bytes = img.encodeJpg(image);
    await File(fileName).writeAsBytes(bytes);

    print("Tensor saved as image: $fileName");
  }

  /// Verificăm dacă tensorii conțin NaN sau Inf
  static bool checkForInvalidValues(List<List<List<List<double>>>> tensor) {
    bool hasInvalid = false;

    for (var batch in tensor) {
      for (var row in batch) {
        for (var col in row) {
          for (var val in col) {
            if (val.isNaN || val.isInfinite) {
              hasInvalid = true;
              print("Found invalid value: $val");
            }
          }
        }
      }
    }

    return hasInvalid;
  }

  /// Calculează statistici pentru tensor (min, max, mean, std)
  static Map<String, double> calculateTensorStats(List<List<List<List<double>>>> tensor) {
    double min = double.infinity;
    double max = double.negativeInfinity;
    double sum = 0;
    int count = 0;

    for (var batch in tensor) {
      for (var row in batch) {
        for (var col in row) {
          for (var val in col) {
            if (val < min) min = val;
            if (val > max) max = val;
            sum += val;
            count++;
          }
        }
      }
    }

    final mean = sum / count;

    // Calcularea deviației standard
    double sumSquaredDiff = 0;
    for (var batch in tensor) {
      for (var row in batch) {
        for (var col in row) {
          for (var val in col) {
            sumSquaredDiff += math.pow(val - mean, 2);
          }
        }
      }
    }

    final variance = sumSquaredDiff / count;
    final stdDev = math.sqrt(variance);

    return {
      'min': min,
      'max': max,
      'mean': mean,
      'std': stdDev
    };
  }
}*/
