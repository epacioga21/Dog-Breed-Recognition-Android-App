class Prediction {
  final String breed;
  final double confidence;

  // Câmpuri noi pentru informații suplimentare
  final String? formattedBreed;
  final String? imageUrl;

  Prediction({
    required this.breed,
    required this.confidence,
    this.formattedBreed,
    this.imageUrl,
  });

  // Returnează numele rasei formatat pentru afișare
  String getDisplayName() {
    return formattedBreed ?? _formatBreedName(breed);
  }

  // Formatarea internă a numelui rasei
  static String _formatBreedName(String name) {
    return name
        .split('_')
        .map((word) => word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1)}'
        : '')
        .join(' ');
  }

  @override
  String toString() {
    return '${getDisplayName()} (${(confidence * 100).toStringAsFixed(1)}%)';
  }
}