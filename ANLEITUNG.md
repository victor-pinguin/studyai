# StudySnap AI – Schritt-für-Schritt-Anleitung

MVP-Version 0.1 · Flutter · Android & iOS · 0 € (Demo-KI, Texterkennung offline auf dem Gerät)

---

## 1. Was die Demo schon kann

| Funktion | Status in der Demo |
|---|---|
| Foto aufnehmen / Bild aus Galerie | ✅ echt (image_picker) |
| Text im Bild erkennen | ✅ echt, kostenlos, offline (Google ML Kit – nur Android/iPhone) |
| Erkannten Text korrigieren | ✅ |
| Erklären – Schritt für Schritt, Lösung erst am Ende | ✅ Mathe wird echt gelöst: lineare Gleichungen (auch mit Klammern, Brüchen, Dezimalzahlen, z. B. `3(x + 2) = 2x + 1`) und Rechenaufgaben mit Klammern / Punkt vor Strich. Geprüft mit über 50.000 Zufallsaufgaben – 0 Fehler. Potenzen, Wurzeln, Prozent und mehrdeutige Schreibweisen wie `6 : 2(1+2)` werden bewusst nicht gerechnet (lieber keine als eine falsche Lösung). Andere Fächer: strukturierte Lernanleitung, aber noch keine inhaltliche Musterlösung |
| Quiz mit 3–10 Fragen, Feedback nach jeder Antwort, Ergebnis | ✅ (Mathe: echte Übungsaufgaben, sonst allgemeine Fragen) |
| Fortschritt: gelöste Aufgaben, Quiz-Ergebnisse, Level/XP, Serie, Wochen-Diagramm | ✅ |
| Pro-Seite, Limits Free/Pro, Pro-Funktionen gesperrt | ✅ (Pro per Demo-Button, ohne Zahlung) |
| Dark Mode / Light Mode | ✅ (Symbol oben rechts auf der Startseite) |
| Design | ✅ kinderfreundlich: Maskottchen **Snappy** (gezeichnet, kein Bild nötig), runde Formen, große Knöpfe, helle Farben, Schriften Fredoka + Nunito + DM Mono (Paket `google_fonts`), Sterne statt Punkte |
| Einmaleins-Trainer | ✅ Reihen 1–9 oder gemischt, 10 Aufgaben, Sterne am Ende – ohne KI und ohne Tageslimit |
| Verlauf „Meine letzten Aufgaben“ | ✅ lokal auf dem Gerät gespeichert |

Kostenlos: 15 KI-Anfragen pro Tag, Quiz bis 5 Fragen (der Einmaleins-Trainer ist immer frei). Pro: 200 Anfragen, 10 Fragen, „Warum?“-Erklärungen, Fach-Statistik, Lernplan. Die Werte stehen in `lib/core/app_config.dart`.

---

## 2. Voraussetzungen (einmalig)

1. **Flutter installieren:** https://docs.flutter.dev/get-started/install → dein Betriebssystem wählen.
2. **Android Studio** installieren (bringt Android SDK und Emulator mit). Dort unter *Device Manager* ein virtuelles Handy anlegen.
3. **Editor:** VS Code mit der Erweiterung „Flutter“ (oder direkt Android Studio).
4. Im Terminal prüfen:
   ```bash
   flutter doctor
   ```
   Alles, was rot ist, zuerst beheben (meistens: `flutter doctor --android-licenses`).
5. **iPhone:** Apps für iOS lassen sich nur auf einem **Mac mit Xcode** bauen. Unter Windows entwickelst und testest du mit Android – der Code ist derselbe.

---

## 3. Projekt anlegen

Im Terminal in den Ordner wechseln, in dem das Projekt liegen soll:

```bash
flutter create --org de.studysnap --platforms=android,ios studysnap_ai
cd studysnap_ai
```

> Der Name muss genau **studysnap_ai** sein – die Tests importieren `package:studysnap_ai/...`.

