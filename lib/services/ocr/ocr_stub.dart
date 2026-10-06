import 'ocr_service.dart';

/// Für Browser und Desktop: Dort gibt es kein ML Kit – der Text wird getippt.
///
/// Wenn du später auch im Browser erkennen willst, kommt hier eine
/// Server-Variante hinein (Bild hochladen, Text zurückbekommen).
class UnsupportedOcrService implements OcrService {
  @override
  bool get isSupported => false;

  @override
  Future<String> recognizeText(String imagePath) async => '';

  @override
  Future<void> dispose() async {}
}

OcrService createPlatformOcrService() => UnsupportedOcrService();
