import 'dart:convert';
import 'dart:io';

import '../models/product_submission.dart';

abstract interface class ProductSubmissionRepository {
  Future<ProductSubmission> submit(ProductSubmission submission);

  Future<ProductSubmission> refresh(ProductSubmission submission);
}

class RemoteProductSubmissionRepository implements ProductSubmissionRepository {
  const RemoteProductSubmissionRepository({
    this.baseUrl = const String.fromEnvironment(
      'CATALOG_API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000',
    ),
  });

  final String baseUrl;

  @override
  Future<ProductSubmission> submit(ProductSubmission submission) async {
    final response = await _request(
      method: 'POST',
      uri: Uri.parse('$baseUrl/v1/submissions'),
      body: submission.toApiJson(),
    );
    return _mergeResponse(submission, response);
  }

  @override
  Future<ProductSubmission> refresh(ProductSubmission submission) async {
    final token = submission.trackingToken;
    if (token == null || token.isEmpty) {
      return submission;
    }
    final response = await _request(
      method: 'GET',
      uri: Uri.parse('$baseUrl/v1/submissions/$token'),
    );
    return _mergeResponse(submission, response);
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required Uri uri,
    Map<String, Object?>? body,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    try {
      final request = method == 'POST'
          ? await client.postUrl(uri)
          : await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(
            const Duration(seconds: 4),
          );
      final responseBody = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Submission API returned ${response.statusCode}',
          uri: uri,
        );
      }
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }

  ProductSubmission _mergeResponse(
    ProductSubmission submission,
    Map<String, dynamic> response,
  ) {
    return submission.copyWith(
      trackingToken: response['trackingToken'] as String?,
      updatedAt: DateTime.parse(response['updatedAt'] as String).toLocal(),
      status: ProductSubmissionStatus.values.byName(
        response['status'] as String,
      ),
      statusMessage: response['statusMessage'] as String?,
    );
  }
}
