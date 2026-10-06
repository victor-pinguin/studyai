import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_service.dart';
import 'ocr_stub.dart' show UnsupportedOcrService;

/// Kostenlose Texterkennung von Google ML Kit – läuft offline auf dem Gerät.
class MlKitOcrService implements OcrService {
  TextRecognizer? _recognizer;

  @override
  bool get isSupported => true;

  @override
  Future<String> recognizeText(String imagePath) async {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    final input = InputImage.fromFilePath(imagePath);
    final result = await _recognizer!.processImage(input);
    return result.text.trim();
  }

  @override
  Future<void> dispose() async {
    await _recognizer?.close();
  }
}

/// Nur Android und iOS haben ML Kit – Windows, macOS und Linux nicht.
OcrService createPlatformOcrService() {
  final isMobile = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  return isMobile ? MlKitOcrService() : UnsupportedOcrService();
}
