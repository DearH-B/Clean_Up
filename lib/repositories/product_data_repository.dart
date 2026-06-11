import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/product_catalog.dart';
import '../data/product_care_templates.dart';
import '../data/product_consumable_defaults.dart';
import '../models/care_record.dart';
import '../models/product_space.dart';
import '../models/product_search_request.dart';
import '../models/zone_item.dart';

class ProductDataRepository {
  const ProductDataRepository();

  // Keep existing keys so users retain data created by earlier app versions.
  static const _spacesKey = 'zones_v1';
  static const _userProductsKey = 'zone_items_v1';
  static const _careRecordsKey = 'cleaning_records_v1';
  static const _searchRequestsKey = 'product_search_requests_v1';
  static const _recentSearchesKey = 'recent_product_searches_v1';

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

    final decoded = jsonDecode(saved) as List<dynamic>;
    return [
      for (final item in decoded)
        fromJson(Map<String, Object?>.from(item as Map)),
    ];
  }

  Future<void> _saveList(
    String key,
    List<Map<String, Object?>> items,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(items));
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

    if (item.catalogProductId == null &&
        item.manufacturer?.isNotEmpty == true &&
        item.modelName?.isNotEmpty == true) {
      final enriched = _enrichCatalogItem(item, markChanged);
      if (!identical(enriched, item)) {
        return enriched;
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
}
