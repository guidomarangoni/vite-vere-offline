# Vite Vere Offline ❤️

[![Flutter](https://img.shields.io/badge/Flutter-3.8+-blue.svg)](https://flutter.dev/)
[![Gemma 3N](https://img.shields.io/badge/Gemma%203N-On--Device-green.svg)](https://ai.google.dev/gemma)
[![Kaggle](https://img.shields.io/badge/Kaggle-Contest-orange.svg)](https://www.kaggle.com/competitions/google-gemma-3n-hackathon)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Applicazione AI offline per assistenza nel percorso di autonomia delle persone con disabilità intellettiva**  
Sviluppata da Guido Marangoni per il Google Gemma 3n Hackathon

Un'applicazione Flutter che dimostra la potenza dell'AI multimodale on-device utilizzando il package `flutter_gemma` con il modello Google Gemma 3 Nano. L'app funziona completamente offline e offre due funzionalità principali: un assistente AI inclusivo per persone con disabilità intellettiva e assistenza per riordinare le stanze.

## 🌟 Genesi del Progetto

**Vite Vere Offline** nasce come evoluzione naturale del progetto **[Vite Vere App](https://ai.google.dev/competition/projects/vite-vere?hl=en)**, sviluppato per la **Gemini API Developer Competition**. 

### 🔄 Dall'Online all'Offline
Il progetto originale **Vite Vere App** utilizzava le API cloud di Google Gemini per fornire assistenza AI avanzata. Questa versione **Offline** rappresenta un passo evolutivo fondamentale, sfruttando le potenzialità rivoluzionarie di **Gemma 3 Nano** per portare l'intelligenza artificiale direttamente sul dispositivo dell'utente.

### 🏆 Contest Kaggle
Lo sviluppo di **Vite Vere Offline** è stato motivato dalla partecipazione al **[Google Gemma 3n Hackathon](https://www.kaggle.com/competitions/google-gemma-3n-hackathon/overview)** su Kaggle, che sfida gli sviluppatori a creare applicazioni innovative sfruttando le capacità on-device di Gemma 3 Nano.

### 🎯 Vantaggi dell'Approccio Offline

#### 🔒 **Privacy Totale**
- Nessun dato lascia mai il dispositivo
- Elaborazione completamente locale delle immagini
- Zero tracking o profilazione utente
- Conformità totale alle normative privacy

#### 💰 **Economicità**
- Nessun costo per chiamate API
- Zero dipendenze da servizi cloud
- Utilizzo illimitato senza subscription
- Modello di business sostenibile

#### 🌐 **Accessibilità Globale**
- Funziona senza connessione internet
- Disponibile in aree con connettività limitata
- Prestazioni costanti indipendenti dalla rete
- Democratizzazione dell'accesso all'AI

### 👨‍💻 Continuità Creativa
Entrambi i progetti sono frutto della visione di **Guido Marangoni**, che continua a esplorare le frontiere dell'AI applicata alla vita quotidiana, dall'approccio cloud-first a quello edge-computing, dimostrando come le stesse funzionalità possano essere implementate con paradigmi tecnologici diversi ma complementari.

### 🔧 Fondamenta Tecniche
La base tecnica del progetto prende spunto dal repository **[offline_menu_translator](https://github.com/gerfalcon/offline_menu_translator)** di gerfalcon, che fornisce un'eccellente implementazione di riferimento per l'integrazione di Gemma 3 Nano in applicazioni Flutter. Questo progetto dimostra come adattare e estendere architetture AI on-device per servire nuovi casi d'uso incentrati sull'inclusività e l'accessibilità.

## ✨ Caratteristiche Principali

### 🤝 Assistente AI Inclusivo
- **Chat AI accessibile** progettata per persone con disabilità intellettiva
- **Linguaggio semplice e inclusivo** con frasi brevi e chiare
- **Input multimodale**: supporta sia testo che immagini
- **Interfaccia intuitiva** ottimizzata per facilità d'uso
- **Risposte strutturate** e comprensibili

### 🏠 Assistente Riordino Stanze
- **Analisi foto della stanza** con AI vision
- **Generazione piano di riordino** strutturato in JSON
- **3 azioni concrete** con passi dettagliati per ciascuna
- **Motivazione personalizzata** per incoraggiare l'utente
- **Text-to-Speech** per ascoltare le istruzioni
- **Supporto multilingua** (Italiano, Inglese, Francese, Spagnolo, Tedesco)

### 🌐 Supporto Multilingua
- **5 lingue supportate**: Italiano, English, Français, Español, Deutsch
- **Cambio lingua dinamico** con persistenza delle preferenze
- **Localizzazione completa** di interfaccia e prompt AI
- **Prompt AI specifici per lingua** per risultati ottimali

### 🤖 Tecnologia AI
- **Completamente offline**: nessuna connessione internet richiesta
- **Modelli Gemma 3 Nano**: E2B (2.9GB, ⭐ raccomandato) e E4B (4.1GB, qualità superiore)
- **Download modelli gestito**: con progress indicator, wakelock anti-standby e cache locale
- **Inferenza on-device robusta**: timeout intelligenti, retry automatici e gestione errori memoria
- **Generazione JSON affidabile**: parsing avanzato con validazione struttura e correzione automatica
- **Privacy e velocità garantite**: nessun dato lascia mai il dispositivo

## 🏗️ Architettura Tecnica

### Stack Tecnologico
- **Flutter**: Framework UI cross-platform
- **flutter_gemma**: Inferenza AI on-device con Gemma 3 Nano
- **Provider**: State management per localizzazione
- **SharedPreferences**: Persistenza impostazioni utente
- **flutter_tts**: Text-to-Speech per istruzioni vocali
- **image_picker**: Selezione immagini da camera/galleria con dialog scelta
- **wakelock_plus**: Prevenzione standby durante operazioni AI lunghe
- **flutter_launcher_icons**: Gestione icone app cross-platform

### Struttura Progetto
```
lib/
├── main.dart                    # Entry point, selezione modelli, navigazione inclusiva
├── data/
│   └── downloader_datasource.dart # Download e gestione modelli AI
├── domain/
│   └── download_model.dart      # Struttura dati modelli
├── localization/               # Sistema i18n
│   ├── app_strings.dart        # Provider localizzazione principale
│   ├── lingua_supportata.dart  # Lingue supportate
│   └── load_lingue.dart        # Utility caricamento lingue
└── ui/
    ├── translator_screen.dart   # Interfaccia chat assistente inclusivo
    └── language_dropdown.dart   # Widget selezione lingua

assets/
├── strings_xx.json            # Traduzioni UI (it, en, fr, es, de) con avvisi RAM
├── order_room_prompt_xx.json  # Prompt AI per riordino rafforzati per lingua
├── gemma-3n.png              # Logo Gemma 3N  
├── riordinare.png             # Icona riordino stanze
├── logo-gemma.png             # Logo Gemma per interfacce
├── vitevereoff-icona.png      # Icona app principale
└── GUIDO-MARANGONI-Logo.png   # Logo sviluppatore
```

## 🚀 Setup e Installazione

### Prerequisiti
- Flutter SDK ≥ 3.8.0
- Dart SDK compatibile
- Token Hugging Face (per download modelli)

### Configurazione

1. **Clone del repository**
   ```bash
   git clone [repository-url]
   cd vite_vere_offline
   ```

2. **Installazione dipendenze**
   ```bash
   flutter pub get
   ```

3. **Configurazione Token Hugging Face**
   
   Modifica `lib/data/downloader_datasource.dart` linea 10:
   ```dart
   const String accessToken = 'IL_TUO_TOKEN_HUGGING_FACE';
   ```

4. **Esecuzione**
   ```bash
   flutter run
   ```

### Comandi di Sviluppo

#### Build e Run
- `flutter run` - Esegue app in debug mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter build web` - Build web app

#### Qualità Codice
- `flutter analyze` - Analisi statica
- `flutter test` - Test unitari e widget
- `flutter clean` - Pulizia artifacts di build

#### Dipendenze
- `flutter pub get` - Installa dipendenze
- `flutter pub upgrade` - Aggiorna dipendenze

## 🎯 Funzionalità Dettagliate

### Gestione Modelli AI
- **Due varianti Gemma 3 Nano**: E2B (⭐ raccomandato, 2.9GB) e E4B (qualità alta, 4.1GB)
- **Download progressivo**: indicatore progress, wakelock anti-standby e gestione errori
- **Cache intelligente**: verifica esistenza modelli prima del download
- **Timeout differenziati**: E2B (5 min) vs E4B (8 min) per caricamento ottimizzato
- **Gestione memoria**: maxTokens ottimizzati per modello (E2B: 2048, E4B: 1536)
- **Avvisi utente**: warning memoria RAM con raccomandazioni specifiche per iPhone
- **Switching modelli**: pulizia memoria e ricaricamento dinamico sicuro

### Sistema di Localizzazione
- **Caricamento dinamico**: asset-based translations con inizializzazione sequenziale
- **Coerenza linguistica**: risoluzione automatica incoerenze al riavvio app
- **Fallback LLM**: traduzione automatica per lingue mancanti
- **Persistenza preferenze**: salvataggio lingua utente con validazione disponibilità
- **Prompt localizzati rafforzati**: istruzioni bilingue per massima accuratezza AI
- **Validazione lingua**: controllo lingua salvata vs lingue disponibili

### Interfacce Utente
- **Design Material**: consistente e moderno con scrolling ottimizzato per schermi piccoli
- **Accessibilità avanzata**: ottimizzato per disabilità intellettive
- **Linguaggio semplice**: terminologie comprensibili e inclusive
- **Feedback visivo**: loading states dettagliati, progress indicators, animazioni
- **Supporto TTS**: lettura vocale delle istruzioni
- **Responsive**: interfacce scrollabili adattive a diverse dimensioni schermo
- **Selezione immagini avanzata**: dialog fotocamera/galleria in chat e riordino stanze
- **Indicatori visivi**: stella ⭐ per modello E2B raccomandato
- **Gestione errori user-friendly**: messaggi chiari per problemi memoria e timeout

## 🔧 Configurazione Avanzata

### URL Modelli
- **E2B**: `https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task`
- **E4B**: `https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task`

### Performance e Ottimizzazioni
- **Modelli grandi**: 2.9-4.1GB, download con progress e wakelock anti-standby
- **Inferenza device robusta**: timeout intelligenti, retry automatici per JSON invalidi
- **Gestione memoria avanzata**: warning RAM, fallback E2B per dispositivi limitati
- **Processamento immagini**: limitato a 1024x1024 per performance ottimale
- **Streaming responses**: feedback immediato durante generazione
- **Wakelock management**: prevenzione standby durante download/generazione lunghe
- **JSON parsing robusto**: validazione struttura, bilanciamento parentesi, correzione automatica
- **Requisiti sistema**: minimo 6GB RAM disponibili, E2B raccomandato per iPhone

## 🆕 Ultime Migliorie Implementate

### 🔧 Robustezza Tecnica
- **Wakelock anti-standby**: Prevenzione blocco dispositivo durante download modelli e generazione AI
- **Timeout differenziati**: Gestione intelligente tempi di caricamento per E2B (5 min) vs E4B (8 min)
- **Gestione memoria ottimizzata**: MaxTokens adattivi (E2B: 2048, E4B: 1536) per evitare OutOfMemoryError
- **JSON parsing avanzato**: Bilanciamento parentesi graffe, validazione struttura, retry automatico
- **Coerenza linguistica**: Risoluzione automatica incoerenze lingua al riavvio app

### 🎨 Esperienza Utente
- **Scrolling ottimizzato**: Interfacce completamente scrollabili per schermi piccoli
- **Selezione immagini migliorata**: Dialog scelta fotocamera/galleria in chat e riordino
- **Indicatori visivi**: Stella ⭐ per modello E2B raccomandato
- **Avvisi RAM intelligenti**: Warning specifici con raccomandazioni per iPhone
- **Prompt AI rafforzati**: Istruzioni bilingue per massima accuratezza linguistica

### 🌐 Nome App
- **Nome visualizzato**: "Vite Vere off" (aggiornato da "vite_vere_offline")
- **Bundle ID iOS**: `it.guidomarangoni.vitevereoffline`
- **Icona app**: `vitevereoff-icona.png` configurata per tutte le piattaforme

## 👨‍💻 Sviluppatore

**Guido Marangoni**  
ingegnere informatico con il sogno di fare l'attore, l'onore di insegnare e la fortuna di essere scrittore
[guidomarangoni.it](https://guidomarangoni.it/)

### 🏆 Portfolio Progetti AI
- **[Vite Vere App](https://ai.google.dev/competition/projects/vite-vere?hl=en)** - Versione cloud-based per Gemini API Developer Competition
- **Vite Vere Offline** - Versione on-device per Google Gemma 3n Hackathon su Kaggle

### 🎯 Visione
Esplorare come l'intelligenza artificiale possa migliorare la vita quotidiana delle persone, con particolare attenzione all'inclusività e all'accessibilità per persone con disabilità intellettiva, utilizzando approcci tecnologici innovativi che rispettino privacy e dignità umana.

## 📄 Licenza

Questo progetto è sviluppato per scopi dimostrativi ed educativi.

## 🙏 Riconoscimenti

- **Ispirazione**: Anna e tutti i ragazzi e le ragazze con sindrome di Down e disabilità intellettiva con i loro meravigliosi percorsi di autonomia sviluppati dalla Cooperativa Vite Vere di Padova - Italia
- **Progetto originale**: [Vite Vere App](https://ai.google.dev/competition/projects/vite-vere?hl=en) di Guido Marangoni sviluppata in occasione della Google Gemini API Developer Competition
- **Esempio di ispirazione per utilizzo modello Gemma 3n**: [offline_menu_translator](https://github.com/gerfalcon/offline_menu_translator) di gerfalcon
- **Tecnologia AI**: Google Gemma 3 Nano e flutter_gemma package
- **Contest**: Google Gemma 3n Hackathon su Kaggle
- **Marchi e loghi**: Gemma 3n è di proprietà di Google

---

*🤖 Questo README è stato generato con l'assistenza di Claude Code*
