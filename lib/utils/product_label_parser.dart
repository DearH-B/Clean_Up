class ProductLabelCandidate {
  const ProductLabelCandidate({
    required this.value,
    required this.score,
  });

  final String value;
  final int score;
}

List<ProductLabelCandidate> extractProductLabelCandidates(String text) {
  final candidates = <String, int>{};
  final lines = text
      .split(RegExp(r'[\r\n]+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    final normalizedLine = line.toUpperCase();
    final hasModelLabel = RegExp(
      r'(MODEL|MODEL\s*NO|모델|모델명|품번|형명)',
      caseSensitive: false,
    ).hasMatch(line);
    final tokens = normalizedLine
        .replaceAll(RegExp(r'[^A-Z0-9\-_/. ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty);

    for (final token in tokens) {
      final cleaned = token
          .replaceAll(RegExp(r'^[./_-]+|[./_-]+$'), '')
          .replaceAll('/', '-');
      if (!_looksLikeModelName(cleaned)) {
        continue;
      }
      var score = 10;
      if (hasModelLabel) score += 50;
      if (RegExp(r'[A-Z]').hasMatch(cleaned)) score += 10;
      if (RegExp(r'\d').hasMatch(cleaned)) score += 10;
      if (cleaned.contains('-')) score += 8;
      if (cleaned.length >= 8) score += 6;
      candidates.update(
        cleaned,
        (current) => current > score ? current : score,
        ifAbsent: () => score,
      );
    }

    if (hasModelLabel && index + 1 < lines.length) {
      final nextLine = lines[index + 1].toUpperCase().trim();
      if (_looksLikeModelName(nextLine)) {
        candidates.update(
          nextLine,
          (current) => current > 65 ? current : 65,
          ifAbsent: () => 65,
        );
      }
    }
  }

  final sorted = [
    for (final entry in candidates.entries)
      ProductLabelCandidate(value: entry.key, score: entry.value),
  ]..sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      return scoreComparison != 0
          ? scoreComparison
          : b.value.length.compareTo(a.value.length);
    });
  return sorted.take(6).toList();
}

bool _looksLikeModelName(String value) {
  if (value.length < 4 || value.length > 32 || value.contains(' ')) {
    return false;
  }
  if (!RegExp(r'[A-Z]').hasMatch(value) || !RegExp(r'\d').hasMatch(value)) {
    return false;
  }
  const excluded = {
    '220V',
    '230V',
    '240V',
    '50HZ',
    '60HZ',
    '50-60HZ',
    'MADEIN',
  };
  if (excluded.contains(value)) {
    return false;
  }
  return RegExp(r'^[A-Z0-9][A-Z0-9._/-]*$').hasMatch(value);
}