Flutter erzeugt dabei die Ordner `android/`, `ios/`, `lib/`, `test/` usw.

---

## 4. Code-Dateien einfügen

1. **Löschen:** den Inhalt von `lib/` (nur `main.dart`) und `test/widget_test.dart` – beide werden ersetzt.
2. **Kopieren:** Aus der ZIP-Datei die Ordner `lib/` und `test/` sowie die Datei `pubspec.yaml` in dein Projekt kopieren und vorhandene Dateien überschreiben.

Danach muss die Struktur so aussehen (Ordner, die es noch nicht gibt, einfach anlegen):

```
studysnap_ai/
├── pubspec.yaml                          ← ersetzt (Pakete)
├── lib/
│   ├── main.dart                         Startpunkt: lädt Daten, startet App
│   ├── app.dart                          MaterialApp, Theme, Provider
│   ├── core/
│   │   ├── app_config.dart               Limits Free/Pro, KI-URL
│   │   ├── app_theme.dart                Design-System: Farben, Schriften, Light/Dark
│   │   └── utils.dart                    Datum, IDs, Begrüßung
│   ├── models/
│   │   ├── subject.dart                  Fächer + automatische Erkennung
│   │   ├── study_task.dart               Aufgabe
│   │   ├── explanation.dart              Erklärung + Schritte
│   │   └── quiz.dart                     Quizfrage + Ergebnis
│   ├── services/
│   │   ├── ai/
│   │   │   ├── ai_service.dart           KI-Schnittstelle (+ Auswahl Demo/echt)
│   │   │   ├── mock_ai_service.dart      kostenlose Platzhalter-KI
│   │   │   ├── math_helper.dart          Mini-Mathe-Engine für die Demo
│   │   │   └── api_ai_service.dart       Vorlage für echte KI über dein Backend
│   │   ├── ocr/
│   │   │   └── ocr_service.dart          Texterkennung (ML Kit)
│   │   └── storage/
│   │       └── study_repository.dart     Speicherung (heute lokal, später Cloud)
│   ├── state/
│   │   └── app_state.dart                zentraler Zustand + Statistik
│   ├── screens/
│   │   ├── main_shell.dart               untere Navigation
│   │   ├── home_screen.dart              Startseite (+ „Alle Aufgaben“)
│   │   ├── task_screen.dart              erkannte Aufgabe bearbeiten
│   │   ├── explanation_screen.dart       Schritt-für-Schritt-Erklärung
│   │   ├── quiz_screen.dart              Quiz + Ergebnis
│   │   ├── times_table_screen.dart       Einmaleins-Trainer (Reihen 1–9)
│   │   ├── progress_screen.dart          Sterne & Statistik
│   │   └── pro_screen.dart               Plus-Seite
│   └── widgets/
│       ├── app_logo.dart                 Logo
│       ├── snappy.dart                   Maskottchen Snappy + Sterne
│       ├── common.dart                   Karten, Animationen, Pro-Sperre …
│       └── task_tile.dart                Listeneintrag Aufgabe
└── test/
    ├── math_helper_test.dart             Tests der Mathe-Logik und Demo-KI
    └── widget_test.dart                  Test der Startseite
```

3. **Pakete laden:**
   ```bash
   flutter pub get
   ```
   Falls eine Versions-Fehlermeldung kommt: `flutter pub upgrade --major-versions` und dann erneut `flutter pub get`.

---

## 5. Plattform-Einstellungen

Die fertigen Textbausteine liegen im Ordner `platform_setup/` der ZIP-Datei.

### Android
- **Zum Entwickeln/Testen: nichts zu tun.**
- Erst für eine Release-Version (`flutter build apk`): Datei `platform_setup/android/proguard-rules.pro` nach `android/app/proguard-rules.pro` kopieren.

