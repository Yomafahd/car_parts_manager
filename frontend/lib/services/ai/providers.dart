import 'dart:typed_data';

import 'ai_capabilities.dart';

/// تنبيه: هذه مجرد هياكل (stubs). لا يوجد استدعاء شبكي هنا.
/// يُنصح بتفعيل هذه المزودات على الخادم وليس داخل تطبيق Flutter مباشرةً.

class OpenAIProvider implements TextGeneration, ImageGeneration {
  OpenAIProvider({required this.apiKey});
  final String apiKey; // لا تُخزن مفاتيح حقيقية هنا في الإنتاج

  @override
  Future<String> generateText(TextPrompt prompt) async {
    return Future.value('[openai:text] ${prompt.prompt}');
  }

  @override
  Future<Uint8List> generateImage(ImagePrompt prompt) async {
    // أعد صورة فارغة كعنصر نائب
    return Uint8List(0);
  }
}

class GoogleAIProvider implements Vision {
  GoogleAIProvider({required this.apiKey});
  final String apiKey;

  @override
  Future<String> analyzeImage(Uint8List imageBytes, {String? task}) async {
    return '[google_ai:vision] task=${task ?? 'generic'} bytes=${imageBytes.length}';
  }
}

class HuggingFaceProvider implements TextGeneration {
  HuggingFaceProvider({required this.apiKey});
  final String apiKey;

  @override
  Future<String> generateText(TextPrompt prompt) async {
    return '[hf:text] ${prompt.prompt}';
  }
}

class StabilityAIProvider implements ImageGeneration {
  StabilityAIProvider({required this.apiKey});
  final String apiKey;

  @override
  Future<Uint8List> generateImage(ImagePrompt prompt) async {
    return Uint8List(0);
  }
}

class RunwayMLProvider implements VideoGeneration {
  RunwayMLProvider({required this.apiKey});
  final String apiKey;

  @override
  Future<Uint8List> generateVideo(String prompt, {Duration? duration}) async {
    return Uint8List(0);
  }
}

class ElevenLabsProvider implements SpeechSynthesis {
  ElevenLabsProvider({required this.apiKey});
  final String apiKey;

  @override
  Future<Uint8List> synthesizeSpeech(String text, {String? voice}) async {
    return Uint8List(0);
  }
}
