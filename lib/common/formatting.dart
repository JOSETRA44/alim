/// Formatea la hora/fecha de un mensaje para listas y burbujas.
/// Sin dependencia de intl en el Hito 1; se sustituirá al añadir i18n.
String formatMessageTime(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final day = DateTime(time.year, time.month, time.day);

  String two(int value) => value.toString().padLeft(2, '0');

  if (day == today) return '${two(time.hour)}:${two(time.minute)}';
  if (today.difference(day).inDays == 1) return 'ayer';
  return '${two(time.day)}/${two(time.month)}';
}
