import 'dart:typed_data';

/// نماذج مدخلات/مخرجات بسيطة للذكاء الاصطناعي
class TextPrompt {
  TextPrompt({required this.prompt, this.options});
  final String prompt;
  final Map<String, dynamic>? options;
}

class ImagePrompt {
  ImagePrompt({required this.prompt, this.width = 512, this.height = 512, this.options});
  final String prompt;
  final int width;
  final int height;
  final Map<String, dynamic>? options;
}

/// قدرات أساسية كواجهات مجردة
abstract class TextGeneration {
  Future<String> generateText(TextPrompt prompt);
}

abstract class ImageGeneration {
  Future<Uint8List> generateImage(ImagePrompt prompt);
}

abstract class SpeechSynthesis {
  Future<Uint8List> synthesizeSpeech(String text, {String? voice});
}

abstract class Vision {
  Future<String> analyzeImage(Uint8List imageBytes, {String? task});
}

abstract class VideoGeneration {
  Future<Uint8List> generateVideo(String prompt, {Duration? duration});
}
