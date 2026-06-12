import 'dart:convert';
import 'dart:io';

import '../data/product_catalog.dart';
import '../models/catalog_model_option.dart';

abstract interface class ProductCatalogRepository {
  Future<List<ProductCatalogEntry>> search(
    String query, {
    String? category,
    int limit = 20,
  });

  Future<List<String>> brandsFor(String category);

  Future<List<CatalogModelOption>> modelsFor({
    required String category,
    required String brand,
    String query = '',
    int limit = 50,
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

  @override
  Future<List<String>> brandsFor(String category) async {
    return catalogBrandOptionsFor(category);
  }

  @override
  Future<List<CatalogModelOption>> modelsFor({
    required String category,
    required String brand,
    String query = '',
    int limit = 50,
  }) async {
    final normalizedQuery = _normalize(query);
    return catalogModelOptionsFor(category, brand)
        .where(
          (model) =>
              normalizedQuery.isEmpty ||
              _normalize(model).contains(normalizedQuery),
        )
        .take(limit)
        .map(
          (model) => CatalogModelOption(
            modelName: model,
            displayName: model,
          ),
        )
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
        final entries = (decoded['items'] as List<dynamic>)
            .map(
              (item) => ProductCatalogEntry.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList();
        return sortProductCatalogResults(entries, query).take(limit).toList();
      } finally {
        client.close(force: true);
      }
    } on Object {
      return fallback.search(query, category: category, limit: limit);
    }
  }

  @override
  Future<List<String>> brandsFor(String category) async {
    try {
      final decoded = await _getJson(
        '/v1/brands',
        queryParameters: {'category': category},
      );
      return (decoded['items'] as List<dynamic>).cast<String>();
    } on Object {
      return fallback.brandsFor(category);
    }
  }

  @override
  Future<List<CatalogModelOption>> modelsFor({
    required String category,
    required String brand,
    String query = '',
    int limit = 50,
  }) async {
    try {
      final decoded = await _getJson(
        '/v1/models',
        queryParameters: {
          'category': category,
          'brand': brand,
          if (query.isNotEmpty) 'q': query,
          'limit': '$limit',
        },
      );
      final models = (decoded['items'] as List<dynamic>)
          .map(
            (item) => CatalogModelOption.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList();
      if (models.isNotEmpty) {
        return models;
      }
      return fallback.modelsFor(
        category: category,
        brand: brand,
        query: query,
        limit: limit,
      );
    } on Object {
      return fallback.modelsFor(
        category: category,
        brand: brand,
        query: query,
        limit: limit,
      );
    }
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    required Map<String, String> queryParameters,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
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
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }
}

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');
}
