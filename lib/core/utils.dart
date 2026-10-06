/// Kleine Hilfsfunktionen ohne zusätzliche Pakete.
class Utils {
  Utils._();

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  static const _weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  static String weekdayShort(DateTime date) => _weekdays[date.weekday - 1];

  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// „Heute“, „Gestern“ oder „11.09.“
  static String relativeDate(DateTime date) {
    final today = dayOnly(DateTime.now());
    final day = dayOnly(date);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Heute';
    if (diff == 1) return 'Gestern';
    return '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.';
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Guten Morgen!';
    if (hour < 18) return 'Hallo!';
    return 'Guten Abend!';
  }
}