### iOS (nur auf dem Mac)
1. `ios/Runner/Info.plist` öffnen und die Zeilen aus `platform_setup/ios/Info.plist-Ergaenzung.xml` innerhalb von `<dict> … </dict>` einfügen (Kamera- und Foto-Berechtigung).
2. In `ios/Podfile` die Zeile `platform :ios, '15.5'` setzen (siehe `Podfile-Hinweis.txt`), dann `cd ios && pod install && cd ..`.
3. ML Kit läuft am zuverlässigsten auf einem echten iPhone, nicht im Simulator.

---

## 6. App starten

```bash
flutter devices        # zeigt Emulator/Handy
flutter run            # startet die App
```

**Testen ohne Kamera:** Auf der Startseite „Beispiel testen“ antippen – z. B. `2x + 3 = 11` → „Erklären“ → „Nächster Schritt“ … → „Lösung anzeigen“ → „Quiz starten“.

**Echtes Handy (Android):** Entwickleroptionen + USB-Debugging aktivieren, per USB verbinden, `flutter run`. Die Texterkennung funktioniert am besten mit einem echten Foto (gutes Licht, Blatt gerade).

**Prüfen, ob alles sauber ist:**
```bash
flutter analyze
flutter test
```

---

## 7. So erweiterst du die App später

Die App ist in Schichten gebaut. Die Screens kennen nur Schnittstellen – du tauschst die Implementierung aus, ohne die Oberfläche anzufassen.

| Erweiterung | Was du tust | Datei |
|---|---|---|
| **Echte KI** | Kleines Backend bauen (z. B. Firebase Cloud Function, Supabase Edge Function, Cloudflare Worker), das die KI-API aufruft und JSON im Format aus `api_ai_service.dart` zurückgibt. Dann starten mit `flutter run --dart-define=AI_API_URL=https://dein-backend…` – die App nutzt automatisch `ApiAiService`. **API-Schlüssel nie in die App schreiben.** | `services/ai/api_ai_service.dart` |
| **Benutzerkonten** | z. B. `firebase_auth`; Login-Token im Header von `ApiAiService` mitsenden | neuer `services/auth/…` |
| **Cloud-Speicherung** | neue Klasse `CloudStudyRepository implements StudyRepository` (Firestore/Supabase) und in `main.dart` statt `LocalStudyRepository` einsetzen | `services/storage/` |
| **Pro bezahlen** | `in_app_purchase` oder RevenueCat; nach erfolgreichem Kauf `appState.setPro(true)`. Den Demo-Button entfernen. Limits zusätzlich im Backend prüfen (sonst umgehbar) | `screens/pro_screen.dart`, `state/app_state.dart` |
| **PDFs/Dokumente (Pro)** | `file_picker` + PDF-Text-Extraktion oder PDF direkt ans Backend | `screens/home_screen.dart` |
| **Limits ändern** | Zahlen anpassen | `core/app_config.dart` |

---

## 8. Häufige Probleme

| Problem | Lösung |
|---|---|
| `Target of URI doesn't exist: package:studysnap_ai/…` | Projekt heißt anders → mit `flutter create … studysnap_ai` neu anlegen oder in `pubspec.yaml` `name:` anpassen und die Imports in `test/` ändern |
| Kamera öffnet sich im Emulator nicht / zeigt nur Testbild | Normal. „Bild auswählen“ oder „Beispiel testen“ nutzen, oder echtes Handy |
| „Automatische Texterkennung gibt es nur auf Android und iPhone“ | Du startest als Web/Windows-App. Mit `flutter run -d <android-gerät>` starten |
| iOS: `pod install` Fehler zur Version | Podfile auf `platform :ios, '15.5'` stellen |
| Release-Build Android: „Missing classes … mlkit“ | `proguard-rules.pro` aus `platform_setup/android/` kopieren |
| Tageslimit im Test erreicht | Pro-Seite → „Pro testen (Demo)“, oder App-Daten löschen |
