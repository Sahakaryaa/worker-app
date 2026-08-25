/// Shared formatting / safe-text helpers (RangeError-proof).
library;

String initialsOf(String name, {int max = 2}) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  final buf = StringBuffer();
  for (final p in parts.take(max)) {
    buf.write(p[0].toUpperCase());
  }
  return buf.toString();
}

String titleCase(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return '';
  return s[0].toUpperCase() + s.substring(1);
}

/// Normalizes a phone input to bare 10 digits (India).
/// Returns null when the input cannot yield exactly 10 digits.
String? normalizePhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length > 10 && digits.startsWith('91')) {
    return digits.substring(digits.length - 10);
  }
  if (digits.length == 10) return digits;
  return null;
}

bool isValidPhone(String raw) => normalizePhone(raw) != null;
