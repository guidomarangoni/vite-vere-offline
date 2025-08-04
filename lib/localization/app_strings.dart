import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AppStrings extends ChangeNotifier {
  Map<String, String> _localizedStrings = {};
  // Cache delle traduzioni: lingua -> json tradotto
  final Map<String, String> _cache = {};

  // Singleton pattern
  static final AppStrings _instance = AppStrings._internal();
  factory AppStrings() => _instance;
  AppStrings._internal();

  // Carica le stringhe da un asset (o da una stringa JSON)
  Future<void> loadFromAsset(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    _localizedStrings = Map<String, String>.from(json.decode(jsonString));
    notifyListeners();
  }

  // Carica le stringhe da una stringa JSON (es. risposta LLM)
  void loadFromJsonString(String jsonString, {String? lingua}) {
    _localizedStrings = Map<String, String>.from(json.decode(jsonString));
    if (lingua != null) {
      _cache[lingua] = jsonString;
    }
    notifyListeners();
  }

  // Ottieni la stringa localizzata
  String get(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Recupera la traduzione dalla cache, se presente
  String? getCachedTranslation(String lingua) => _cache[lingua];
} 