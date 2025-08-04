import 'package:flutter/material.dart';
import 'package:vite_vere_offline/ui/translator_screen.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:vite_vere_offline/data/downloader_datasource.dart';
import 'package:vite_vere_offline/domain/download_model.dart';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'localization/app_strings.dart';
import 'localization/load_lingue.dart';
import 'localization/lingua_supportata.dart';
import 'ui/language_dropdown.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';

// Mappa lingua -> nome nella propria lingua e bandiera
const linguaDisplay = [
  {'code': 'it', 'label': 'Italiano', 'flag': '🇮🇹'},
  {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
  {'code': 'fr', 'label': 'Français', 'flag': '🇫🇷'},
  {'code': 'es', 'label': 'Español', 'flag': '🇪🇸'},
  {'code': 'de', 'label': 'Deutsch', 'flag': '🇩🇪'},
];

// Mappa label lingua -> nome lingua in inglese per il prompt
const linguaPromptMap = {
  'Italiano': 'Italian',
  'English': 'English',
  'Français': 'French',
  'Español': 'Spanish',
  'Deutsch': 'German',
};

// Mappa codice lingua -> codice TTS
const linguaTTSMap = {
  'it': 'it-IT',
  'en': 'en-US',
  'fr': 'fr-FR',
  'es': 'es-ES',
  'de': 'de-DE',
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appStrings = AppStrings();
  await appStrings.loadFromAsset('assets/strings_it.json');
  runApp(
    ChangeNotifierProvider.value(
      value: appStrings,
      child: const MyApp(),
    ),
  );
}

class ModelHolder {
  static InferenceModel? model;
  static InferenceChat? chat;
  static String? currentModelName;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appStrings = context.watch<AppStrings>();
    return MaterialApp(
      title: appStrings.get('app_title'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const LanguageAndModelSelectionScreen(),
    );
  }
}

class LanguageAndModelSelectionScreen extends StatefulWidget {
  const LanguageAndModelSelectionScreen({super.key});

  @override
  State<LanguageAndModelSelectionScreen> createState() => _LanguageAndModelSelectionScreenState();
}

class _LanguageAndModelSelectionScreenState extends State<LanguageAndModelSelectionScreen> {
  List<String> _lingueDisponibili = [];
  String? _linguaSelezionata = 'Italiano';
  bool _loading = true;
  bool _isTranslating = false;
  String? _translationError;
  bool? _isE2BDownloaded;
  bool? _isE4BDownloaded;

  @override
  void initState() {
    super.initState();
    _initializeLanguageAndModels();
  }
  
  Future<void> _initializeLanguageAndModels() async {
    // Prima inizializza le lingue disponibili
    await _initLingueDagliAssets();
    // Poi carica la lingua salvata (che ora può usare linguaDisplay)
    await _loadSavedLanguage();
    // Infine controlla i modelli
    _checkModels();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('user_language');
    print('DEBUG _loadSavedLanguage: $savedLang');
    print('DEBUG _loadSavedLanguage: lingue disponibili: $_lingueDisponibili');
    
    String linguaFinale = savedLang ?? 'Italiano';
    
    // Verifica che la lingua salvata sia effettivamente disponibile
    if (savedLang != null && !_lingueDisponibili.contains(savedLang)) {
      print('DEBUG: Lingua salvata "$savedLang" non disponibile, uso Italiano');
      linguaFinale = 'Italiano';
      await prefs.setString('user_language', 'Italiano');
    }
    
    // Se la lingua salvata è vuota o null, forza il default italiano
    if (savedLang == null || savedLang.isEmpty) {
      await prefs.setString('user_language', 'Italiano');
      linguaFinale = 'Italiano';
      print('DEBUG: Forzata lingua italiana come default');
    }
    
    setState(() {
      _linguaSelezionata = linguaFinale;
    });
    
    // IMPORTANTE: Carica subito il file asset della lingua salvata
    final linguaObj = linguaDisplay.firstWhere((l) => l['label'] == linguaFinale, orElse: () => linguaDisplay[0]);
    final code = linguaObj['code'] ?? 'it';
    String assetPath = 'assets/strings_$code.json';
    print('DEBUG _loadSavedLanguage: Caricamento asset da $assetPath');
    
    try {
      await context.read<AppStrings>().loadFromAsset(assetPath);
      print('DEBUG _loadSavedLanguage: Asset caricato con successo');
    } catch (e) {
      print('DEBUG _loadSavedLanguage: Errore caricamento asset lingua: $e');
      // In caso di errore, carica l'italiano come fallback
      try {
        await context.read<AppStrings>().loadFromAsset('assets/strings_it.json');
      } catch (fallbackError) {
        print('DEBUG _loadSavedLanguage: Errore anche nel fallback italiano: $fallbackError');
      }
    }
  }

  Future<void> _initLingueDagliAssets() async {
    // Lista delle lingue supportate in base ai file assets/strings_xx.json
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final lingue = <Map<String, String>>[];
    final regex = RegExp(r'assets/strings_([a-z]{2})\.json');
    for (final path in manifestMap.keys) {
      final match = regex.firstMatch(path);
      if (match != null) {
        final code = match.group(1)!;
        final found = linguaDisplay.firstWhere(
          (l) => l['code'] == code,
          orElse: () => {'code': code, 'label': code, 'flag': ''},
        );
        lingue.add(found);
      }
    }
    setState(() {
      _lingueDisponibili = lingue.map((l) => l['label']!).toList();
      _loading = false;
      if (!_lingueDisponibili.contains(_linguaSelezionata)) {
        _linguaSelezionata = _lingueDisponibili.isNotEmpty ? _lingueDisponibili.first : null;
      }
    });
  }

  Future<void> _checkModels() async {
    final e2b = GemmaDownloaderDataSource(
      model: DownloadModel(
        modelUrl: 'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
        modelFilename: 'gemma-3n-E2B-it-int4.task',
      ),
    );
    final e4b = GemmaDownloaderDataSource(
      model: DownloadModel(
        modelUrl: 'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
        modelFilename: 'gemma-3n-E4B-it-int4.task',
      ),
    );
    final e2bDownloaded = await e2b.checkModelExistence();
    final e4bDownloaded = await e4b.checkModelExistence();
    setState(() {
      _isE2BDownloaded = e2bDownloaded;
      _isE4BDownloaded = e4bDownloaded;
    });
  }

  Future<void> _onModelSelected(String modelName) async {
    print('DEBUG: Selezionato modello: $modelName, lingua: $_linguaSelezionata');
    // Naviga a schermata di inizializzazione modello
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModelInitScreen(
          modelName: modelName,
          onModelReady: null, // Non ricaricare la lingua qui!
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isTranslating) {
      return Scaffold(
        appBar: AppBar(title: Text(context.watch<AppStrings>().get('app_title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_translationError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.watch<AppStrings>().get('app_title'))),
        body: Center(child: Text(_translationError!, style: const TextStyle(color: Colors.red))),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.watch<AppStrings>().get('app_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Logo Gemma 3N
            Center(
              child: Image.asset(
                'assets/gemma-3n.png',
                width: double.infinity,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            // 2. Seleziona modello
            Text(context.watch<AppStrings>().get('select_model'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            // 3. Carte dei modelli
            _ModelCard(
              title: context.watch<AppStrings>().get('model_e2b_title'),
              description: context.watch<AppStrings>().get('model_e2b_desc'),
              isDownloaded: _isE2BDownloaded,
              isRecommended: true,
              onTap: () => _onModelSelected('gemma-3n-E2B-it-int4.task'),
              onDelete: _isE2BDownloaded == true
                  ? () async {
                      final downloader = GemmaDownloaderDataSource(
                        model: DownloadModel(
                          modelUrl: 'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
                          modelFilename: 'gemma-3n-E2B-it-int4.task',
                        ),
                      );
                      final filePath = await downloader.getFilePath();
                      final file = File(filePath);
                      if (await file.exists()) {
                        await file.delete();
                        setState(() {
                          _isE2BDownloaded = false;
                        });
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 24),
            _ModelCard(
              title: context.watch<AppStrings>().get('model_e4b_title'),
              description: context.watch<AppStrings>().get('model_e4b_desc'),
              isDownloaded: _isE4BDownloaded,
              onTap: () => _onModelSelected('gemma-3n-E4B-it-int4.task'),
              onDelete: _isE4BDownloaded == true
                  ? () async {
                      final downloader = GemmaDownloaderDataSource(
                        model: DownloadModel(
                          modelUrl: 'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
                          modelFilename: 'gemma-3n-E4B-it-int4.task',
                        ),
                      );
                      final filePath = await downloader.getFilePath();
                      final file = File(filePath);
                      if (await file.exists()) {
                        await file.delete();
                        setState(() {
                          _isE4BDownloaded = false;
                        });
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            // Avviso memoria RAM
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                context.watch<AppStrings>().get('memory_warning') ?? 
                'Nota: I modelli AI richiedono almeno 6GB di RAM disponibili. Su alcuni device potrebbe non funzionare.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.amber.shade800,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            // 4. Seleziona lingua
            Text(context.watch<AppStrings>().get('choose_language'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade300, width: 1.2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _linguaSelezionata,
                  hint: const Text('Seleziona lingua'),
                  isExpanded: true,
                  style: const TextStyle(fontSize: 22, color: Colors.black),
                  iconSize: 36,
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  items: linguaDisplay.where((l) => _lingueDisponibili.contains(l['label'])).map((lingua) {
                    return DropdownMenuItem<String>(
                      value: lingua['label'],
                      child: Row(
                        children: [
                          Text(lingua['flag'] ?? '', style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Text(lingua['label']!, style: const TextStyle(fontSize: 22)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (nuovaLingua) async {
                    if (nuovaLingua != null) {
                      print('DEBUG: Cambiata lingua da $_linguaSelezionata a $nuovaLingua');
                      // Salva PRIMA la lingua selezionata nelle preferenze
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('user_language', nuovaLingua);
                      print('DEBUG: Salvata lingua $nuovaLingua nelle SharedPreferences');
                      setState(() {
                        _linguaSelezionata = nuovaLingua;
                      });
                      // Carica subito il file asset della lingua selezionata
                      final linguaObj = linguaDisplay.firstWhere((l) => l['label'] == _linguaSelezionata, orElse: () => linguaDisplay[0]);
                      final code = linguaObj['code'] ?? 'it';
                      String assetPath = 'assets/strings_$code.json';
                      print('DEBUG: Caricamento asset da $assetPath');
                      try {
                        await context.read<AppStrings>().loadFromAsset(assetPath);
                        if (!mounted) return;
                      } catch (e) {
                        print('DEBUG: Errore caricamento asset lingua: $e');
                        if (!mounted) return;
                        setState(() {
                          _translationError = 'Errore nel caricamento delle stringhe per la lingua $_linguaSelezionata: $e';
                        });
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
            // 5. Logo Guido Marangoni
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Image.asset(
                'assets/GUIDO-MARANGONI-Logo.png',
                width: double.infinity,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Funzione helper per traduzione dinamica tramite LLM
Future<String> traduciJsonConLLM(String linguaDestinazione, String jsonDaTradurre) async {
  print('DEBUG: [traduciJsonConLLM] INIZIO per $linguaDestinazione');
  final chat = ModelHolder.chat;
  if (chat == null) throw Exception('Modello non inizializzato');
  final prompt = '''
Traduci il seguente oggetto JSON dall'italiano a $linguaDestinazione. Mantieni la struttura e traduci solo i valori:
$jsonDaTradurre
''';
  await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
  String response = '';
  try {
    print('DEBUG: [traduciJsonConLLM] Inizio generazione risposta LLM...');
    bool timeout = false;
    final stream = chat.generateChatResponseAsync().timeout(
      const Duration(seconds: 20),
      onTimeout: (sink) {
        print('DEBUG: [traduciJsonConLLM] TIMEOUT generazione risposta LLM');
        timeout = true;
        sink.close();
      },
    );
    await for (final token in stream) {
      print('DEBUG: [traduciJsonConLLM] token: $token');
      response += token;
    }
    if (timeout) {
      throw Exception('Timeout generazione risposta LLM');
    }
    print('DEBUG: [traduciJsonConLLM] Risposta grezza LLM: \n$response');
    // Pulisci eventuali caratteri extra
    final start = response.indexOf('{');
    final end = response.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      print('DEBUG: [traduciJsonConLLM] JSON estratto, ritorno risultato');
      return response.substring(start, end + 1);
    }
    print('DEBUG: [traduciJsonConLLM] Risposta LLM non valida, lancio eccezione');
    throw Exception('Risposta LLM non valida');
  } catch (e) {
    print('DEBUG: [traduciJsonConLLM] Errore: $e');
    rethrow;
  }
  // Non dovrebbe mai arrivare qui
  print('DEBUG: [traduciJsonConLLM] FINE (caso inatteso)');
}

class ModelSelectionScreen extends StatefulWidget {
  final VoidCallback? onModelLoaded;
  const ModelSelectionScreen({super.key, this.onModelLoaded});

  @override
  State<ModelSelectionScreen> createState() => _ModelSelectionScreenState();
}

class _ModelSelectionScreenState extends State<ModelSelectionScreen> {
  bool? _isE2BDownloaded;
  bool? _isE4BDownloaded;

  @override
  void initState() {
    super.initState();
    _checkModels();
  }

  Future<void> _checkModels() async {
    final e2b = GemmaDownloaderDataSource(
      model: DownloadModel(
        modelUrl: 'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
        modelFilename: 'gemma-3n-E2B-it-int4.task',
      ),
    );
    final e4b = GemmaDownloaderDataSource(
      model: DownloadModel(
        modelUrl: 'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
        modelFilename: 'gemma-3n-E4B-it-int4.task',
      ),
    );
    final e2bDownloaded = await e2b.checkModelExistence();
    final e4bDownloaded = await e4b.checkModelExistence();
    setState(() {
      _isE2BDownloaded = e2bDownloaded;
      _isE4BDownloaded = e4bDownloaded;
    });
  }

  Future<void> _deleteModel(String modelName, String modelUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text('Sei sicuro di voler eliminare il modello "$modelName" dallo smartphone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final downloader = GemmaDownloaderDataSource(
      model: DownloadModel(
        modelUrl: modelUrl,
        modelFilename: modelName,
      ),
    );
    final filePath = await downloader.getFilePath();
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('model_downloaded_$modelName', false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Modello $modelName eliminato')),
        );
      }
      _checkModels();
    }
  }

  Future<void> _onModelSelected(String modelName) async {
    // Qui puoi mostrare un loader se vuoi
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ModelInitScreen(
          modelName: modelName,
          onModelReady: widget.onModelLoaded,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleziona modello'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        elevation: 0,
      ),
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Benvenuti in Vite Vere OFF',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Seleziona il modello AI che preferisci',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.blueGrey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _ModelCard(
                  title: context.watch<AppStrings>().get('model_e2b_title'),
                  description: context.watch<AppStrings>().get('model_e2b_desc'),
                  isDownloaded: _isE2BDownloaded,
                  isRecommended: true,
                  onTap: () => _onModelSelected('gemma-3n-E2B-it-int4.task'),
                  onDelete: _isE2BDownloaded == true
                      ? () => _deleteModel(
                            'gemma-3n-E2B-it-int4.task',
                            'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
                          )
                      : null,
                ),
                const SizedBox(height: 24),
                _ModelCard(
                  title: context.watch<AppStrings>().get('model_e4b_title'),
                  description: context.watch<AppStrings>().get('model_e4b_desc'),
                  isDownloaded: _isE4BDownloaded,
                  onTap: () => _onModelSelected('gemma-3n-E4B-it-int4.task'),
                  onDelete: _isE4BDownloaded == true
                      ? () => _deleteModel(
                            'gemma-3n-E4B-it-int4.task',
                            'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
                          )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final String title;
  final String description;
  final bool? isDownloaded;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isRecommended;

  const _ModelCard({
    required this.title,
    required this.description,
    required this.isDownloaded,
    required this.onTap,
    this.onDelete,
    this.isRecommended = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            children: [
              Icon(
                isDownloaded == true ? Icons.check_circle : Icons.cloud_download,
                color: isDownloaded == true ? Colors.green : Colors.grey,
                size: 40,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                        if (isRecommended)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                    if (isDownloaded == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          'Scaricato',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isDownloaded == true && onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                  tooltip: 'Elimina modello',
                  onPressed: onDelete,
                ),
              const Icon(Icons.arrow_forward_ios, color: Colors.blueGrey, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class ModelInitScreen extends StatefulWidget {
  final String modelName;
  final VoidCallback? onModelReady;
  const ModelInitScreen({super.key, required this.modelName, this.onModelReady});

  @override
  State<ModelInitScreen> createState() => _ModelInitScreenState();
}

class _ModelInitScreenState extends State<ModelInitScreen> {
  String? _status;
  bool _error = false;
  String? _errorMsg;
  double? _downloadProgress;

  @override
  void initState() {
    super.initState();
    _status = null;
    _initModel();
  }
  
  Future<void> _initializeInclusiveSystemPrompt(InferenceChat chat) async {
    // Ottieni la lingua corrente dall'utente
    final prefs = await SharedPreferences.getInstance();
    final linguaUtente = prefs.getString('lingua_utente') ?? 'Italiano';
    
    // Mappa le lingue ai codici per il prompt
    final Map<String, String> lingueCodici = {
      'Italiano': 'italiano',
      'English': 'inglese',
      'Français': 'francese', 
      'Español': 'spagnolo',
      'Deutsch': 'tedesco',
    };
    
    final linguaPrompt = lingueCodici[linguaUtente] ?? 'italiano';
    
    // Prompt di sistema ottimizzato per Gemma 3n e personalità inclusiva
    final systemPrompt = '''Sei Vite Vere, un assistente AI inclusivo e gentile. La tua missione è aiutare le persone con disabilità intellettiva.

LINGUA: Rispondi SEMPRE in $linguaPrompt. Tutte le tue risposte devono essere in $linguaPrompt.

PERSONALITÀ:
- Sei paziente, gentile e incoraggiante
- Usi parole semplici e frasi brevi
- Dai una risposta alla volta
- Celebri i piccoli successi

COMUNICAZIONE:
- Parole facili (evita termini complicati)
- Frasi di massimo 15 parole
- Spiegazioni passo dopo passo
- Esempi concreti e pratici

COMPORTAMENTO:
- Ascolta sempre con attenzione
- Non giudicare mai
- Incoraggia sempre
- Ripeti se necessario
- Chiedi se hai capito bene

Se l'utente manda una foto, descrivila in modo semplice e aiutalo.

Inizia presentandoti brevemente in $linguaPrompt.''';

    // Invia il prompt di sistema come primo messaggio
    await chat.addQueryChunk(Message.text(text: systemPrompt, isUser: true));
    
    // Genera e consuma la risposta di inizializzazione senza mostrarla
    final responseStream = chat.generateChatResponseAsync();
    await for (final _ in responseStream) {
      // Consuma la risposta senza memorizzarla
    }
  }

  Future<void> _initModel() async {
    try {
      // Controlla se il modello richiesto è già caricato
      if (ModelHolder.currentModelName == widget.modelName && 
          ModelHolder.model != null && 
          ModelHolder.chat != null) {
        // Modello già caricato, vai direttamente alla splash screen
        await Future.delayed(const Duration(milliseconds: 500));
        if (widget.onModelReady != null) widget.onModelReady!();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SplashScreen()),
          );
        }
        return;
      }
      
      // Attiva wakelock per impedire lo standby durante download/inizializzazione
      await WakelockPlus.enable();
      
      // Pulisci il modello precedente se esiste
      if (ModelHolder.model != null) {
        ModelHolder.model = null;
        ModelHolder.chat = null;
        ModelHolder.currentModelName = null;
      }
      
      final gemma = FlutterGemmaPlugin.instance;
      final modelUrl = widget.modelName == 'gemma-3n-E2B-it-int4.task'
          ? 'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task'
          : 'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task';
      final downloader = GemmaDownloaderDataSource(
        model: DownloadModel(
          modelUrl: modelUrl,
          modelFilename: widget.modelName,
        ),
      );

      setState(() { _status = context.read<AppStrings>().get('loading'); _downloadProgress = null; });
      final exists = await downloader.checkModelExistence();
      if (!exists) {
        setState(() { _status = context.read<AppStrings>().get('loading'); _downloadProgress = 0.0; });
        await downloader.downloadModel(
          token: accessToken,
          onProgress: (progress) {
            setState(() {
              _downloadProgress = progress;
              _status = context.read<AppStrings>().get('loading') + ' ${(progress * 100).toStringAsFixed(1)}%';
            });
          },
        );
      }

      final modelPath = await downloader.getFilePath();
      setState(() { _status = 'Configurazione percorso modello...'; _downloadProgress = null; });
      print('DEBUG: Configurazione percorso modello: $modelPath');
      await gemma.modelManager.setModelPath(modelPath);
      print('DEBUG: Percorso modello configurato');
      
      setState(() { _status = 'Caricamento modello in memoria...'; });
      // Per E4B, aumenta i maxTokens e sii più paziente con il timeout
      final isE4B = widget.modelName.contains('E4B');
      print('DEBUG: Inizio creazione modello, isE4B: $isE4B');
      final model = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        supportImage: true,
        maxTokens: isE4B ? 1536 : 2048, // Riduci i token per E4B per risparmiare memoria
      ).timeout(
        Duration(minutes: isE4B ? 8 : 5), // Timeout più lungo per E4B
        onTimeout: () => throw TimeoutException('Timeout caricamento modello - il dispositivo potrebbe non avere abbastanza RAM per questo modello'),
      );
      print('DEBUG: Modello creato con successo');
      
      setState(() { _status = 'Creazione sessione chat...'; });
      final chat = await model.createChat(supportImage: true).timeout(
        Duration(minutes: 3),
        onTimeout: () => throw TimeoutException('Timeout creazione chat'),
      );
      print('DEBUG: Chat creata con successo');
      
      // Inizializza la chat con prompt di sistema inclusivo
      await _initializeInclusiveSystemPrompt(chat);
      
      ModelHolder.model = model;
      ModelHolder.chat = chat;
      ModelHolder.currentModelName = widget.modelName;
      await Future.delayed(const Duration(milliseconds: 500));
      if (widget.onModelReady != null) widget.onModelReady!();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      }
      
      // Disattiva wakelock al completamento
      await WakelockPlus.disable();
    } catch (e) {
      // Pulisci lo stato in caso di errore
      ModelHolder.model = null;
      ModelHolder.chat = null;
      ModelHolder.currentModelName = null;
      
      String errorMessage = e.toString();
      
      // Gestione specifica per errori di memoria
      if (errorMessage.contains('OutOfMemoryError') || 
          errorMessage.contains('Cannot allocate memory') ||
          errorMessage.contains('Timeout caricamento modello')) {
        errorMessage = 'Memoria insufficiente per questo modello. Prova il modello E2B o usa un dispositivo con più RAM.';
      } else if (errorMessage.contains('TimeoutException') || errorMessage.contains('Timeout')) {
        errorMessage = 'Caricamento troppo lento. Il dispositivo potrebbe non avere abbastanza RAM per questo modello.';
      }
      
      setState(() {
        _error = true;
        _errorMsg = errorMessage;
        _downloadProgress = null;
      });
      
      // Disattiva wakelock anche in caso di errore
      await WakelockPlus.disable();
    }
  }

  @override
  void dispose() {
    // Assicurati che il wakelock venga disattivato quando il widget viene distrutto
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _error
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 24),
                  Text(context.watch<AppStrings>().get('error_loading_model'), style: const TextStyle(fontSize: 18, color: Colors.red)),
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMsg!, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _initModel,
                    child: Text(context.watch<AppStrings>().get('retry')),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  const _ModernSpinner(),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      _status ?? context.watch<AppStrings>().get('loading'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_downloadProgress != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                      child: LinearProgressIndicator(value: _downloadProgress),
                    ),
                ],
              ),
      ),
    );
  }
}

class _ModernSpinner extends StatefulWidget {
  const _ModernSpinner();
  @override
  State<_ModernSpinner> createState() => _ModernSpinnerState();
}

class _ModernSpinnerState extends State<_ModernSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 6.28319,
          child: child,
        );
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue.shade300, width: 8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo-gemma.png'),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MenuScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo-gemma.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 32),
            Text(
              context.watch<AppStrings>().get('app_title'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedLanguage;
  List<String> _lingueDisponibili = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initLingueDagliAssets();
    _loadProfile();
  }

  Future<void> _initLingueDagliAssets() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final lingue = <Map<String, String>>[];
    final regex = RegExp(r'assets/strings_([a-z]{2})\.json');
    for (final path in manifestMap.keys) {
      final match = regex.firstMatch(path);
      if (match != null) {
        final code = match.group(1)!;
        final found = linguaDisplay.firstWhere(
          (l) => l['code'] == code,
          orElse: () => {'code': code, 'label': code, 'flag': ''},
        );
        lingue.add(found);
      }
    }
    setState(() {
      _lingueDisponibili = lingue.map((l) => l['label']!).toList();
      _loading = false;
    });
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final lang = prefs.getString('user_language');
    setState(() {
      _nameController.text = name;
      _selectedLanguage = lang;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    if (_selectedLanguage != null) {
      await prefs.setString('user_language', _selectedLanguage!);
    }
    if (_selectedLanguage != null) {
      final linguaObj = linguaDisplay.firstWhere((l) => l['label'] == _selectedLanguage, orElse: () => linguaDisplay[0]);
      final code = linguaObj['code'] ?? 'it';
      String assetPath = 'assets/strings_$code.json';
      await context.read<AppStrings>().loadFromAsset(assetPath);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<AppStrings>().get('profile') ?? 'Profilo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.watch<AppStrings>().get('your_name') ?? 'Il tuo nome', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      hintText: context.watch<AppStrings>().get('your_name_hint') ?? 'Inserisci il tuo nome',
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(context.watch<AppStrings>().get('choose_language'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade300, width: 1.2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        hint: const Text('Seleziona lingua'),
                        isExpanded: true,
                        style: const TextStyle(fontSize: 22, color: Colors.black),
                        iconSize: 36,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        items: linguaDisplay.where((l) => _lingueDisponibili.contains(l['label'])).map((lingua) {
                          return DropdownMenuItem<String>(
                            value: lingua['label'],
                            child: Row(
                              children: [
                                Text(lingua['flag'] ?? '', style: const TextStyle(fontSize: 28)),
                                const SizedBox(width: 12),
                                Text(lingua['label']!, style: const TextStyle(fontSize: 22)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (nuovaLingua) {
                          setState(() {
                            _selectedLanguage = nuovaLingua;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(context.watch<AppStrings>().get('save_profile') ?? 'Salva'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.watch<AppStrings>().get('main_menu_title')),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, size: 32),
            tooltip: 'Profilo',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MenuButton(
              title: context.watch<AppStrings>().get('chat_menu_title'),
              subtitle: context.watch<AppStrings>().get('chat_menu_subtitle'),
              image: 'assets/gemma.png',
              color: Colors.blue.shade100,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const TranslatorScreen()),
                );
              },
            ),
            const SizedBox(height: 32),
            _MenuButton(
              title: context.watch<AppStrings>().get('order_room_menu_title'),
              subtitle: context.watch<AppStrings>().get('order_room_menu_subtitle'),
              image: 'assets/riordinare.png',
              color: Colors.green.shade100,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const OrderRoomScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  image,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderRoomScreen extends StatefulWidget {
  const OrderRoomScreen({super.key});

  @override
  State<OrderRoomScreen> createState() => _OrderRoomScreenState();
}

class _OrderRoomScreenState extends State<OrderRoomScreen> {
  Uint8List? _photoBytes;
  String? _jsonResponse;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  String? _prompt;
  String _loadingStatus = '';
  int _elapsedSeconds = 0;
  Timer? _timer;
  int? _tokenCount;
  bool? _isE2BDownloaded;
  bool? _isE4BDownloaded;

  @override
  void initState() {
    super.initState();
    _loadPrompt();
    _checkModels();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStrings>().addListener(_loadPrompt);
    });
  }

  @override
  void dispose() {
    context.read<AppStrings>().removeListener(_loadPrompt);
    _timer?.cancel();
    // Assicurati che il wakelock venga disattivato quando il widget viene distrutto
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _loadPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final userLang = prefs.getString('user_language') ?? 'Italiano';
    print('DEBUG _loadPrompt userLang: $userLang');
    // Mappa label lingua -> codice file
    final langCodeMap = {
      'Italiano': 'it',
      'English': 'en',
      'Français': 'fr',
      'Español': 'es',
      'Deutsch': 'de',
    };
    final code = langCodeMap[userLang] ?? 'it';
    final assetPath = 'assets/order_room_prompt_' + code + '.json';
    print('DEBUG _loadPrompt assetPath: $assetPath');
    String prompt;
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final data = json.decode(jsonString);
      prompt = data['order_room_prompt'] as String;
    } catch (e) {
      // Fallback all'italiano se file non trovato
      final jsonString = await rootBundle.loadString('assets/order_room_prompt_it.json');
      final data = json.decode(jsonString);
      prompt = data['order_room_prompt'] as String;
    }
    setState(() {
      _prompt = prompt;
    });
    print('DEBUG _loadPrompt prompt caricato: $_prompt');
  }

  Future<void> _checkModels() async {
    final e2b = GemmaDownloaderDataSource(
      model: DownloadModel(
        modelUrl: 'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
        modelFilename: 'gemma-3n-E2B-it-int4.task',
      ),
    );
    final e4b = GemmaDownloaderDataSource(
      model: DownloadModel(
        modelUrl: 'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task',
        modelFilename: 'gemma-3n-E4B-it-int4.task',
      ),
    );
    final e2bDownloaded = await e2b.checkModelExistence();
    final e4bDownloaded = await e4b.checkModelExistence();
    setState(() {
      _isE2BDownloaded = e2bDownloaded;
      _isE4BDownloaded = e4bDownloaded;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.read<AppStrings>().get('choose_photo_source')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(context.read<AppStrings>().get('take_photo')),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(context.read<AppStrings>().get('select_from_gallery')),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.read<AppStrings>().get('cancel')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _takePhotoAndAskLLM([ImageSource? source]) async {
    ImageSource imageSource = source ?? ImageSource.camera;
    
    // Se non è stata specificata una fonte, mostra il dialog di selezione
    if (source == null) {
      imageSource = await _showImageSourceDialog() ?? ImageSource.camera;
    }
    
    final pickedFile = await _picker.pickImage(source: imageSource, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (pickedFile == null) return;
    final bytes = await pickedFile.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _jsonResponse = null;
      _isLoading = true;
      _loadingStatus = 'Uso la chat già pronta...';
      _tokenCount = null;
    });
    _startTimer();
    
    // Attiva wakelock per impedire lo standby durante la generazione
    await WakelockPlus.enable();
    
    try {
      final chat = ModelHolder.chat;
      if (chat == null) throw Exception('Chat non inizializzata');
      print('Chat pronta');
      setState(() { _loadingStatus = 'Invio la foto e il prompt...'; });
      // Ricarica il prompt per assicurarsi che sia nella lingua corretta
      await _loadPrompt();
      // Recupera nome e lingua dal profilo
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name')?.trim();
      final userLang = prefs.getString('user_language');
      print('DEBUG userLang dalle SharedPreferences: $userLang');
      print('DEBUG tutti i valori SharedPreferences: ${prefs.getKeys()}');
      String linguaPrompt = '';
      if (userLang != null && userLang.isNotEmpty) {
        linguaPrompt = linguaPromptMap[userLang] ?? userLang;
      }
      print('DEBUG linguaPrompt: $linguaPrompt');
      // Recupera la stringa localizzata e sostituisci {language}
      final appStrings = context.read<AppStrings>();
      String personNameStr = appStrings.get('prompt_person_name').replaceAll('{name}', userName ?? '');
      if (!personNameStr.endsWith('.')) personNameStr += '.';
      personNameStr += ' ';
      String prefix = personNameStr;
      // Crea istruzioni linguistiche molto più forti
      String languageInstruction = '';
      String targetLanguage = linguaPrompt.isEmpty ? 'italiano' : (linguaPromptMap.entries
          .firstWhere((entry) => entry.value == linguaPrompt, orElse: () => const MapEntry('Italiano', 'Italian'))
          .key.toLowerCase());
      
      if (linguaPrompt.isNotEmpty) {
        languageInstruction = '''
        
LINGUA OBBLIGATORIA: Devi rispondere ESCLUSIVAMENTE in lingua $targetLanguage.
IMPORTANTE: Ogni singola parola della tua risposta deve essere in $targetLanguage.
LANGUAGE REQUIREMENT: You must respond EXCLUSIVELY in $linguaPrompt language.
IMPORTANT: Every single word of your response must be in $linguaPrompt.
        ''';
      } else {
        languageInstruction = '''
        
LINGUA OBBLIGATORIA: Devi rispondere ESCLUSIVAMENTE in italiano.
IMPORTANTE: Ogni singola parola della tua risposta deve essere in italiano.
        ''';
      }
      print('DEBUG languageInstruction: $languageInstruction');
      print('DEBUG _prompt: $_prompt');
      String prompt = prefix + (_prompt ?? '') + languageInstruction;
      print('DEBUG Prompt finale inviato al LLM:\n$prompt');
      await chat.addQueryChunk(Message.withImage(
        text: prompt,
        imageBytes: bytes,
        isUser: true,
      ));
      print('addQueryChunk ok');
      setState(() { _loadingStatus = 'Genero la risposta...'; });
      String response = '';
      int tokenCount = 0;
      await for (final token in chat.generateChatResponseAsync()) {
        response += token;
        print('token: $token');
        tokenCount++;
      }
      print('Risposta generata');
      print('Risposta LLM:\n$response');
      
      // Verifica se il JSON è valido, altrimenti riprova una volta
      String? validJson = extractFirstJsonObject(response);
      if (validJson == null) {
        print('Prima risposta non valida, riprovo...');
        setState(() { _loadingStatus = 'Riprovo la generazione...'; });
        
        // Invia un prompt di correzione
        await chat.addQueryChunk(Message.text(
          text: 'La risposta precedente non era in formato JSON valido. Rispondi SOLO con il JSON richiesto, senza altro testo.',
          isUser: true,
        ));
        
        String retryResponse = '';
        await for (final token in chat.generateChatResponseAsync()) {
          retryResponse += token;
          tokenCount++;
        }
        
        // Prova a estrarre JSON dalla seconda risposta
        validJson = extractFirstJsonObject(retryResponse);
        if (validJson != null) {
          response = retryResponse;
          print('Seconda risposta valida:\n$retryResponse');
        } else {
          print('Anche la seconda risposta non è valida:\n$retryResponse');
        }
      }
      
      setState(() {
        _jsonResponse = response;
        _tokenCount = tokenCount;
      });
    } catch (e, st) {
      print('Errore: $e\n$st');
      setState(() {
        _jsonResponse = 'Errore: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _loadingStatus = '';
      });
      _stopTimer();
      
      // Disattiva wakelock al completamento della generazione
      await WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<AppStrings>().get('order_room')),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/riordinare.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.add_a_photo, size: 32),
                label: Text(context.watch<AppStrings>().get('take_room_photo')),
                onPressed: _isLoading ? null : _takePhotoAndAskLLM,
              ),
              const SizedBox(height: 24),
              if (_photoBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    _photoBytes!,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      _AnimatedLoadingText(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer, color: Colors.black45),
                          const SizedBox(width: 8),
                          Text(
                            _elapsedSeconds < 60
                                ? '${_elapsedSeconds}s'
                                : '${_elapsedSeconds ~/ 60}m ${_elapsedSeconds % 60}s',
                            style: const TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_loadingStatus.isNotEmpty)
                        Text(
                          _loadingStatus,
                          style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              if (_jsonResponse != null && !_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: _OrderRoomResultView(
                    jsonString: _jsonResponse!,
                    elapsedSeconds: _elapsedSeconds,
                    tokenCount: _tokenCount,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedLoadingText extends StatefulWidget {
  const _AnimatedLoadingText();

  @override
  State<_AnimatedLoadingText> createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<_AnimatedLoadingText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<int> _dotCountAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _dotCountAnim = StepTween(begin: 0, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseText = context.watch<AppStrings>().get('analyzing_photo');
    return AnimatedBuilder(
      animation: _dotCountAnim,
      builder: (context, child) {
        final dots = '.' * _dotCountAnim.value;
        return Text(
          '$baseText$dots',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}

String? extractFirstJsonObject(String input) {
  // Rimuovi caratteri di controllo e spazi iniziali/finali
  input = input.trim();
  
  // Cerca il primo oggetto JSON valido nella stringa
  int start = input.indexOf('{');
  if (start == -1) return null;
  
  // Trova la fine dell'oggetto JSON bilanciando le parentesi graffe
  int braceCount = 0;
  int end = -1;
  bool inString = false;
  bool escapeNext = false;
  
  for (int i = start; i < input.length; i++) {
    final char = input[i];
    
    if (escapeNext) {
      escapeNext = false;
      continue;
    }
    
    if (char == '\\' && inString) {
      escapeNext = true;
      continue;
    }
    
    if (char == '"') {
      inString = !inString;
      continue;
    }
    
    if (!inString) {
      if (char == '{') {
        braceCount++;
      } else if (char == '}') {
        braceCount--;
        if (braceCount == 0) {
          end = i;
          break;
        }
      }
    }
  }
  
  if (end == -1) return null;
  
  final candidate = input.substring(start, end + 1);
  try {
    // Verifica che sia JSON valido
    final decoded = json.decode(candidate);
    
    // Verifica che contenga la struttura richiesta
    if (decoded is Map<String, dynamic>) {
      final actions = decoded['actions'];
      final motivation = decoded['motivation'];
      
      if (actions is List && actions.length == 3 && motivation is String) {
        // Verifica che ogni action abbia la struttura corretta
        for (final action in actions) {
          if (action is Map<String, dynamic> &&
              action['action'] is String &&
              action['steps'] is List &&
              (action['steps'] as List).length == 3) {
            continue;
          } else {
            return null; // Struttura non valida
          }
        }
        return candidate; // Tutto ok
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

class _OrderRoomResultView extends StatelessWidget {
  final String jsonString;
  final int? elapsedSeconds;
  final int? tokenCount;
  const _OrderRoomResultView({required this.jsonString, this.elapsedSeconds, this.tokenCount});

  @override
  Widget build(BuildContext context) {
    try {
      final cleaned = extractFirstJsonObject(jsonString);
      if (cleaned == null) throw Exception('Nessun oggetto JSON trovato');
      final data = json.decode(cleaned);
      final List actions = data['actions'] ?? [];
      final String motivation = data['motivation'] ?? '';
      if (actions.length != 3) throw Exception('Il JSON non contiene 3 actions');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < 3; i++)
            _ActionBox(
              action: actions[i]['action'] ?? '',
              steps: List<String>.from(actions[i]['steps'] ?? []),
              index: i,
            ),
          const SizedBox(height: 20),
          if (motivation.isNotEmpty)
            _MotivationBox(motivation: motivation),
          const SizedBox(height: 16),
          _GenerationStats(
            elapsedSeconds: elapsedSeconds,
            tokenCount: tokenCount,
          ),
        ],
      );
    } catch (e) {
      // Mostra un messaggio di errore chiaro se il parsing fallisce
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ Errore: la risposta non è in formato JSON valido o non contiene 3 azioni.\n',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              jsonString,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
            ),
          ],
        ),
      );
    }
  }
}

class _MotivationBox extends StatefulWidget {
  final String motivation;
  const _MotivationBox({required this.motivation});

  @override
  State<_MotivationBox> createState() => _MotivationBoxState();
}

class _MotivationBoxState extends State<_MotivationBox> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _tts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
        });
        print('TTS: start');
      }
    });
    _tts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
        print('TTS: cancel');
      }
    });
    _tts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
        print('TTS: error: '
            '\u001b[31m$msg\u001b[0m');
      }
    });
  }

  Future<String> _getUserTTSLang() async {
    final prefs = await SharedPreferences.getInstance();
    final userLang = prefs.getString('user_language') ?? 'Italiano';
    final langCodeMap = {
      'Italiano': 'it',
      'English': 'en',
      'Français': 'fr',
      'Español': 'es',
      'Deutsch': 'de',
    };
    final code = langCodeMap[userLang] ?? 'it';
    return linguaTTSMap[code] ?? 'it-IT';
  }

  Future<void> _speak() async {
    await _tts.stop();
    setState(() {
      _isSpeaking = true;
      _done = false;
    });
    final ttsLang = await _getUserTTSLang();
    await _tts.setLanguage(ttsLang);
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.10);
    await _tts.awaitSpeakCompletion(true);

    await _tts.speak(widget.motivation);
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _done = true;
      });
      print('TTS: motivazione completata');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _done = false);
      });
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_emotions, color: Colors.green, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.motivation,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.green),
            ),
          ),
          _done
              ? Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 32),
                    const SizedBox(width: 4),
                    Text('Fatto!', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                  ],
                )
              : IconButton(
                  icon: Icon(
                    _isSpeaking ? Icons.volume_up : Icons.volume_mute,
                    color: Colors.green.shade700,
                    size: 32,
                  ),
                  tooltip: 'Leggi motivazione',
                  onPressed: _isSpeaking ? null : _speak,
                ),
        ],
      ),
    );
  }
}

class _GenerationStats extends StatelessWidget {
  final int? elapsedSeconds;
  final int? tokenCount;
  const _GenerationStats({this.elapsedSeconds, this.tokenCount});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 13, color: Colors.grey.shade400);
    final List<String> stats = [];
    if (elapsedSeconds != null) {
      final s = elapsedSeconds!;
      final timeStr = s < 60 ? '${s}s' : '${s ~/ 60}m ${s % 60}s';
      stats.add('Tempo: $timeStr');
    }
    if (tokenCount != null) {
      stats.add('Token generati: $tokenCount');
    }
    if (stats.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        stats.join('   •   '),
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

class _ActionBox extends StatefulWidget {
  final String action;
  final List<String> steps;
  final int index;
  const _ActionBox({required this.action, required this.steps, required this.index});

  @override
  State<_ActionBox> createState() => _ActionBoxState();
}

class _ActionBoxState extends State<_ActionBox> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _tts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
        });
        print('TTS: start');
      }
    });
    _tts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
        print('TTS: cancel');
      }
    });
    _tts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
        print('TTS: error: '
            '\u001b[31m$msg\u001b[0m');
      }
    });
  }

  Future<String> _getUserTTSLang() async {
    final prefs = await SharedPreferences.getInstance();
    final userLang = prefs.getString('user_language') ?? 'Italiano';
    final langCodeMap = {
      'Italiano': 'it',
      'English': 'en',
      'Français': 'fr',
      'Español': 'es',
      'Deutsch': 'de',
    };
    final code = langCodeMap[userLang] ?? 'it';
    return linguaTTSMap[code] ?? 'it-IT';
  }

  Future<void> _speak() async {
    await _tts.stop();
    setState(() {
      _isSpeaking = true;
      _done = false;
    });
    final ttsLang = await _getUserTTSLang();
    await _tts.setLanguage(ttsLang);
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.10);
    await _tts.awaitSpeakCompletion(true);

    final action = widget.action;
    final steps = widget.steps;
    final List<String> frasi = [action, ...steps];
    for (final frase in frasi) {
      await _tts.speak(frase);
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _done = true;
      });
      print('TTS: sequenza completata');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _done = false);
      });
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.blue.shade50, Colors.orange.shade50, Colors.purple.shade50];
    final icons = [Icons.cleaning_services, Icons.format_list_bulleted, Icons.check_circle_outline];
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors[widget.index % colors.length],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors[widget.index % colors.length].withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: colors[widget.index % colors.length].withOpacity(0.13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icons[widget.index % icons.length], color: Colors.black54, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.action,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              _done
                  ? Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 32),
                        const SizedBox(width: 4),
                        Text('Fatto!', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : IconButton(
                      icon: Icon(
                        _isSpeaking ? Icons.volume_up : Icons.volume_mute,
                        color: Colors.green.shade700,
                        size: 32,
                      ),
                      tooltip: 'Leggi',
                      onPressed: _isSpeaking ? null : _speak,
                    ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < widget.steps.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.steps[i],
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}