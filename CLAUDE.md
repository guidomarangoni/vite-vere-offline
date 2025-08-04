# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build and Run
- `flutter run` - Run the app in debug mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter build web` - Build web app

### Code Quality
- `flutter analyze` - Run static analysis
- `flutter test` - Run unit and widget tests
- `flutter clean` - Clean build artifacts

### Dependencies
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies

## Project Architecture

### Core Technologies
- **Flutter**: Cross-platform UI framework
- **flutter_gemma**: On-device AI using Google's Gemma 3 Nano model
- **Provider**: State management for localization
- **SharedPreferences**: User settings persistence

### Key Features
1. **Offline AI Translation**: Menu translation using on-device Gemma models
2. **Room Organization**: AI-powered photo analysis for room cleaning tasks
3. **Multilingual Support**: Italian, English, French, Spanish, German
4. **Text-to-Speech**: Spoken instructions for room organization
5. **Model Management**: Download/delete AI models (E2B and E4B variants)

### Architecture Patterns

#### Model Initialization
- Global `ModelHolder` singleton stores AI model instances
- Models are downloaded from Hugging Face and cached locally
- Two model variants: E2B (~2GB, balanced) and E4B (~4GB, higher quality)

#### Localization System
- Dynamic language switching via `AppStrings` provider
- Asset-based translations (assets/strings_xx.json)
- LLM-powered translation for missing languages
- User language preference stored in SharedPreferences

#### AI Integration
- All AI processing happens on-device using flutter_gemma
- Supports multimodal input (text + images)
- Streaming token generation for real-time responses
- Chat-based interaction model with message history

### File Structure
```
lib/
├── main.dart                    # App entry point, model selection, language switching
├── data/
│   └── downloader_datasource.dart # Model download/management logic
├── domain/
│   └── download_model.dart      # Model data structure
├── localization/               # i18n system
│   ├── app_strings.dart        # Main localization provider
│   ├── lingua_supportata.dart  # Supported languages
│   └── load_lingue.dart        # Language loading utilities
└── ui/
    ├── translator_screen.dart   # Chat-based translation interface
    └── language_dropdown.dart   # Language selection widget
```

### Important Configuration

#### Hugging Face Token
- Required for model downloads
- Configure in `lib/data/downloader_datasource.dart:10`
- Replace placeholder token with valid HF token

#### Model URLs
- E2B: `https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task`
- E4B: `https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task`

### Navigation Flow
1. Language selection screen → Model selection → Model initialization → Main menu
2. Two main features: Chat translator and Room organization
3. Profile screen for user settings (name, language)

### Data Management
- User preferences stored in SharedPreferences
- AI models stored in app documents directory
- Localization assets bundled with app
- Dynamic prompt loading based on user language

### Performance Considerations
- Models are large (2-4GB), download shows progress
- AI inference can be slow on device, use loading indicators
- Image processing limited to 1024x1024 for performance
- Streaming responses provide immediate feedback