class Prediction {
  final String breed;
  final double confidence;

  Prediction({
    required this.breed,
    required this.confidence,
  });

  @override
  String toString() {
    return '$breed (${(confidence * 100).toStringAsFixed(1)}%)';
  }
}