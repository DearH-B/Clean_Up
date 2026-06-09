import 'package:clean_up/utils/product_code_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseProductCode', () {
    test('keeps a barcode value as the search query', () {
      final result = parseProductCode('8801234567890');

      expect(result.rawValue, '8801234567890');
      expect(result.searchQuery, '8801234567890');
      expect(result.sourceUrl, isNull);
    });

    test('extracts a model name from a QR URL query parameter', () {
      final result = parseProductCode(
        'https://example.com/manual?model=DCS-HM4AG-W',
      );

      expect(result.searchQuery, 'DCS-HM4AG-W');
      expect(result.sourceUrl, isNotNull);
    });

    test('uses the final URL path when no model parameter exists', () {
      final result = parseProductCode(
        'https://example.com/products/DCS-HM4AG-W',
      );

      expect(result.searchQuery, 'DCS-HM4AG-W');
    });
  });
}
