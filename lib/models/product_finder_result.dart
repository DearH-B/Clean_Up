import 'catalog_model_option.dart';
import 'visual_product_candidate.dart';

class ProductFinderResult {
  const ProductFinderResult.exact(this.exactModel)
      : manualModelName = null,
        visualCandidate = null;

  const ProductFinderResult.manual(this.manualModelName)
      : exactModel = null,
        visualCandidate = null;

  const ProductFinderResult.similar(this.visualCandidate)
      : exactModel = null,
        manualModelName = null;

  final CatalogModelOption? exactModel;
  final String? manualModelName;
  final VisualProductCandidate? visualCandidate;

  String get modelName => exactModel?.modelName ?? manualModelName ?? '';

  bool get isExactModel => exactModel != null;
  bool get hasModelName => modelName.isNotEmpty;
}
