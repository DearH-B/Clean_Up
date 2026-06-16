import 'dart:convert';
import 'dart:io';

import '../data/product_diagnostics.dart';
import '../models/product_diagnostic.dart';

typedef DiagnosticJsonLoader = Future<Map<String, dynamic>> Function(Uri uri);

abstract interface class ProductDiagnosticRepository {
  Future<List<ProductDiagnostic>> diagnosticsFor(String productName);
}

class LocalProductDiagnosticRepository implements ProductDiagnosticRepository {
  const LocalProductDiagnosticRepository();

  @override
  Future<List<ProductDiagnostic>> diagnosticsFor(String productName) async {
    return diagnosticsForProduct(productName);
  }
}

class RemoteFirstProductDiagnosticRepository
    implements ProductDiagnosticRepository {
  const RemoteFirstProductDiagnosticRepository({
    this.baseUrl = const String.fromEnvironment(
      'CATALOG_API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000',
    ),
    this.fallback = const LocalProductDiagnosticRepository(),
    this.loader,
  });

  final String baseUrl;
  final ProductDiagnosticRepository fallback;
  final DiagnosticJsonLoader? loader;

  @override
  Future<List<ProductDiagnostic>> diagnosticsFor(String productName) async {
    try {
      final uri = Uri.parse('$baseUrl/v1/diagnostics').replace(
        queryParameters: {'productType': productName},
      );
      final decoded =
          loader == null ? await _loadJson(uri) : await loader!(uri);
      final items = (decoded['items'] as List<dynamic>)
          .map(
            (item) => ProductDiagnostic.fromJson(
              Map<String, Object?>.from(item as Map),
            ),
          )
          .toList();
      if (items.isNotEmpty) {
        return items;
      }
    } on Object {
      // The bundled guide remains available when the API cannot be reached.
    }
    return fallback.diagnosticsFor(productName);
  }

  Future<Map<String, dynamic>> _loadJson(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
            const Duration(seconds: 3),
          );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Diagnostic API returned ${response.statusCode}',
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
