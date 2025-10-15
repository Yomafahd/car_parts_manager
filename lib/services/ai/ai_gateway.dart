import 'dart:typed_data';

import 'ai_capabilities.dart';

/// بوابة مركزية لتوجيه الطلبات إلى مزود محدد
class AiGateway implements TextGeneration, ImageGeneration, SpeechSynthesis, Vision, VideoGeneration {
  AiGateway({this.textGen, this.imageGen, this.speech, this.vision, this.video});

  final TextGeneration? textGen;
  final ImageGeneration? imageGen;
  final SpeechSynthesis? speech;
  final Vision? vision;
  final VideoGeneration? video;

  @override
  Future<String> generateText(TextPrompt prompt) async {
    final impl = textGen;
    if (impl == null) throw StateError('No TextGeneration provider configured');
    return impl.generateText(prompt);
  }

  @override
  Future<Uint8List> generateImage(ImagePrompt prompt) async {
    final impl = imageGen;
    if (impl == null) throw StateError('No ImageGeneration provider configured');
    return impl.generateImage(prompt);
  }

  @override
  Future<Uint8List> synthesizeSpeech(String text, {String? voice}) async {
    final impl = speech;
    if (impl == null) throw StateError('No SpeechSynthesis provider configured');
    return impl.synthesizeSpeech(text, voice: voice);
  }

  @override
  Future<String> analyzeImage(Uint8List imageBytes, {String? task}) async {
    final impl = vision;
    if (impl == null) throw StateError('No Vision provider configured');
    return impl.analyzeImage(imageBytes, task: task);
  }

  @override
  Future<Uint8List> generateVideo(String prompt, {Duration? duration}) async {
    final impl = video;
    if (impl == null) throw StateError('No VideoGeneration provider configured');
    return impl.generateVideo(prompt, duration: duration);
  }
}
