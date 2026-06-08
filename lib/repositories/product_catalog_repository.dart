import 'dart:convert';
import 'dart:io';

import '../data/product_catalog.dart';

abstract interface class ProductCatalogRepository {
  Future<List<ProductCatalogEntry>> search(
    String query, {
    String? category,
    int limit = 20,
  });
}

class LocalProductCatalogRepository implements ProductCatalogRepository {
  const LocalProductCatalogRepository();

  @override
  Future<List<ProductCatalogEntry>> search(
    String query, {
    String? category,
    int limit = 20,
  }) async {
    return searchProductCatalog(query)
        .where(
          (entry) =>
              category == null ||
              category.contains(entry.categoryName) ||
              entry.categoryName.contains(category),
        )
        .take(limit)
        .toList();
  }
}

class RemoteFirstProductCatalogRepository implements ProductCatalogRepository {
  const RemoteFirstProductCatalogRepository({
    this.baseUrl = const String.fromEnvironment(
      'CATALOG_API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000',
    ),
    this.fallback = const LocalProductCatalogRepository(),
  });

  final String baseUrl;
  final ProductCatalogRepository fallback;

  @override
  Future<List<ProductCatalogEntry>> search(
    String query, {
    String? category,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/v1/products').replace(
        queryParameters: {
          'q': query,
          if (category != null && category.isNotEmpty) 'category': category,
          'limit': '$limit',
        },
      );
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 2);
      try {
        final request = await client.getUrl(uri);
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close().timeout(
              const Duration(seconds: 3),
            );
        if (response.statusCode != HttpStatus.ok) {
          throw HttpException(
            'Catalog API returned ${response.statusCode}',
            uri: uri,
          );
        }
        final body = await utf8.decoder.bind(response).join();
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        return (decoded['items'] as List<dynamic>)
            .map(
              (item) => ProductCatalogEntry.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList();
      } finally {
        client.close(force: true);
      }
    } on Object {
      return fallback.search(query, category: category, limit: limit);
    }
  }
}
