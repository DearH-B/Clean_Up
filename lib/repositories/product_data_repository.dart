import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/product_catalog.dart';
import '../data/product_care_templates.dart';
import '../data/product_consumable_defaults.dart';
import '../models/care_record.dart';
import '../models/product_space.dart';
import '../models/product_search_request.dart';
import '../models/product_submission.dart';
import '../models/zone_item.dart';
import 'local_product_database.dart';

class ProductDataRepository {
  const ProductDataRepository();

  // Keep existing keys so users retain data created by earlier app versions.
  static const _spacesKey = 'zones_v1';
  static const _userProductsKey = 'zone_items_v1';
  static const _careRecordsKey = 'cleaning_records_v1';
  static const _searchRequestsKey = 'product_search_requests_v1';
  static const _recentSearchesKey = 'recent_product_searches_v1';
  static const _recentProductIdsKey = 'recent_product_ids_v1';
  static const _submissionsKey = 'product_submissions_v1';
  static const _migrationKey = 'legacy_json_migration_v1';
  static const _recentSearchesMetadataKey = 'recent_searches';
  static const _recentProductIdsMetadataKey = 'recent_product_ids';
  static final LocalProductDatabase _database = LocalProductDatabase();
  static Future<void>? _migrationFuture;

  bool get _usesDatabase => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<List<ProductSpace>?> loadSpaces() async {
    return _loadList(
      _spacesKey,
      ProductSpace.fromJson,
      table: LocalProductDatabase.spacesTable,
    );
  }

  Future<void> saveSpaces(List<ProductSpace> spaces) async {
    await _saveList(
      _spacesKey,
      [for (final space in spaces) space.toJson()],
      table: LocalProductDatabase.spacesTable,
    );
  }

  Future<List<ZoneItem>?> loadUserProducts() async {
    final items = await _loadList(
      _userProductsKey,
      ZoneItem.fromJson,
      table: LocalProductDatabase.productsTable,
    );
    if (items == null) {
      return null;
    }

    var changed = false;
    final enrichedItems = [
      for (final item in items) _upgradeProduct(item, () => changed = true),
    ];
    if (changed) {
      await saveUserProducts(enrichedItems);
    }
    return enrichedItems;
  }

  Future<void> saveUserProducts(List<ZoneItem> products) async {
    await _saveList(
      _userProductsKey,
      [for (final product in products) product.toJson()],
      table: LocalProductDatabase.productsTable,
    );
  }

  Future<List<CareRecord>?> loadCareRecords() async {
    return _loadList(
      _careRecordsKey,
      CareRecord.fromJson,
      table: LocalProductDatabase.recordsTable,
    );
  }

  Future<void> saveCareRecords(List<CareRecord> records) async {
    await _saveList(
      _careRecordsKey,
      [for (final record in records) record.toJson()],
      table: LocalProductDatabase.recordsTable,
    );
  }

  Future<List<ProductSearchRequest>?> loadProductSearchRequests() async {
    return _loadList(
      _searchRequestsKey,
      ProductSearchRequest.fromJson,
      table: LocalProductDatabase.requestsTable,
    );
  }

  Future<void> saveProductSearchRequests(
    List<ProductSearchRequest> requests,
  ) async {
    await _saveList(
      _searchRequestsKey,
      [for (final request in requests) request.toJson()],
      table: LocalProductDatabase.requestsTable,
    );
  }

  Future<List<ProductSubmission>?> loadProductSubmissions() async {
    return _loadList(
      _submissionsKey,
      ProductSubmission.fromJson,
      table: LocalProductDatabase.submissionsTable,
    );
  }

  Future<void> saveProductSubmissions(
    List<ProductSubmission> submissions,
  ) async {
    await _saveList(
      _submissionsKey,
      [for (final submission in submissions) submission.toJson()],
      table: LocalProductDatabase.submissionsTable,
    );
  }

