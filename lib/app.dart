import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'screens/main_shell.dart';
import 'services/ai/ai_service.dart';
import 'services/ocr/ocr_service.dart';
import 'state/app_state.dart';

class StudySnapApp extends StatelessWidget {
  const StudySnapApp({
    super.key,
    required this.appState,
    required this.aiService,
    required this.ocrService,
  });

  final AppState appState;
  final AiService aiService;
  final OcrService ocrService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        Provider<AiService>.value(value: aiService),
        Provider<OcrService>.value(value: ocrService),
      ],
      child: Consumer<AppState>(
        builder: (context, state, child) => MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: state.themeMode,
          locale: const Locale('de'),
          supportedLocales: const [Locale('de'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MainShell(),
        ),
      ),
    );
  }
}
