class ProductSearchRequest {
  const ProductSearchRequest({
    required this.id,
    required this.query,
    required this.requestedAt,
    required this.registeredAsGeneral,
    this.categoryName,
    this.brand,
    this.modelName,
  });

  final String id;
  final String query;
  final String? categoryName;
  final String? brand;
  final String? modelName;
  final DateTime requestedAt;
  final bool registeredAsGeneral;

  factory ProductSearchRequest.fromJson(Map<String, Object?> json) {
    return ProductSearchRequest(
      id: json['id'] as String,
      query: json['query'] as String,
      categoryName: json['categoryName'] as String?,
      brand: json['brand'] as String?,
      modelName: json['modelName'] as String?,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      registeredAsGeneral: json['registeredAsGeneral'] as bool? ?? false,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'query': query,
      'categoryName': categoryName,
      'brand': brand,
      'modelName': modelName,
      'requestedAt': requestedAt.toIso8601String(),
      'registeredAsGeneral': registeredAsGeneral,
    };
  }
}
