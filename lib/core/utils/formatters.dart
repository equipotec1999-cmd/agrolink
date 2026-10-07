/// Formato de moneda MXN sin dependencias externas: 85000 -> "$85,000".
String formatMoney(num value) {
  final negative = value < 0;
  final digits = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return '${negative ? '-' : ''}\$$buffer';
}

/// Formato de cantidad sin signo de moneda: 1500 -> "1,500", 0.5 -> "0.5".
String formatQuantity(num value) {
  if (value == value.roundToDouble()) return formatMoney(value).replaceAll('\$', '');
  // Para decimales, deja hasta 2 lugares y limpia ceros a la derecha.
  final text = value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  final parts = text.split('.');
  final intPart = formatMoney(num.parse(parts[0])).replaceAll('\$', '');
  return parts.length == 2 ? '$intPart.${parts[1]}' : intPart;
}

String formatTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.hour)}:${two(d.minute)}';
}

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'ayer';
  return 'hace ${diff.inDays} días';
}

/// Normaliza texto para búsqueda: minúsculas y sin acentos.
String normalize(String input) {
  const from = 'áéíóúüñÁÉÍÓÚÜÑ';
  const to = 'aeiouunaeiouun';
  final buffer = StringBuffer();
  for (final ch in input.split('')) {
    final i = from.indexOf(ch);
    buffer.write(i >= 0 ? to[i] : ch);
  }
  return buffer.toString().toLowerCase();
}
