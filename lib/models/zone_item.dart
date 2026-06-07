enum ZoneItemType {
  appliance('가전'),
  furniture('가구'),
  fixture('시설'),
  other('기타');

  const ZoneItemType(this.label);

  final String label;
}

class CleaningProduct {
  const CleaningProduct({
    required this.brand,
    required this.name,
    required this.reason,
    required this.url,
    this.isSponsored = false,
  });

  final String brand;
  final String name;
  final String reason;
  final String url;
  final bool isSponsored;
}

class ZoneItem {
  const ZoneItem({
    required this.id,
    required this.zoneId,
    required this.name,
    required this.type,
    required this.summary,
    required this.frequency,
    required this.supplies,
    required this.cautions,
    required this.steps,
    this.manufacturer,
    this.modelName,
    this.productMethod,
    this.guideStatus,
    this.guideVideoUrl,
    this.guideVideoTitle,
    this.guideVideoChannel,
    this.guideBasis,
    this.recommendedSupplies = const [],
    this.recommendedProducts = const [],
  });

  final String id;
  final String zoneId;
  final String name;
  final ZoneItemType type;
  final String summary;
  final String frequency;
  final List<String> supplies;
  final List<String> cautions;
  final List<String> steps;
  final String? manufacturer;
  final String? modelName;
  final String? productMethod;
  final String? guideStatus;
  final String? guideVideoUrl;
  final String? guideVideoTitle;
  final String? guideVideoChannel;
  final String? guideBasis;
  final List<String> recommendedSupplies;
  final List<CleaningProduct> recommendedProducts;

  bool get hasProductInfo =>
      (manufacturer?.trim().isNotEmpty ?? false) ||
      (modelName?.trim().isNotEmpty ?? false);

  ZoneItem copyWith({
    String? manufacturer,
    String? modelName,
    String? guideStatus,
  }) {
    return ZoneItem(
      id: id,
      zoneId: zoneId,
      name: name,
      type: type,
      summary: summary,
      frequency: frequency,
      supplies: supplies,
      cautions: cautions,
      steps: steps,
      manufacturer: manufacturer ?? this.manufacturer,
      modelName: modelName ?? this.modelName,
      productMethod: productMethod,
      guideStatus: guideStatus ?? this.guideStatus,
      guideVideoUrl: guideVideoUrl,
      guideVideoTitle: guideVideoTitle,
      guideVideoChannel: guideVideoChannel,
      guideBasis: guideBasis,
      recommendedSupplies: recommendedSupplies,
      recommendedProducts: recommendedProducts,
    );
  }
}
