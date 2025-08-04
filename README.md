# Vite Vere Offline ❤️

[![Flutter](https://img.shields.io/badge/Flutter-3.8+-blue.svg)](https://flutter.dev/)
[![Gemma 3N](https://img.shields.io/badge/Gemma%203N-On--Device-green.svg)](https://ai.google.dev/gemma)
[![Kaggle](https://img.shields.io/badge/Kaggle-Contest-orange.svg)](https://www.kaggle.com/competitions/google-gemma-3n-hackathon)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Offline AI application for inclusive assistance and room organization**  
Developed by Guido Marangoni for the Google Gemma 3n Hackathon

> 🇮🇹 [Versione Italiana](README_IT.md) | 🇺🇸 English Version

A Flutter application demonstrating the power of on-device multimodal AI using the `flutter_gemma` package with Google Gemma 3 Nano models. The app works completely offline and offers two main features: an inclusive AI assistant for people with intellectual disabilities and assistance for room organization.

## 🌟 Project Genesis

**Vite Vere Offline** is born as a natural evolution of the **[Vite Vere App](https://ai.google.dev/competition/projects/vite-vere?hl=en)** project, developed for the **Gemini API Developer Competition**.

### 🔄 From Online to Offline
The original **Vite Vere App** project used Google Gemini cloud APIs to provide advanced AI assistance. This **Offline** version represents a fundamental evolutionary step, leveraging the revolutionary potential of **Gemma 3 Nano** to bring artificial intelligence directly to the user's device.

### 🏆 Kaggle Contest
The development of **Vite Vere Offline** was motivated by participation in the **[Google Gemma 3n Hackathon](https://www.kaggle.com/competitions/google-gemma-3n-hackathon/overview)** on Kaggle, which challenges developers to create innovative applications leveraging Gemma 3 Nano's on-device capabilities.

### 🎯 Advantages of the Offline Approach

#### 🔒 **Total Privacy**
- No data ever leaves the device
- Completely local image processing
- Zero tracking or user profiling
- Full compliance with privacy regulations

#### 💰 **Cost Effectiveness**
- No API call costs
- Zero cloud service dependencies
- Unlimited usage without subscriptions
- Sustainable business model

#### 🌐 **Global Accessibility**
- Works without internet connection
- Available in areas with limited connectivity
- Consistent performance independent of network
- Democratization of AI access

### 👨‍💻 Creative Continuity
Both projects are the result of **Guido Marangoni**'s vision, who continues to explore the frontiers of AI applied to daily life, from cloud-first to edge-computing approaches, demonstrating how the same functionalities can be implemented with different but complementary technological paradigms.

### 🔧 Technical Foundation
The technical foundation of the project draws inspiration from the **[offline_menu_translator](https://github.com/gerfalcon/offline_menu_translator)** repository by gerfalcon, which provides an excellent reference implementation for integrating Gemma 3 Nano into Flutter applications. This project demonstrates how to adapt and extend on-device AI architectures to serve new use cases focused on inclusivity and accessibility.

## ✨ Main Features

### 🤝 Inclusive AI Assistant
- **Accessible AI chat** designed for people with intellectual disabilities
- **Simple and inclusive language** with short and clear sentences
- **Multimodal input**: supports both text and images
- **Intuitive interface** optimized for ease of use
- **Structured responses** that are understandable

### 🏠 Room Organization Assistant
- **Room photo analysis** with AI vision
- **Structured organization plan generation** in JSON format
- **3 concrete actions** with detailed steps for each
- **Personalized motivation** to encourage the user
- **Text-to-Speech** to listen to instructions
- **Multilingual support** (Italian, English, French, Spanish, German)

### 🌐 Multilingual Support
- **5 supported languages**: Italian, English, French, Spanish, German
- **Dynamic language switching** with preference persistence
- **Complete localization** of interface and AI prompts
- **Language-specific AI prompts** for optimal results

### 🤖 AI Technology
- **Completely offline**: no internet connection required
- **Gemma 3 Nano models**: E2B (2.9GB, ⭐ recommended) and E4B (4.1GB, higher quality)
- **Managed model downloads**: with progress indicator, anti-standby wakelock and local cache
- **Robust on-device inference**: intelligent timeouts, automatic retries and memory error handling
- **Reliable JSON generation**: advanced parsing with structure validation and automatic correction
- **Privacy and speed guaranteed**: no data ever leaves the device

## 🏗️ Technical Architecture

### Technology Stack
- **Flutter**: Cross-platform UI framework
- **flutter_gemma**: On-device AI inference with Gemma 3 Nano
- **Provider**: State management for localization
- **SharedPreferences**: User settings persistence
- **flutter_tts**: Text-to-Speech for voice instructions
- **image_picker**: Image selection from camera/gallery with choice dialog
- **wakelock_plus**: Standby prevention during long AI operations
- **flutter_launcher_icons**: Cross-platform app icon management

### Project Structure
```
lib/
├── main.dart                    # Entry point, model selection, inclusive navigation
├── data/
│   └── downloader_datasource.dart # AI model download and management
├── domain/
│   └── download_model.dart      # Model data structure
├── localization/               # i18n system
│   ├── app_strings.dart        # Main localization provider
│   ├── lingua_supportata.dart  # Supported languages
│   └── load_lingue.dart        # Language loading utilities
└── ui/
    ├── translator_screen.dart   # Inclusive assistant chat interface
    └── language_dropdown.dart   # Language selection widget

assets/
├── strings_xx.json            # UI translations (it, en, fr, es, de) with RAM warnings
├── order_room_prompt_xx.json  # Language-reinforced AI prompts for organization
├── gemma-3n.png              # Gemma 3N logo  
├── riordinare.png             # Room organization icon
├── logo-gemma.png             # Gemma logo for interfaces
├── vitevereoff-icona.png      # Main app icon
└── GUIDO-MARANGONI-Logo.png   # Developer logo
```

## 🚀 Setup and Installation

### Prerequisites
- Flutter SDK ≥ 3.8.0
- Compatible Dart SDK
- Hugging Face Token (for model downloads)

### Configuration

1. **Repository clone**
   ```bash
   git clone [repository-url]
   cd vite_vere_offline
   ```

2. **Dependencies installation**
   ```bash
   flutter pub get
   ```

3. **Hugging Face Token configuration**
   
   Edit `lib/data/downloader_datasource.dart` line 10:
   ```dart
   const String accessToken = 'YOUR_HUGGING_FACE_TOKEN';
   ```

4. **Execution**
   ```bash
   flutter run
   ```

### Development Commands

#### Build and Run
- `flutter run` - Run app in debug mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter build web` - Build web app

#### Code Quality
- `flutter analyze` - Static analysis
- `flutter test` - Unit and widget tests
- `flutter clean` - Clean build artifacts

#### Dependencies
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies

## 🎯 Detailed Features

### AI Model Management
- **Two Gemma 3 Nano variants**: E2B (⭐ recommended, 2.9GB) and E4B (high quality, 4.1GB)
- **Progressive download**: progress indicator, anti-standby wakelock and error handling
- **Intelligent cache**: model existence verification before download
- **Differentiated timeouts**: E2B (5 min) vs E4B (8 min) for optimized loading
- **Memory management**: optimized maxTokens per model (E2B: 2048, E4B: 1536)
- **User warnings**: RAM memory warnings with specific iPhone recommendations
- **Safe model switching**: memory cleanup and dynamic reloading

### Localization System
- **Dynamic loading**: asset-based translations with sequential initialization
- **Language consistency**: automatic resolution of inconsistencies on app restart
- **LLM fallback**: automatic translation for missing languages
- **Preference persistence**: user language saving with availability validation
- **Reinforced localized prompts**: bilingual instructions for maximum AI accuracy
- **Language validation**: saved language vs available languages check

### User Interfaces
- **Material Design**: consistent and modern with optimized scrolling for small screens
- **Advanced accessibility**: optimized for intellectual disabilities
- **Simple language**: understandable and inclusive terminology
- **Visual feedback**: detailed loading states, progress indicators, animations
- **TTS support**: voice reading of instructions
- **Responsive**: scrollable interfaces adaptive to different screen sizes
- **Advanced image selection**: camera/gallery dialog in chat and room organization
- **Visual indicators**: ⭐ star for recommended E2B model
- **User-friendly error handling**: clear messages for memory and timeout issues

## 🔧 Advanced Configuration

### Model URLs
- **E2B**: `https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task`
- **E4B**: `https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task`

### Performance and Optimizations
- **Large models**: 2.9-4.1GB, download with progress and anti-standby wakelock
- **Robust device inference**: intelligent timeouts, automatic retries for invalid JSON
- **Advanced memory management**: RAM warnings, E2B fallback for limited devices
- **Image processing**: limited to 1024x1024 for optimal performance
- **Streaming responses**: immediate feedback during generation
- **Wakelock management**: standby prevention during long downloads/generations
- **Robust JSON parsing**: structure validation, brace balancing, automatic correction
- **System requirements**: minimum 6GB available RAM, E2B recommended for iPhone

## 🆕 Latest Implemented Improvements

### 🔧 Technical Robustness
- **Anti-standby wakelock**: Device blocking prevention during model downloads and AI generation
- **Differentiated timeouts**: Intelligent loading time management for E2B (5 min) vs E4B (8 min)
- **Optimized memory management**: Adaptive maxTokens (E2B: 2048, E4B: 1536) to avoid OutOfMemoryError
- **Advanced JSON parsing**: Brace balancing, structure validation, automatic retry
- **Language consistency**: Automatic resolution of language inconsistencies on app restart

### 🎨 User Experience
- **Optimized scrolling**: Fully scrollable interfaces for small screens
- **Improved image selection**: Camera/gallery choice dialog in chat and organization
- **Visual indicators**: ⭐ star for recommended E2B model
- **Intelligent RAM warnings**: Specific warnings with iPhone recommendations
- **Reinforced AI prompts**: Bilingual instructions for maximum language accuracy

### 🌐 App Name
- **Display name**: "Vite Vere off" (updated from "vite_vere_offline")
- **iOS Bundle ID**: `it.guidomarangoni.vitevereoffline`
- **App icon**: `vitevereoff-icona.png` configured for all platforms

## 👨‍💻 Developer

**Guido Marangoni**  
Computer engineer with the dream of being an actor, the honor of teaching and the fortune of being a writer  
[guidomarangoni.it](https://guidomarangoni.it/)

### 🏆 AI Projects Portfolio
- **[Vite Vere App](https://ai.google.dev/competition/projects/vite-vere?hl=en)** - Cloud-based version for Gemini API Developer Competition
- **Vite Vere Offline** - On-device version for Google Gemma 3n Hackathon on Kaggle

### 🎯 Vision
Exploring how artificial intelligence can improve people's daily lives, with particular attention to inclusivity and accessibility for people with intellectual disabilities, using innovative technological approaches that respect privacy and human dignity.

## 📄 License

This project is developed for demonstration and educational purposes.

## 🙏 Acknowledgments

- **Inspiration**: Anna and all the boys and girls with Down syndrome and intellectual disabilities with their wonderful autonomy journeys developed by the Vite Vere Cooperative of Padua - Italy
- **Original project**: [Vite Vere App](https://ai.google.dev/competition/projects/vite-vere?hl=en) by Guido Marangoni developed for the Google Gemini API Developer Competition
- **Inspiration example for Gemma 3n model usage**: [offline_menu_translator](https://github.com/gerfalcon/offline_menu_translator) by gerfalcon
- **AI Technology**: Google Gemma 3 Nano and flutter_gemma package
- **Contest**: Google Gemma 3n Hackathon on Kaggle
- **Trademarks and logos**: Gemma 3n is owned by Google

---

*🤖 This README was generated with the assistance of Claude Code*