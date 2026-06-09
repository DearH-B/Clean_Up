class ProductCodeParseResult {
  const ProductCodeParseResult({
    required this.rawValue,
    required this.searchQuery,
    this.sourceUrl,
  });

  final String rawValue;
  final String searchQuery;
  final String? sourceUrl;
}

ProductCodeParseResult parseProductCode(String rawValue) {
  final value = rawValue.trim();
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return ProductCodeParseResult(rawValue: value, searchQuery: value);
  }

  const preferredKeys = [
    'model',
    'modelno',
    'model_no',
    'modelname',
    'product',
    'productid',
    'item',
    'gtin',
    'ean',
    'upc',
  ];
  final normalizedParameters = <String, String>{
    for (final entry in uri.queryParameters.entries)
      entry.key.toLowerCase(): entry.value,
  };

  for (final key in preferredKeys) {
    final candidate = normalizedParameters[key]?.trim();
    if (candidate != null && candidate.isNotEmpty) {
      return ProductCodeParseResult(
        rawValue: value,
        searchQuery: candidate,
        sourceUrl: value,
      );
    }
  }

  final pathSegments = uri.pathSegments
      .map(Uri.decodeComponent)
      .where((segment) => segment.trim().isNotEmpty)
      .toList();
  final lastSegment = pathSegments.isEmpty ? '' : pathSegments.last.trim();
  final usefulPathSegment = lastSegment.contains('.') ? '' : lastSegment;

  return ProductCodeParseResult(
    rawValue: value,
    searchQuery: usefulPathSegment.isEmpty ? value : usefulPathSegment,
    sourceUrl: value,
  );
}
