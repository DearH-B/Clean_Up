import 'package:flutter/material.dart';

import '../models/visual_product_candidate.dart';

List<VisualProductCandidate> visualCandidatesFor({
  required String categoryName,
  required String brand,
}) {
  final category = _normalize(categoryName);
  if (!category.contains('냉장고')) {
    return const [];
  }

  final normalizedBrand = _normalize(brand);
  final knownBrand = normalizedBrand.isEmpty ? '브랜드 미상' : brand.trim();
  return [
    VisualProductCandidate(
      id: '${normalizedBrand.isEmpty ? 'generic' : normalizedBrand}-four-door',
      categoryName: '냉장고',
      brand: knownBrand,
      displayName: '$knownBrand 4도어 냉장고',
      formFactor: '4도어 · 상냉장 하냉동',
      releasePeriod: '2018년 이후 주로 판매',
      features: const ['위쪽 냉장실', '아래쪽 냉동실', '가운데 세로 분할'],
      icon: Icons.view_module_outlined,
    ),
    VisualProductCandidate(
      id: '${normalizedBrand.isEmpty ? 'generic' : normalizedBrand}-side-by-side',
      categoryName: '냉장고',
      brand: knownBrand,
      displayName: '$knownBrand 양문형 냉장고',
      formFactor: '양문형 · 좌우 2도어',
      releasePeriod: '2000년대 이후 널리 판매',
      features: const ['왼쪽 냉동실', '오른쪽 냉장실', '세로로 긴 문 2개'],
      icon: Icons.view_week_outlined,
    ),
    VisualProductCandidate(
      id: '${normalizedBrand.isEmpty ? 'generic' : normalizedBrand}-top-freezer',
      categoryName: '냉장고',
      brand: knownBrand,
      displayName: '$knownBrand 일반형 냉장고',
      formFactor: '일반형 · 상냉동 하냉장',
      releasePeriod: '연식 구분 없이 지속 판매',
      features: const ['위쪽 작은 냉동실', '아래쪽 큰 냉장실', '문 2개'],
      icon: Icons.kitchen_outlined,
    ),
    VisualProductCandidate(
      id: '${normalizedBrand.isEmpty ? 'generic' : normalizedBrand}-kimchi',
      categoryName: '김치냉장고',
      brand: knownBrand,
      displayName: '$knownBrand 스탠드형 김치냉장고',
      formFactor: '스탠드형 · 3도어 또는 4도어',
      releasePeriod: '2010년대 이후 주로 판매',
      features: const ['독립 보관칸', '서랍 또는 다중 도어', '김치 보관 모드'],
      icon: Icons.grid_view_outlined,
    ),
  ];
}

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');
}