  Future<List<String>> loadRecentProductSearches() async {
    if (_usesDatabase) {
      await _ensureMobileMigration();
      final encoded = await _database.readMetadata(_recentSearchesMetadataKey);
      return encoded == null
          ? const []
          : (jsonDecode(encoded) as List<dynamic>).cast<String>();
    }
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_recentSearchesKey) ?? const [];
  }

  Future<void> saveRecentProductSearches(List<String> searches) async {
    if (_usesDatabase) {
      await _ensureMobileMigration();
      await _database.writeMetadata(
        _recentSearchesMetadataKey,
        jsonEncode(searches),
      );
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_recentSearchesKey, searches);
  }

  Future<List<String>> loadRecentProductIds() async {
    if (_usesDatabase) {
      await _ensureMobileMigration();
      final encoded =
          await _database.readMetadata(_recentProductIdsMetadataKey);
      return encoded == null
          ? const []
          : (jsonDecode(encoded) as List<dynamic>).cast<String>();
    }
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_recentProductIdsKey) ?? const [];
  }

  Future<void> markProductViewed(String productId) async {
    final current = await loadRecentProductIds();
    final updated = [
      productId,
      for (final id in current)
        if (id != productId) id,
    ].take(5).toList();
    await _saveRecentProductIds(updated);
  }

  Future<void> removeRecentProduct(String productId) async {
    final current = await loadRecentProductIds();
    await _saveRecentProductIds(
      [
        for (final id in current)
          if (id != productId) id
      ],
    );
  }

  Future<String> exportBackupJson() async {
    return jsonEncode({
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'spaces': [
        for (final item in await loadSpaces() ?? const <ProductSpace>[])
          item.toJson(),
      ],
      'products': [
        for (final item in await loadUserProducts() ?? const <ZoneItem>[])
          item.toJson(),
      ],
      'careRecords': [
        for (final item in await loadCareRecords() ?? const <CareRecord>[])
          item.toJson(),
      ],
      'searchRequests': [
        for (final item in await loadProductSearchRequests() ??
            const <ProductSearchRequest>[])
          item.toJson(),
      ],
      'submissions': [
        for (final item
            in await loadProductSubmissions() ?? const <ProductSubmission>[])
          item.toJson(),
      ],
      'recentSearches': await loadRecentProductSearches(),
      'recentProductIds': await loadRecentProductIds(),
    });
  }

  Future<DataRestoreSummary> restoreBackupJson(String encoded) async {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException('백업 형식이 올바르지 않아요.');
    }
    final json = Map<String, Object?>.from(decoded);
    if (json['schemaVersion'] != 1) {
      throw const FormatException('지원하지 않는 백업 버전이에요.');
    }

    final spaces = _decodeJsonItems(json['spaces'], ProductSpace.fromJson);
    final products = _decodeJsonItems(json['products'], ZoneItem.fromJson);
    final records = _decodeJsonItems(json['careRecords'], CareRecord.fromJson);
    final requests = _decodeJsonItems(
      json['searchRequests'],
      ProductSearchRequest.fromJson,
    );
    final submissions = _decodeJsonItems(
      json['submissions'],
      ProductSubmission.fromJson,
    );
    final recentSearches = _decodeStrings(json['recentSearches']);
    final recentProductIds = _decodeStrings(json['recentProductIds']);

    if (_usesDatabase) {
      await _ensureMobileMigration();
      await _database.replaceAllData(
        tables: {
          LocalProductDatabase.spacesTable: [
            for (final item in spaces) item.toJson(),
          ],
          LocalProductDatabase.productsTable: [
            for (final item in products) item.toJson(),
          ],
          LocalProductDatabase.recordsTable: [
            for (final item in records) item.toJson(),
          ],
          LocalProductDatabase.requestsTable: [
            for (final item in requests) item.toJson(),
          ],
          LocalProductDatabase.submissionsTable: [
            for (final item in submissions) item.toJson(),
          ],
        },
        metadata: {
          _recentSearchesMetadataKey: jsonEncode(recentSearches),
          _recentProductIdsMetadataKey: jsonEncode(recentProductIds),
          _migrationKey: 'complete',
        },
      );
    } else {
      await saveSpaces(spaces);
      await saveUserProducts(products);
      await saveCareRecords(records);
      await saveProductSearchRequests(requests);
      await saveProductSubmissions(submissions);
      await saveRecentProductSearches(recentSearches);
      await _saveRecentProductIds(recentProductIds);
    }

    return DataRestoreSummary(
      spaceCount: spaces.length,
      productCount: products.length,
      recordCount: records.length,
    );
  }

  Future<void> clearAllUserData() async {
    if (_usesDatabase) {
      await _ensureMobileMigration();
      await _database.clearUserData();
      await _database.writeMetadata(_migrationKey, 'complete');
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    for (final key in [
      _spacesKey,
      _userProductsKey,
      _careRecordsKey,
      _searchRequestsKey,
      _recentSearchesKey,
      _recentProductIdsKey,
      _submissionsKey,
    ]) {
      await preferences.remove(key);
      await preferences.remove(_backupKey(key));
    }
  }

  Future<List<T>?> _loadList<T>(
    String key,
    T Function(Map<String, Object?> json) fromJson, {
    required String table,
  }) async {
    if (_usesDatabase) {
      await _ensureMobileMigration();
      final items = await _database.readItems(table);
      return [for (final item in items) fromJson(item)];
    }
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(key);
    if (saved == null) {
      return null;
    }

    try {
      return _decodeList(saved, fromJson);
    } on Object {
      final backup = preferences.getString(_backupKey(key));
      if (backup == null) {
        return null;
      }
      try {
        final recovered = _decodeList(backup, fromJson);
        await preferences.setString(key, backup);
        return recovered;
      } on Object {
        return null;
      }
    }
  }

  Future<void> _saveList(
    String key,
    List<Map<String, Object?>> items, {
    required String table,
  }) async {
    if (_usesDatabase) {
      await _ensureMobileMigration();
      await _database.writeItems(table, items);
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final current = preferences.getString(key);
    if (current != null) {
      await preferences.setString(_backupKey(key), current);
    }
    await preferences.setString(key, jsonEncode(items));
  }

  List<T> _decodeList<T>(
    String encoded,
    T Function(Map<String, Object?> json) fromJson,
  ) {
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return [
      for (final item in decoded)
        fromJson(Map<String, Object?>.from(item as Map)),
    ];
  }

  List<T> _decodeJsonItems<T>(
    Object? value,
    T Function(Map<String, Object?> json) fromJson,
  ) {
    if (value is! List) {
      throw const FormatException('백업 데이터 항목이 누락됐어요.');
    }
    return [
      for (final item in value)
        if (item is Map)
          fromJson(Map<String, Object?>.from(item))
        else
          throw const FormatException('백업 항목 형식이 올바르지 않아요.'),
    ];
  }

  List<String> _decodeStrings(Object? value) {
    if (value is! List || value.any((item) => item is! String)) {
      throw const FormatException('백업 목록 형식이 올바르지 않아요.');
    }
    return value.cast<String>();
  }

  Future<void> _saveRecentProductIds(List<String> ids) async {
    if (_usesDatabase) {
      await _ensureMobileMigration();
      await _database.writeMetadata(
        _recentProductIdsMetadataKey,
        jsonEncode(ids.take(5).toList()),
      );
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_recentProductIdsKey, ids.take(5).toList());
  }

  String _backupKey(String key) => '${key}_backup';

  Future<void> _ensureMobileMigration() async {
    if (!_usesDatabase) {
      return;
    }
    _migrationFuture ??= _migrateLegacyData();
    await _migrationFuture;
  }

  Future<void> _migrateLegacyData() async {
    if (await _database.readMetadata(_migrationKey) == 'complete') {
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final spaces = _legacyItems(
      preferences,
      _spacesKey,
      ProductSpace.fromJson,
      (item) => item.toJson(),
    );
    final products = _legacyItems(
      preferences,
      _userProductsKey,
      ZoneItem.fromJson,
      (item) => item.toJson(),
    );
    final records = _legacyItems(
      preferences,
      _careRecordsKey,
      CareRecord.fromJson,
      (item) => item.toJson(),
    );
    final requests = _legacyItems(
      preferences,
      _searchRequestsKey,
      ProductSearchRequest.fromJson,
      (item) => item.toJson(),
    );
    final submissions = _legacyItems(
      preferences,
      _submissionsKey,
      ProductSubmission.fromJson,
      (item) => item.toJson(),
    );
    await _database.replaceAllData(
      tables: {
        LocalProductDatabase.spacesTable: spaces,
        LocalProductDatabase.productsTable: products,
        LocalProductDatabase.recordsTable: records,
        LocalProductDatabase.requestsTable: requests,
        LocalProductDatabase.submissionsTable: submissions,
      },
      metadata: {
        _recentSearchesMetadataKey: jsonEncode(
          preferences.getStringList(_recentSearchesKey) ?? const <String>[],
        ),
        _recentProductIdsMetadataKey: jsonEncode(
          preferences.getStringList(_recentProductIdsKey) ?? const <String>[],
        ),
        _migrationKey: 'complete',
      },
    );
  }

  List<Map<String, Object?>> _legacyItems<T>(
    SharedPreferences preferences,
    String key,
    T Function(Map<String, Object?> json) fromJson,
    Map<String, Object?> Function(T item) toJson,
  ) {
    final encoded = preferences.getString(key);
    if (encoded == null) {
      return const [];
    }
    try {
      return [
        for (final item in _decodeList(encoded, fromJson)) toJson(item),
      ];
    } on Object {
      final backup = preferences.getString(_backupKey(key));
      if (backup == null) {
        rethrow;
      }
      return [
        for (final item in _decodeList(backup, fromJson)) toJson(item),
      ];
    }
  }

  ZoneItem _enrichCatalogItem(ZoneItem item, void Function() markChanged) {
    final entry = findCatalogEntry(
      categoryName: item.name,
      brand: item.manufacturer!,
      modelName: item.modelName!,
    );
    if (entry == null) {
      return item;
    }
    markChanged();
    if (item.sourceTitle != null) {
      return item.copyWith(catalogProductId: entry.id);
    }
    return entry.mergeInto(item);
  }

  ZoneItem _upgradeProduct(ZoneItem item, void Function() markChanged) {
    if (item.consumables.isEmpty) {
      final defaults = defaultConsumablesFor(item.name);
      if (defaults.isNotEmpty) {
        markChanged();
        item = item.copyWith(consumables: defaults);
      }
    }

    if (item.modelName?.isNotEmpty == true &&
        item.modelImageUrl?.isNotEmpty != true) {
      final categoryName =
          findCatalogEntryById(item.catalogProductId ?? '')?.categoryName ??
              item.name;
      final models = catalogModelDetailsFor(
        categoryName,
        item.manufacturer ?? '',
      );
      for (final model in models) {
        if (model.modelName == item.modelName &&
            (model.imageUrl?.isNotEmpty == true ||
                model.productUrl?.isNotEmpty == true)) {
          markChanged();
          item = item.copyWith(
            modelDisplayName: model.displayName,
            modelReleaseYear: model.releaseYear,
            modelImageUrl: model.imageUrl,
            officialProductUrl: model.productUrl,
            modelFeatures: model.features,
            matchLevelLabel: '공식 확인 모델',
          );
          break;
        }
      }
    }

    if (item.manufacturer?.isNotEmpty == true &&
        item.modelName?.isNotEmpty == true) {
      final categoryName =
          findCatalogEntryById(item.catalogProductId ?? '')?.categoryName ??
              item.name;
      final exactEntry = findCatalogEntry(
        categoryName: categoryName,
        brand: item.manufacturer!,
        modelName: item.modelName!,
      );
      if (exactEntry != null && exactEntry.id != item.catalogProductId) {
        markChanged();
        return exactEntry.mergeInto(item);
      }
    }

    if (item.catalogProductId == null &&
        item.manufacturer?.isNotEmpty == true &&
        item.modelName?.isNotEmpty == true) {
      final enriched = _enrichCatalogItem(item, markChanged);
      if (!identical(enriched, item)) {
        return enriched;
      }
    }

    final catalogProductId = item.catalogProductId;
    if (catalogProductId != null) {
      final entry = findCatalogEntryById(catalogProductId);
      final currentCheckedAt = item.sourceCheckedAt;
      if (entry != null &&
          (currentCheckedAt == null ||
              entry.sourceCheckedAt.isAfter(currentCheckedAt) ||
              _catalogGuideChanged(item, entry))) {
        markChanged();
        return entry.mergeInto(item);
      }
    }

    if (!_usesLegacyGenericGuide(item)) {
      return item;
    }
    final template = findProductCareTemplate(item.name);
    if (template == null) {
      return item;
    }
    markChanged();
    return template
        .createProduct(
          id: item.id,
          zoneId: item.zoneId,
          nickname: item.nickname,
          purchaseDate: item.purchaseDate,
          installedDate: item.installedDate,
          note: item.note,
          manufacturer: item.manufacturer,
          modelName: item.modelName,
          scannedCode: item.scannedCode,
          scannedCodeFormat: item.scannedCodeFormat,
          scannedSourceUrl: item.scannedSourceUrl,
        )
        .copyWith(
          lastCleanedAt: item.lastCleanedAt,
          nextDueAt: item.nextDueAt,
          consumables: item.consumables,
        );
  }

  bool _usesLegacyGenericGuide(ZoneItem item) {
    return item.summary.contains('재질과 사용설명서를 확인한 뒤 관리하세요') ||
        item.guideStatus?.contains('세부 관리법을 준비하고 있어요') == true ||
        (item.steps.length == 4 &&
            item.steps.any((step) => step.contains('주변의 물건과 먼지를 먼저 정리')));
  }

  bool _catalogGuideChanged(ZoneItem item, ProductCatalogEntry entry) {
    return item.summary != entry.summary ||
        item.guideStatus != entry.guideStatus ||
        item.guideBasis != entry.guideBasis ||
        item.officialManualUrl != entry.officialManualUrl ||
        item.supportUrl != entry.supportUrl ||
        !listEquals(item.supplies, entry.supplies) ||
        !listEquals(item.steps, entry.steps) ||
        !listEquals(item.cautions, entry.cautions) ||
        !listEquals(item.productSpecs, entry.productSpecs) ||
        !setEquals(
          item.consumables
              .map((item) => item.id)
              .where(catalogManagedConsumableIds().contains)
              .toSet(),
          entry.consumableDetails.map((item) => item.id).toSet(),
        );
  }
}

class DataRestoreSummary {
  const DataRestoreSummary({
    required this.spaceCount,
    required this.productCount,
    required this.recordCount,
  });

  final int spaceCount;
  final int productCount;
  final int recordCount;
}
