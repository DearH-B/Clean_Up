import 'dart:convert';

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

class ProductDataRepository {
  const ProductDataRepository();

  // Keep existing keys so users retain data created by earlier app versions.
  static const _spacesKey = 'zones_v1';
  static const _userProductsKey = 'zone_items_v1';
  static const _careRecordsKey = 'cleaning_records_v1';
  static const _searchRequestsKey = 'product_search_requests_v1';
  static const _recentSearchesKey = 'recent_product_searches_v1';
  static const _submissionsKey = 'product_submissions_v1';

  Future<List<ProductSpace>?> loadSpaces() async {
    return _loadList(_spacesKey, ProductSpace.fromJson);
  }

  Future<void> saveSpaces(List<ProductSpace> spaces) async {
    await _saveList(_spacesKey, [for (final space in spaces) space.toJson()]);
  }

  Future<List<ZoneItem>?> loadUserProducts() async {
    final items = await _loadList(_userProductsKey, ZoneItem.fromJson);
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
    );
  }

  Future<List<CareRecord>?> loadCareRecords() async {
    return _loadList(_careRecordsKey, CareRecord.fromJson);
  }

  Future<void> saveCareRecords(List<CareRecord> records) async {
    await _saveList(
      _careRecordsKey,
      [for (final record in records) record.toJson()],
    );
  }

  Future<List<ProductSearchRequest>?> loadProductSearchRequests() async {
    return _loadList(_searchRequestsKey, ProductSearchRequest.fromJson);
  }

  Future<void> saveProductSearchRequests(
    List<ProductSearchRequest> requests,
  ) async {
    await _saveList(
      _searchRequestsKey,
      [for (final request in requests) request.toJson()],
    );
  }

  Future<List<ProductSubmission>?> loadProductSubmissions() async {
    return _loadList(_submissionsKey, ProductSubmission.fromJson);
  }

  Future<void> saveProductSubmissions(
    List<ProductSubmission> submissions,
  ) async {
    await _saveList(
      _submissionsKey,
      [for (final submission in submissions) submission.toJson()],
    );
  }

  Future<List<String>> loadRecentProductSearches() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_recentSearchesKey) ?? const [];
  }

  Future<void> saveRecentProductSearches(List<String> searches) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_recentSearchesKey, searches);
  }

  Future<List<T>?> _loadList<T>(
    String key,
    T Function(Map<String, Object?> json) fromJson,
  ) async {
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
    List<Map<String, Object?>> items,
  ) async {
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

  String _backupKey(String key) => '${key}_backup';

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
        !listEquals(item.productSpecs, entry.productSpecs);
  }
}
