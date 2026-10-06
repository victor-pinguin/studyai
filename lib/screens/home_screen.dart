import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/utils.dart';
import '../models/study_task.dart';
import '../services/ocr/ocr_service.dart';
import '../state/app_state.dart';
import '../widgets/snappy.dart';
import '../widgets/common.dart';
import '../widgets/learn_menu.dart';
import '../widgets/task_tile.dart';
import 'pro_screen.dart';
import 'task_screen.dart';
import 'german_screen.dart';
import 'times_table_screen.dart';
import 'vocab_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;

  static const _samples = [
    ('Gleichung', '2x + 3 = 11'),
    ('Klammern auflösen', '3(x + 2) = 2x + 1'),
    ('Punkt vor Strich', 'Berechne: 12 + 7 · 3'),
    ('Biologie', 'Erkläre, wie die Photosynthese in Pflanzen funktioniert.'),
  ];

  // ---------------------------------------------------------------------------
  // Aktionen
  // ---------------------------------------------------------------------------

  Future<void> _pickImage(ImageSource source) async {
    final app = context.read<AppState>();
    final ocr = context.read<OcrService>();
    final maxDim = app.limits.maxImageDimension;

    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: maxDim,
        maxHeight: maxDim,
        imageQuality: 85,
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack(source == ImageSource.camera
          ? 'Kamera nicht verfügbar. Prüfe die Berechtigung oder wähle ein Bild aus.'
          : 'Das Bild konnte nicht geladen werden.');
      return;
    }
    if (file == null || !mounted) return; // Nutzer hat abgebrochen

    setState(() => _busy = true);
    var bytes = Uint8List(0);
    var text = '';
    String? hint;
    try {
      bytes = await file.readAsBytes();
      if (ocr.isSupported) {
        try {
          text = await ocr.recognizeText(file.path);
        } catch (_) {
          hint = 'Die Texterkennung hat nicht geklappt – bitte tippe die Aufgabe ab.';
        }
        if (text.isEmpty && hint == null) {
          hint = 'Kein Text erkannt. Tipp: Gutes Licht, Blatt gerade halten und '
              'die Aufgabe formatfüllend fotografieren.';
        }
      } else {
        hint = 'Automatische Texterkennung gibt es nur auf Android und iPhone. '
            'Bitte tippe die Aufgabe hier ab.';
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _showSnack('Das Bild konnte nicht gelesen werden.');
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TaskScreen(initialText: text, imageBytes: bytes, hint: hint),
    ));
  }

  void _openTaskScreen(String text) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskScreen(initialText: text)));

  void _openTask(StudyTask task) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TaskScreen(task: task, initialText: task.text)));

  void _openPro() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ProScreen()));

  Future<void> _chooseSample() async {
    final theme = Theme.of(context);
    final text = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Beispielaufgabe wählen', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            for (final (label, sample) in _samples)
              ListTile(
                leading: const Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.violet),
                title: Text(label, style: theme.textTheme.titleSmall),
                subtitle: Text(sample,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.mono(context, size: 12.5)),
                trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
                onTap: () => Navigator.pop(context, sample),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (text == null || !mounted) return;
    _openTaskScreen(text);
  }

  void _showSnack(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final recent = app.tasks.take(4).toList();

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              children: [
                FadeSlideIn(
                    child: _Hero(
                        onTheme: app.cycleThemeMode,
                        onMenu: () => showLearnMenu(context))),
                const SizedBox(height: 14),

                FadeSlideIn(
                  index: 1,
                  child: _ShotCard(
                    icon: Icons.photo_camera_rounded,
                    title: 'Aufgabe fotografieren',
                    subtitle: 'Die App liest den Text selbst',
                    primary: true,
                    onTap: _busy ? null : () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  index: 2,
                  child: _ShotCard(
                    icon: Icons.photo_library_rounded,
                    title: 'Bild auswählen',
                    subtitle: 'Ein Foto aus deiner Galerie',
                    onTap: _busy ? null : () => _pickImage(ImageSource.gallery),
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  index: 3,
                  child: _ShotCard(
                    icon: Icons.grid_on_rounded,
                    title: 'Einmaleins üben',
                    subtitle: 'Die Reihen 1 bis 9 – ohne Hilfe-Limit',
                    accent: AppTheme.leaf,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const TimesTableScreen())),
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  index: 4,
                  child: _ShotCard(
                    icon: Icons.translate_rounded,
                    title: '${app.learnLanguage.label} üben',
                    subtitle: 'Vokabeln nach Themen – ohne Hilfe-Limit',
                    accent: AppTheme.coral,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const VocabScreen())),
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  index: 5,
                  child: _ShotCard(
                    icon: Icons.spellcheck_rounded,
                    title: 'Deutsch üben',
                    subtitle: 'der/die/das und richtige Schreibweise',
                    accent: AppTheme.sky,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GermanScreen())),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickButton(
                        icon: Icons.keyboard_rounded,
                        label: 'Eintippen',
                        onTap: () => _openTaskScreen(''),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickButton(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Beispiel',
                        onTap: _chooseSample,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tageslimit
                AppCard(
                  onTap: _openPro,
                  padding: const EdgeInsets.fromLTRB(17, 15, 17, 17),
                  radius: 22,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded,
                              size: 18, color: AppTheme.violet),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Noch ${app.remainingAiRequests} von '
                              '${app.limits.dailyAiRequests} Hilfen für heute',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (app.isPro)
                            const ProBadge()
                          else
                            Icon(Icons.arrow_forward_rounded,
                                size: 18, color: muted),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GradientMeter(
                        value: app.limits.dailyAiRequests == 0
                            ? 0
                            : app.remainingAiRequests / app.limits.dailyAiRequests,
                        height: 7,
                      ),
                    ],
                  ),
                ),

                SectionHeader(
                  'Meine Aufgaben',
                  action: app.tasks.length > 4
                      ? TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AllTasksScreen()),
                          ),
                          child: const Text('Alle ansehen'),
                        )
                      : null,
                ),
                if (recent.isEmpty)
                  AppCard(
                    child: Row(
                      children: [
                        const IconBubble(
                            icon: Icons.inbox_rounded, color: AppTheme.violet),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Noch nichts da. Fotografiere deine erste Aufgabe '
                            'oder probiere ein Beispiel!',
                            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (var i = 0; i < recent.length; i++)
                    FadeSlideIn(
                      index: i,
                      child: TaskTile(
                        task: recent[i],
                        onTap: () => _openTask(recent[i]),
                      ),
                    ),
              ],
            ),
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.42),
                child: Center(
                  child: AppCard(
                    padding: const EdgeInsets.all(30),
                    shadow: true,
                    child: const ThinkingIndicator(message: 'Text wird erkannt …'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Farbige Begrüßungskarte ganz oben.
class _Hero extends StatelessWidget {
  const _Hero({required this.onTheme, required this.onMenu});

  final VoidCallback onTheme;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Guten Morgen!'
        : hour < 18
            ? 'Was möchtest du üben?'
            : 'Guten Abend!';
    final themeIcon = switch (app.themeMode) {
      ThemeMode.system => Icons.brightness_auto_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
    };

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.violet.withValues(alpha: 0.45),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              right: -60,
              top: -70,
              child: _Blob(size: 210, color: Colors.white.withValues(alpha: 0.16)),
            ),
            Positioned(
              left: -50,
              bottom: -80,
              child: _Blob(
                  size: 170, color: const Color(0xFFB8F13C).withValues(alpha: 0.22)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Snappy(size: 66),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hallo! Ich bin Snappy',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(color: Colors.white)),
                            const SizedBox(height: 6),
                            Text(
                              '$greeting Zeig mir deine Aufgabe – ich erkläre '
                              'sie dir Schritt für Schritt.',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 14.5,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onTheme,
                        tooltip: 'Hell oder dunkel',
                        icon: Icon(themeIcon, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: onMenu,
                        tooltip: 'Menü: Fächer und Sprache',
                        icon: const Icon(Icons.menu_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          '${app.starCount} Sterne · '
                          '${app.streakDays} ${app.streakDays == 1 ? 'Tag' : 'Tage'} in Folge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Große Aktionskarte (Foto / Galerie).
class _ShotCard extends StatelessWidget {
  const _ShotCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool primary;

  /// Eigene Farbe für das Symbol (z. B. Grün für das Einmaleins).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      shadow: true,
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          if (primary)
            const GradientBubble(icon: Icons.photo_camera_rounded, size: 56)
          else
            IconBubble(icon: icon, color: accent ?? AppTheme.violet, size: 50),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded,
              color: primary
                  ? AppTheme.violet
                  : (accent ?? theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Kleiner gestrichelter Sekundär-Button.
class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderColor(context), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: theme.colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alle gespeicherten Aufgaben. Wischen zum Löschen.
class AllTasksScreen extends StatelessWidget {
  const AllTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tasks = app.tasks;
    return Scaffold(
      appBar: AppBar(title: const Text('Alle Aufgaben')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: tasks.length,
        itemBuilder: (context, i) {
          final task = tasks[i];
          return Dismissible(
            key: ValueKey(task.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(Icons.delete_rounded, color: AppTheme.coral),
            ),
            onDismissed: (_) => context.read<AppState>().deleteTask(task.id),
            child: TaskTile(
              task: task,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TaskScreen(task: task, initialText: task.text),
              )),
            ),
          );
        },
      ),
    );
  }
}
