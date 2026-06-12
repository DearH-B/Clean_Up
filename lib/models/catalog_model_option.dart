class CatalogModelOption {
  const CatalogModelOption({
    required this.modelName,
    required this.displayName,
    this.releaseYear,
    this.imageUrl,
    this.productUrl,
    this.features = const [],
  });

  final String modelName;
  final String displayName;
  final int? releaseYear;
  final String? imageUrl;
  final String? productUrl;
  final List<String> features;

  factory CatalogModelOption.fromJson(Map<String, Object?> json) {
    return CatalogModelOption(
      modelName: json['modelName'] as String,
      displayName:
          json['displayName'] as String? ?? json['modelName'] as String,
      releaseYear: json['releaseYear'] as int?,
      imageUrl: json['imageUrl'] as String?,
      productUrl: json['productUrl'] as String?,
      features: (json['features'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }
}
