class ProductSpace {
  const ProductSpace({
    required this.id,
    required this.name,
    required this.description,
    required this.productCount,
    required this.identifiedProductCount,
  });

  final String id;
  final String name;
  final String description;
  final int productCount;
  final int identifiedProductCount;

  double get identificationProgress {
    if (productCount == 0) {
      return 0;
    }
    return identifiedProductCount / productCount;
  }

  factory ProductSpace.fromJson(Map<String, Object?> json) {
    return ProductSpace(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      productCount:
          json['productCount'] as int? ?? json['taskCount'] as int? ?? 0,
      identifiedProductCount: json['identifiedProductCount'] as int? ??
          json['completedTaskCount'] as int? ??
          0,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'productCount': productCount,
      'identifiedProductCount': identifiedProductCount,
    };
  }

  ProductSpace copyWith({
    String? id,
    String? name,
    String? description,
    int? productCount,
    int? identifiedProductCount,
  }) {
    return ProductSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      productCount: productCount ?? this.productCount,
      identifiedProductCount:
          identifiedProductCount ?? this.identifiedProductCount,
    );
  }
}
