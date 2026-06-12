import 'visual_product_candidate.dart';

class ProductFinderResult {
  const ProductFinderResult.exact(this.modelName) : visualCandidate = null;

  const ProductFinderResult.similar(this.visualCandidate) : modelName = '';

  final String modelName;
  final VisualProductCandidate? visualCandidate;

  bool get isExactModel => modelName.isNotEmpty;
}
