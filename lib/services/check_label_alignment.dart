import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LabelAlignmentTool {
  /// Verifică alinierea între etichetele modelului și cele din JSON
  static Future<void> checkAlignment() async {
    try {
      // Încărcăm etichetele modelului
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      final modelLabels = labelData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      // Încărcăm datele JSON
      final jsonString = await rootBundle.loadString('assets/dog_breeds.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      final jsonLabels = jsonData
          .map((item) => item['name'].toString().toLowerCase())
          .toList();
      
      print("=== LABEL ALIGNMENT CHECK ===");
      print("Model labels: ${modelLabels.length}");
      print("JSON labels: ${jsonLabels.length}");
      
      // Verificăm care etichete din model nu există în JSON
      print("\nModel labels missing from JSON:");
      for (final label in modelLabels) {
        final normalizedLabel = label.toLowerCase();
        if (!jsonLabels.contains(normalizedLabel)) {
          // Încercăm să găsim cea mai apropiată potrivire
          final closestMatch = _findClosestMatch(normalizedLabel, jsonLabels);
          print("'$label' not found. Closest match: '$closestMatch'");
        }
      }
      
      // Verificăm care etichete din JSON nu există în model
      print("\nJSON labels missing from model:");
      for (final jsonLabel in jsonLabels) {
        final normalizedLabels = modelLabels.map((e) => e.toLowerCase()).toList();
        if (!normalizedLabels.contains(jsonLabel)) {
          // Încercăm să găsim cea mai apropiată potrivire
          final closestMatch = _findClosestMatch(jsonLabel, normalizedLabels);
          print("'$jsonLabel' not found. Closest match: '$closestMatch'");
        }
      }
      
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
    // Împărțim string-urile în cuvinte
    final words1 = s1.split('_');
    final words2 = s2.split('_');
    
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
}