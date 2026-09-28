import '../../../core/utils/formatters.dart';
import 'search_filters.dart';

/// Interpreta frases como:
///   "caballos cuarto de milla menores de 8 años"
///   "borregos de engorda de 35 a 50 kg"
///   "chile habanero más de 500 kg"
///   "miel multifloral por mayoreo"
///
/// ⚠️ En producción esta interpretación vive en el BACKEND (una sola lógica para
/// móvil y web). Aquí existe para que el prototipo se sienta real.
class ParsedQuery {
  const ParsedQuery({
    required this.terms,
    required this.ranges,
    required this.wholesale,
    required this.chips,
  });

  final List<String> terms;
  final Map<String, NumRange> ranges; // clave de atributo -> rango
  final bool wholesale;
  final List<String> chips; // interpretación legible para el usuario

  bool get isEmpty => terms.isEmpty && ranges.isEmpty && !wholesale;
}

const _stopwords = {
  'de', 'del', 'la', 'el', 'los', 'las', 'por', 'en', 'y', 'a', 'con', 'para',
  'un', 'una', 'que', 'se', 'vendo', 'busco', 'venta',
};

ParsedQuery parseQuery(String raw) {
  var text = normalize(raw);
  final ranges = <String, NumRange>{};
  final chips = <String>[];
  var wholesale = false;

  // "menores de 8 años" / "menos de 18 meses"
  final age = RegExp(r'(menor(?:es)? de|menos de)\s+(\d+)\s*(anos|ano|meses|mes)');
  final ageMatch = age.firstMatch(text);
  if (ageMatch != null) {
    final n = double.parse(ageMatch.group(2)!);
    final years = ageMatch.group(3)!.startsWith('ano');
    ranges['edad_anios'] = NumRange(max: years ? n : n / 12);
    ranges['edad_meses'] = NumRange(max: years ? n * 12 : n);
    chips.add('Edad ≤ ${n.toStringAsFixed(0)} ${years ? 'años' : 'meses'}');
    text = text.replaceFirst(ageMatch.group(0)!, ' ');
  }

  // "de 35 a 50 kg"
  final between = RegExp(r'de\s+(\d+(?:\.\d+)?)\s*a\s*(\d+(?:\.\d+)?)\s*kg');
  final betweenMatch = between.firstMatch(text);
  if (betweenMatch != null) {
    final a = double.parse(betweenMatch.group(1)!);
    final b = double.parse(betweenMatch.group(2)!);
    ranges['peso'] = NumRange(min: a, max: b);
    chips.add('Peso ${a.toStringAsFixed(0)}–${b.toStringAsFixed(0)} kg');
    text = text.replaceFirst(betweenMatch.group(0)!, ' ');
  }

  // "más de 500 kg" / "mas de 2 toneladas"
  final over = RegExp(r'(mas de|mayor(?:es)? de|minimo)\s+(\d+(?:\.\d+)?)\s*(kg|toneladas|tonelada|ton)');
  final overMatch = over.firstMatch(text);
  if (overMatch != null) {
    var n = double.parse(overMatch.group(2)!);
    if (overMatch.group(3)!.startsWith('ton')) n *= 1000;
    ranges['disponible_kg'] = NumRange(min: n);
    chips.add('Disponible ≥ ${formatMoney(n).substring(1)} kg');
    text = text.replaceFirst(overMatch.group(0)!, ' ');
  }

  if (text.contains('mayoreo')) {
    wholesale = true;
    chips.add('Venta por mayoreo');
    text = text.replaceAll('mayoreo', ' ');
  }

  final terms = text
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.length > 1 && !_stopwords.contains(t))
      .toList();

  return ParsedQuery(terms: terms, ranges: ranges, wholesale: wholesale, chips: chips);
}

/// Coincidencia tolerante a plurales: "caballos" encuentra "caballo", "chiles" -> "chile".
bool termMatches(String haystack, String term) {
  if (haystack.contains(term)) return true;
  if (term.endsWith('es') && term.length > 4 && haystack.contains(term.substring(0, term.length - 2))) {
    return true;
  }
  if (term.endsWith('s') && term.length > 3 && haystack.contains(term.substring(0, term.length - 1))) {
    return true;
  }
  return false;
}
