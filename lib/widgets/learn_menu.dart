import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/vocab.dart';
import '../screens/german_screen.dart';
import '../screens/times_table_screen.dart';
import '../screens/vocab_screen.dart';
import '../state/app_state.dart';
import 'common.dart';
import 'snappy.dart';

/// Das Menü hinter den drei Strichen: Fach wählen und Lernsprache umstellen.
Future<void> showLearnMenu(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LearnMenu(),
  );
}

class _LearnMenu extends StatelessWidget {
  const _LearnMenu();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);

    void open(Widget screen) {
      Navigator.of(context).pop();
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => screen));
    }

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppTheme.borderColor(context),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SnappyBubble(
              text: 'Was möchtest du üben?',
              size: 54,
            ),
            const SectionHeader('Fächer'),
            _MenuTile(
              icon: Icons.grid_on_rounded,
              color: AppTheme.leaf,
              title: 'Mathe',
              subtitle: 'Einmaleins, die Reihen 1 bis 9',
              onTap: () => open(const TimesTableScreen()),
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.spellcheck_rounded,
              color: AppTheme.sky,
              title: 'Deutsch',
              subtitle: 'der/die/das und richtige Schreibweise',
              onTap: () => open(const GermanScreen()),
            ),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.translate_rounded,
              color: AppTheme.coral,
              title: app.learnLanguage.label,
              subtitle: 'Vokabeln nach Themen',
              onTap: () => open(const VocabScreen()),
            ),
            const SectionHeader('Deine Lernsprache'),
            for (final language in LearnLanguage.values) ...[
              _LanguageTile(
                language: language,
                selected: app.learnLanguage == language,
                onTap: () => context.read<AppState>().setLearnLanguage(language),
              ),
              const SizedBox(height: 10),
            ],
            const SectionHeader('Ton'),
            _MenuTile(
              icon: app.soundOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: AppTheme.leaf,
              title: app.soundOn ? 'Töne an' : 'Töne aus',
              subtitle: 'Klänge bei richtigen und falschen Antworten',
              onTap: () => context.read<AppState>().toggleSound(),
            ),
            const SectionHeader('Aussehen'),
            _MenuTile(
              icon: switch (app.themeMode) {
                ThemeMode.system => Icons.brightness_auto_rounded,
                ThemeMode.light => Icons.light_mode_rounded,
                ThemeMode.dark => Icons.dark_mode_rounded,
              },
              color: AppTheme.violet,
              title: switch (app.themeMode) {
                ThemeMode.system => 'Wie das Handy',
                ThemeMode.light => 'Hell',
                ThemeMode.dark => 'Dunkel',
              },
              subtitle: 'Zum Umschalten tippen',
              onTap: () => context.read<AppState>().cycleThemeMode(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
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
          Icon(Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final LearnLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? AppTheme.violet.withValues(alpha: .12)
          : AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: selected ? AppTheme.violet : AppTheme.borderColor(context),
          width: selected ? 2.5 : 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              FlagStripes(language: language, width: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(language.label, style: theme.textTheme.titleMedium),
                    Text('${language.country} · ${language.greeting}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? AppTheme.violet
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: .5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
