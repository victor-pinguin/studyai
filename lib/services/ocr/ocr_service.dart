import 'ocr_stub.dart' if (dart.library.io) 'ocr_mlkit.dart';

/// Texterkennung (OCR) aus Bildern.
///
/// Auf Android und iOS übernimmt Google ML Kit die Erkennung – offline,
/// kostenlos, ohne Konto. Im Browser gibt es ML Kit nicht; dort tippt man
/// die Aufgabe ein. Welche Fassung geladen wird, entscheidet der Import
/// oben beim Kompilieren: Das Web bekommt den ML-Kit-Code gar nicht erst
/// zu sehen, deshalb lässt sich die App auch für den Browser bauen.
abstract class OcrService {
  /// Funktioniert die Texterkennung auf diesem Gerät?
  bool get isSupported;

  /// Liefert den erkannten Text (leer, wenn nichts gefunden wurde).
  Future<String> recognizeText(String imagePath);

  Future<void> dispose();
}

/// Wählt automatisch die passende Fassung.
OcrService createOcrService() => createPlatformOcrService();
