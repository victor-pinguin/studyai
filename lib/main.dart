import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/ai/ai_service.dart';
import 'services/ocr/ocr_service.dart';
import 'services/storage/study_repository.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Speicher vorbereiten und gespeicherte Daten laden
  final prefs = await SharedPreferences.getInstance();
  final appState = AppState(LocalStudyRepository(prefs));
  await appState.load();

  // 2) App starten – Services werden hier „eingesteckt“.
  //    Später z. B.: Login-Service, Cloud-Repository, Bezahl-Service.
  runApp(StudySnapApp(
    appState: appState,
    aiService: createAiService(),
    ocrService: createOcrService(),
  ));
}
