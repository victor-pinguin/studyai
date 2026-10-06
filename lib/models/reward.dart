import 'package:flutter/material.dart';

/// Ein Sticker aus der Sammlung. Sticker gibt es als Belohnung für gute Quizze.
class Sticker {
  const Sticker({required this.id, required this.name, required this.icon});

  final String id;
  final String name;
  final IconData icon;

  /// Reihenfolge, in der die Sticker freigeschaltet werden.
  static const List<Sticker> all = [
    Sticker(id: 's1', name: 'Sternchen', icon: Icons.star_rounded),
    Sticker(id: 's2', name: 'Rakete', icon: Icons.rocket_launch_rounded),
    Sticker(id: 's3', name: 'Medaille', icon: Icons.military_tech_rounded),
    Sticker(id: 's4', name: 'Feuer', icon: Icons.local_fire_department_rounded),
    Sticker(id: 's5', name: 'Schlaukopf', icon: Icons.psychology_rounded),
    Sticker(id: 's6', name: 'Blitz', icon: Icons.bolt_rounded),
    Sticker(id: 's7', name: 'Krone', icon: Icons.workspace_premium_rounded),
    Sticker(id: 's8', name: 'Forscher', icon: Icons.science_rounded),
    Sticker(id: 's9', name: 'Bücherwurm', icon: Icons.menu_book_rounded),
    Sticker(id: 's10', name: 'Einmaleins', icon: Icons.grid_on_rounded),
    Sticker(id: 's11', name: 'Rechenprofi', icon: Icons.calculate_rounded),
    Sticker(id: 's12', name: 'Quizmeister', icon: Icons.emoji_events_rounded),
  ];

  static Sticker? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// Gold gibt es für alles richtig, Silber ab 80 %.
enum RewardTier {
  gold('Gold'),
  silver('Silber');

  const RewardTier(this.label);
  final String label;
}

/// Ein bereits gesammelter Sticker.
class EarnedSticker {
  const EarnedSticker({required this.stickerId, required this.tier});

  final String stickerId;
  final RewardTier tier;

  Sticker? get sticker => Sticker.byId(stickerId);

  String encode() => '$stickerId:${tier.name}';

  static EarnedSticker? decode(String raw) {
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final sticker = Sticker.byId(parts[0]);
    if (sticker == null) return null;
    for (final t in RewardTier.values) {
      if (t.name == parts[1]) {
        return EarnedSticker(stickerId: sticker.id, tier: t);
      }
    }
    return null;
  }
}

/// Das, was es direkt nach einem Quiz zu feiern gibt.
class Reward {
  const Reward({required this.tier, required this.bonusStars, this.sticker});

  final RewardTier tier;
  final int bonusStars;

  /// Null, wenn schon alle Sticker gesammelt sind.
  final Sticker? sticker;
}
