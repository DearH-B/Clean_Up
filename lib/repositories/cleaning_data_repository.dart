import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cleaning_record.dart';
import '../models/cleaning_zone.dart';
import '../models/community_post.dart';
import '../models/zone_item.dart';

class CleaningDataRepository {
  const CleaningDataRepository();

  static const _zonesKey = 'zones_v1';
  static const _zoneItemsKey = 'zone_items_v1';
  static const _recordsKey = 'cleaning_records_v1';
  static const _communityPostsKey = 'community_posts_v1';

  Future<List<CleaningZone>?> loadZones() async {
    return _loadList(_zonesKey, CleaningZone.fromJson);
  }

  Future<void> saveZones(List<CleaningZone> zones) async {
    await _saveList(_zonesKey, [for (final zone in zones) zone.toJson()]);
  }

  Future<List<ZoneItem>?> loadZoneItems() async {
    return _loadList(_zoneItemsKey, ZoneItem.fromJson);
  }

  Future<void> saveZoneItems(List<ZoneItem> items) async {
    await _saveList(_zoneItemsKey, [for (final item in items) item.toJson()]);
  }

  Future<List<CleaningRecord>?> loadRecords() async {
    return _loadList(_recordsKey, CleaningRecord.fromJson);
  }

  Future<void> saveRecords(List<CleaningRecord> records) async {
    await _saveList(_recordsKey, [
      for (final record in records) record.toJson(),
    ]);
  }

  Future<List<CommunityPost>?> loadCommunityPosts() async {
    return _loadList(_communityPostsKey, CommunityPost.fromJson);
  }

  Future<void> saveCommunityPosts(List<CommunityPost> posts) async {
    await _saveList(
        _communityPostsKey, [for (final post in posts) post.toJson()]);
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

  Future<void> _saveList(String key, List<Map<String, Object?>> items) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(items));
  }
}
