String toUserMessage(Object? error, {String fallback = 'Произошла ошибка. Попробуйте снова.'}) {
  final raw = (error ?? '').toString().trim();
  if (raw.isEmpty) return fallback;
  if (raw.startsWith('Exception: ')) {
    final stripped = raw.substring('Exception: '.length).trim();
    return stripped.isEmpty ? fallback : stripped;
  }
  return raw;
}
