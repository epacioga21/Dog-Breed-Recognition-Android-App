// lib/models/prediction.dart
class Prediction {
  final String breed;  // Numele rasei în formatul original din model (snake_case)
  final double confidence;
  final String? formattedBreed;  // Numele rasei formatat pentru afișare (poate fi furnizat extern)
  final String? imageUrl;  // URL-ul imaginii pentru rasă (poate fi null)

  Prediction({
    required this.breed,
    required this.confidence,
    this.formattedBreed,
    this.imageUrl,
  });

  // Returnează numele rasei formatat pentru afișare
  String getDisplayName() {
    // Dacă avem un nume formatat deja furnizat, îl folosim
    if (formattedBreed != null && formattedBreed!.isNotEmpty) {
      return formattedBreed!;
    }

    // Altfel, formatăm numele intern (transformăm snake_case în Title Case)
    return formatBreedName(breed);
  }

  static String formatBreedName(String rawBreedName) {
    // Handle special cases first
    final specialCases = {
      'black-and-tan_coonhound': 'Black and Tan Coonhound',
      'blenheim_spaniel': 'Blenheim Spaniel',
      'boston_bull': 'Boston Bull',
      'bouvier_des_flandres': 'Bouvier Des Flandres',
      'german_short-haired_pointer': 'German Short Haired Pointer',
      'mexican_hairless': 'Mexican Hairless',
      'shih-tzu': 'Shih-Tzu',
      'soft-coated_wheaten_terrier': 'Soft Coated Wheaten Terrier',
      'wire-haired_fox_terrier': 'Wire Haired Fox Terrier',
    };

    if (specialCases.containsKey(rawBreedName)) {
      return specialCases[rawBreedName]!;
    }

    // General case conversion
    return rawBreedName
        .split('_')
        .map((word) => word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1)}'
        : '')
        .join(' ');
  }
}