import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studysnap_ai/app.dart';
import 'package:studysnap_ai/services/ai/mock_ai_service.dart';
import 'package:studysnap_ai/services/ocr/ocr_service.dart';
import 'package:studysnap_ai/services/storage/study_repository.dart';
import 'package:studysnap_ai/state/app_state.dart';

void main() {
  testWidgets('Startseite zeigt Logo und Buttons', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final state = AppState(LocalStudyRepository(prefs));
    await state.load();

    await tester.pumpWidget(StudySnapApp(
      appState: state,
      aiService: MockAiService(delay: Duration.zero),
      ocrService: UnsupportedOcrService(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('StudySnap'), findsOneWidget);
    expect(find.text('Aufgabe fotografieren'), findsOneWidget);
    expect(find.text('Bild auswählen'), findsOneWidget);
  });
}
