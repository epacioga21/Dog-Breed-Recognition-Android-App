// lib/tools/label_alignment_tool.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LabelAlignmentTool {
  /// Verifică alinierea între etichetele modelului și cele din JSON
  static Future<void> checkAlignment() async {
    try {
      // Încărcăm etichetele modelului - PĂSTRĂM FORMATUL ORIGINAL
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      final modelLabels = labelData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Transformăm etichetele modelului în formatul din JSON pentru comparație
      final formattedModelLabels = modelLabels.map((label) =>
          label.split('_')
              .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
              .join(' ')
      ).toList();

      // Încărcăm datele JSON
      final jsonString = await rootBundle.loadString('assets/dog_breeds.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      final jsonLabels = jsonData
          .map((item) => item['name'].toString())  // Nu mai transformăm în lowercase
          .toList();

      print("=== LABEL ALIGNMENT CHECK ===");
      print("Model labels: ${modelLabels.length}");
      print("Formatted model labels: ${formattedModelLabels.length}");
      print("JSON labels: ${jsonLabels.length}");

      // Verificăm care etichete din model nu există în JSON
      print("\nModel labels missing from JSON:");
      int missingFromJson = 0;
      for (int i = 0; i < modelLabels.length; i++) {
        final formattedLabel = formattedModelLabels[i];
        if (!jsonLabels.contains(formattedLabel)) {
          missingFromJson++;
          print("'${modelLabels[i]}' -> '$formattedLabel' not found in JSON");
        }
      }
      print("Total missing from JSON: $missingFromJson");

      // Verificăm care etichete din JSON nu există în model după formatare
      print("\nJSON labels missing from model:");
      int missingFromModel = 0;
      for (final jsonLabel in jsonLabels) {
        if (!formattedModelLabels.contains(jsonLabel)) {
          missingFromModel++;
          // Găsim cea mai apropiată potrivire
          final closestMatch = _findClosestMatch(jsonLabel, formattedModelLabels);
          print("'$jsonLabel' not found in formatted model labels. Closest match: '$closestMatch'");
        }
      }
      print("Total missing from model: $missingFromModel");

      print("\n=== END ALIGNMENT CHECK ===");
    } catch (e) {
      print("Error checking label alignment: $e");
    }
  }

  /// Găsește cea mai apropiată potrivire pentru un string într-o listă
  static String _findClosestMatch(String target, List<String> candidates) {
    String bestMatch = "";
    int bestScore = 0;

    for (final candidate in candidates) {
      final score = _calculateMatchScore(target, candidate);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = candidate;
      }
    }

    return bestMatch;
  }

  /// Calculează un scor simplu de potrivire între două string-uri
  static int _calculateMatchScore(String s1, String s2) {
    // Convertim la lowercase pentru comparație
    final ls1 = s1.toLowerCase();
    final ls2 = s2.toLowerCase();

    // Împărțim string-urile în cuvinte
    final words1 = ls1.split(' ');
    final words2 = ls2.split(' ');

    int score = 0;

    // Verificăm câte cuvinte sunt comune
    for (final word1 in words1) {
      for (final word2 in words2) {
        if (word1.length > 2 && word2.length > 2) {
          if (word1 == word2) {
            score += 10;
          } else if (word1.contains(word2) || word2.contains(word1)) {
            score += 5;
          }
        }
      }
    }

    return score;
  }

  /// Creează o mapare între etichetele din model și cele din JSON
  static Future<Map<String, String>> createLabelMapping() async {
    final Map<String, String> mapping = {};

    try {
      // Încărcăm etichetele modelului
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      final modelLabels = labelData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Transformăm etichetele modelului în formatul din JSON
      final formattedModelLabels = modelLabels.map((label) =>
          label.split('_')
              .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
              .join(' ')
      ).toList();

      // Încărcăm datele JSON
      final jsonString = await rootBundle.loadString('assets/dog_breeds.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      final jsonLabels = jsonData
          .map((item) => item['name'].toString())
          .toList();

      // Creăm maparea directă pentru etichetele care se potrivesc
      for (int i = 0; i < modelLabels.length; i++) {
        final modelLabel = modelLabels[i];
        final formattedLabel = formattedModelLabels[i];

        if (jsonLabels.contains(formattedLabel)) {
          mapping[modelLabel] = formattedLabel;
        } else {
          // Pentru cele care nu se potrivesc direct, găsim cea mai apropiată potrivire
          final closestMatch = _findClosestMatch(formattedLabel, jsonLabels);
          mapping[modelLabel] = closestMatch;
        }
      }

      print("Created mapping for ${mapping.length} labels");

      // Salvăm și câteva exemple pentru verificare
      final examples = mapping.entries.take(10).map((e) => "'${e.key}' -> '${e.value}'").join('\n');
      print("Mapping examples:\n$examples");

    } catch (e) {
      print("Error creating label mapping: $e");
    }

    return mapping;
  }
}