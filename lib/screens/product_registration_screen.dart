import 'dart:async';

import 'package:flutter/material.dart';

import '../data/product_catalog.dart';
import '../data/product_care_templates.dart';
import '../models/product_search_request.dart';
import '../models/product_submission.dart';
import '../models/product_space.dart';
import '../models/product_finder_result.dart';
import '../models/visual_product_candidate.dart';
import '../models/zone_item.dart';
import '../repositories/product_catalog_repository.dart';
import '../repositories/product_data_repository.dart';
import 'product_code_scanner_screen.dart';
import 'model_selection_screen.dart';

class ProductRegistrationResult {
  const ProductRegistrationResult._({
    this.product,
    this.existingProduct,
    this.openDetails = false,
  });

  const ProductRegistrationResult.created(
    ZoneItem product, {
    required bool openDetails,
  }) : this._(product: product, openDetails: openDetails);

  const ProductRegistrationResult.existing(ZoneItem product)
      : this._(existingProduct: product, openDetails: true);

  final ZoneItem? product;
  final ZoneItem? existingProduct;
  final bool openDetails;
}

class ProductRegistrationScreen extends StatefulWidget {
  const ProductRegistrationScreen({
    required this.space,
    required this.spaces,
    required this.existingProducts,
    required this.dataRepository,
    required this.catalogRepository,
    super.key,
  });

  final ProductSpace space;
  final List<ProductSpace> spaces;
  final List<ZoneItem> existingProducts;
  final ProductDataRepository dataRepository;
  final ProductCatalogRepository catalogRepository;

  @override
  State<ProductRegistrationScreen> createState() =>
      _ProductRegistrationScreenState();
}

class _ProductRegistrationScreenState extends State<ProductRegistrationScreen> {
  final _searchController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _noteController = TextEditingController();
  Timer? _searchDebounce;

  int _step = 0;
  bool _manualMode = false;
  bool _startedFromSearchFailure = false;
  bool _isSearching = false;
  bool _isLoadingBrands = false;
  String _searchQuery = '';
  List<String> _recentSearches = [];
  List<String> _brandOptions = [];
  List<ProductCatalogEntry> _searchResults = [];
  ProductCatalogEntry? _selectedEntry;
  ZoneItemType _selectedType = ZoneItemType.appliance;
  DateTime? _purchaseDate;
  DateTime? _installedDate;
  ZoneItem? _draftProduct;
  String? _scannedCode;
  String? _scannedCodeFormat;
  String? _scannedSourceUrl;
  VisualProductCandidate? _visualCandidate;
  late String _selectedSpaceId;

  @override
  void initState() {
    super.initState();
    _selectedSpaceId = widget.space.id;
    unawaited(_loadRecentSearches());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _nicknameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) {
          setState(() => _step--);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('제품 등록'),
          leading: IconButton(
            tooltip: _step == 0 ? '닫기' : '이전',
            onPressed: _goBack,
            icon: Icon(_step == 0 ? Icons.close : Icons.arrow_back),
          ),
        ),
        body: Column(
          children: [
            _StepHeader(currentStep: _step),
            Expanded(
              child: IndexedStack(
                index: _step,
                children: [
                  _buildFindStep(),
                  _buildConfirmStep(),
                  _buildMyProductStep(),
                  _buildCompleteStep(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _step == 0
            ? null
            : SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    10 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: _buildBottomAction(),
                ),
              ),
      ),
    );
  }

  Widget _buildFindStep() {
    final recommendedProducts = _recommendedProductsFor(widget.space.name);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text('어떤 제품인가요?', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text('제품 라벨의 모델명이나 브랜드를 검색하면 가장 정확해요.'),
        const SizedBox(height: 18),
        FilledButton.tonalIcon(
          onPressed: _openCodeScanner,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('QR·바코드로 제품 찾기'),
        ),
        if (_scannedCode != null) ...[
          const SizedBox(height: 10),
          _ScannedCodeSummary(
            code: _scannedCode!,
            format: _scannedCodeFormat,
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          autofocus: false,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: '제품 검색',
            hintText: '예: DCS-HM4AG-W, 에코업 음식물처리기',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: '검색어 지우기',
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close),
                  ),
          ),
          onChanged: _searchCatalog,
          onSubmitted: _searchCatalog,
        ),
        const SizedBox(height: 14),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_searchQuery.isNotEmpty && _searchResults.isEmpty)
          _NoSearchResult(
            query: _searchQuery,
            onManual: () => _startManualRegistration(
              fromSearchFailure: true,
            ),
            onRequest: _requestProductInformation,
          )
        else if (_searchResults.isNotEmpty)
          for (final entry in _searchResults)
            _CatalogResultCard(
              entry: entry,
              onTap: () => _selectEntry(entry),
            )
        else ...[
          if (_recentSearches.isNotEmpty) ...[
            const _SectionLabel(label: '최근 검색'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final query in _recentSearches)
                  ActionChip(
                    label: Text(query),
                    onPressed: () {
                      _searchController.text = query;
                      _searchCatalog(query);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 22),
          ],
          _SectionLabel(label: '${widget.space.name}에서 자주 등록하는 제품'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in recommendedProducts)
                ActionChip(
                  avatar: Icon(preset.icon, size: 18),
                  label: Text(preset.name),
                  onPressed: () => _startManualRegistration(preset: preset),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _startManualRegistration,
          icon: const Icon(Icons.help_outline),
          label: const Text('모델명을 몰라요'),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: [
        Text(
          _manualMode ? '알고 있는 정보만 적어주세요' : '이 제품이 맞나요?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          _manualMode
              ? '모델명을 몰라도 제품 종류만으로 등록할 수 있어요.'
              : '제품명과 모델명, 정보 출처를 확인해 주세요.',
        ),
        const SizedBox(height: 18),
        if (_manualMode) _buildManualFields() else _buildSelectedProduct(),
      ],
    );
  }

  Widget _buildManualFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _categoryController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: '제품 종류',
            hintText: '예: 냉장고, 음식물처리기',
          ),
          onChanged: (_) {
            setState(() {
              _visualCandidate = null;
              _brandOptions = [];
            });
            _loadBrandOptions();
          },
        ),
        const SizedBox(height: 14),
        DropdownMenu<ZoneItemType>(
          width: double.infinity,
          initialSelection: _selectedType,
          label: const Text('분류'),
          dropdownMenuEntries: [
            for (final type in ZoneItemType.values)
              DropdownMenuEntry(value: type, label: type.label),
          ],
          onSelected: (type) {
            if (type != null) {
              setState(() => _selectedType = type);
            }
          },
        ),
        const SizedBox(height: 14),
        if (_isLoadingBrands)
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: LinearProgressIndicator(),
          )
        else if (_brandOptions.isNotEmpty) ...[
          Text('대표 브랜드', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final brand in _brandOptions)
                ChoiceChip(
                  label: Text(brand),
                  selected: _brandController.text.trim() == brand,
                  onSelected: (_) {
                    setState(() {
                      _brandController.text = brand;
                      _modelController.clear();
                      _visualCandidate = null;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _brandController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: '브랜드 또는 제조사 (선택)',
            hintText: '모르면 비워두세요',
          ),
          onChanged: (_) => setState(() {
            _modelController.clear();
            _visualCandidate = null;
          }),
        ),
        const SizedBox(height: 14),
        FilledButton.tonalIcon(
          onPressed:
              _brandController.text.trim().isEmpty ? null : _openProductFinder,
          icon: const Icon(Icons.image_search_outlined),
          label: Text(
            _modelController.text.trim().isNotEmpty
                ? _modelController.text.trim()
                : _visualCandidate != null
                    ? '선택한 제품 바꾸기'
                    : '내 제품 찾기',
          ),
        ),
        if (_brandController.text.trim().isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '브랜드를 먼저 선택하면 모델 후보를 볼 수 있어요.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else if (_modelController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text('선택한 모델: ${_modelController.text.trim()}')),
              IconButton(
                tooltip: '모델 선택 해제',
                onPressed: () => setState(_modelController.clear),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ] else if (_visualCandidate != null) ...[
          const SizedBox(height: 10),
          _VisualCandidateSummary(candidate: _visualCandidate!),
        ],
        const SizedBox(height: 12),
        Text(
          '모델 정보가 없으면 제품군의 일반 관리법을 먼저 보여드려요.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSelectedProduct() {
    final entry = _selectedEntry;
    if (entry == null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(_iconFor(entry.type))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        [entry.brand, entry.seriesName, entry.modelName]
                            .where((value) => value.isNotEmpty)
                            .join(' · '),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified_outlined),
              ],
            ),
            const SizedBox(height: 16),
            _InfoLine(label: '제품 종류', value: entry.categoryName),
            _InfoLine(label: '일치 수준', value: entry.matchLevelLabel),
            _InfoLine(
              label: '검수 상태',
              value: _reviewStatusLabel(entry.reviewStatus),
            ),
            _InfoLine(label: '정보 출처', value: entry.sourceTitle),
            _InfoLine(
              label: '확인일',
              value: _formatDate(entry.sourceCheckedAt),
            ),
            if (entry.productSpecs.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                '주요 정보',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              for (final spec in entry.productSpecs.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text('• $spec'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMyProductStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
      children: [
        Text('내 제품 정보', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text('나중에 같은 모델을 구분할 때 도움이 되는 정보예요.'),
        const SizedBox(height: 18),
        _ReadOnlyField(
          label: '공간',
          value: _selectedSpace.name,
          icon: Icons.home_work_outlined,
        ),
        if (widget.spaces.length > 1) ...[
          const SizedBox(height: 10),
          DropdownMenu<String>(
            width: double.infinity,
            initialSelection: _selectedSpaceId,
            label: const Text('공간 변경'),
            dropdownMenuEntries: [
              for (final space in widget.spaces)
                DropdownMenuEntry(value: space.id, label: space.name),
            ],
            onSelected: (spaceId) {
              if (spaceId != null) {
                setState(() => _selectedSpaceId = spaceId);
              }
            },
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _nicknameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: '별칭 (선택)',
            hintText: '예: 주방 큰 냉장고',
            prefixIcon: Icon(Icons.label_outline),
          ),
        ),
        const SizedBox(height: 14),
        _DateField(
          label: '구매일 (선택)',
          value: _purchaseDate,
          onTap: () => _pickDate(isPurchaseDate: true),
        ),
        const SizedBox(height: 14),
        _DateField(
          label: '설치일 (선택)',
          value: _installedDate,
          onTap: () => _pickDate(isPurchaseDate: false),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _noteController,
          minLines: 3,
          maxLines: 5,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: '메모 (선택)',
            hintText: '설치 위치, 특이사항 등을 적어두세요',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    final product = _draftProduct;
    if (product == null) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
      children: [
        Center(
          child: Icon(
            Icons.check_circle,
            size: 66,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${product.displayName} 등록 준비 완료',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '${_selectedSpace.name}에서 필요할 때 바로 관리 정보를 확인할 수 있어요.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoLine(label: '제품', value: product.name),
                if (product.seriesName?.isNotEmpty == true)
                  _InfoLine(label: '시리즈', value: product.seriesName!),
                _InfoLine(
                  label: '모델',
                  value: product.modelName?.isNotEmpty == true
                      ? product.modelName!
                      : '선택하지 않음',
                ),
                _InfoLine(
                  label: '관리 정보',
                  value: product.guideSourceType.label,
                ),
                _InfoLine(label: '공간', value: _selectedSpace.name),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    if (_step == 3) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _finish(openDetails: false),
              child: const Text('나중에 보기'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: () => _finish(openDetails: true),
              child: const Text('관리법 보기'),
            ),
          ),
        ],
      );
    }
    return FilledButton(
      onPressed: _continue,
      child: Text(_step == 1 ? '이 정보로 계속' : '등록 내용 확인'),
    );
  }

  Future<void> _continue() async {
    if (_step == 1) {
      if (_manualMode && _categoryController.text.trim().isEmpty) {
        _showMessage('제품 종류를 입력해 주세요.');
        return;
      }
      setState(() => _step = 2);
      return;
    }

    if (_step == 2) {
      final product = _buildProduct();
      final duplicate = _findDuplicate(product);
      if (duplicate != null) {
        final decision = await _showDuplicateDialog(duplicate);
        if (!mounted || decision == null) {
          return;
        }
        if (decision == _DuplicateDecision.openExisting) {
          Navigator.of(context).pop(
            ProductRegistrationResult.existing(duplicate),
          );
          return;
        }
      }
      setState(() {
        _draftProduct = product;
        _step = 3;
      });
    }
  }

  ZoneItem _buildProduct() {
    final id = 'product-${DateTime.now().microsecondsSinceEpoch}';
    final nickname = _nicknameController.text.trim();
    final note = _noteController.text.trim();
    final entry = _selectedEntry;
    if (!_manualMode && entry != null) {
      return entry.toZoneItem(id: id, zoneId: _selectedSpaceId).copyWith(
            scannedCode: _scannedCode,
            scannedCodeFormat: _scannedCodeFormat,
            scannedSourceUrl: _scannedSourceUrl,
            nickname: nickname.isEmpty ? null : nickname,
            purchaseDate: _purchaseDate,
            installedDate: _installedDate,
            note: note.isEmpty ? null : note,
          );
    }

    final category = _categoryController.text.trim();
    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();
    final template = findProductCareTemplate(category);
    if (template != null) {
      return template.createProduct(
        id: id,
        zoneId: _selectedSpaceId,
        nickname: nickname.isEmpty ? null : nickname,
        purchaseDate: _purchaseDate,
        installedDate: _installedDate,
        note: note.isEmpty ? null : note,
        manufacturer: brand.isEmpty ? null : brand,
        modelName: model.isEmpty ? null : model,
        scannedCode: _scannedCode,
        scannedCodeFormat: _scannedCodeFormat,
        scannedSourceUrl: _scannedSourceUrl,
        visualCandidateId: _visualCandidate?.id,
        releasePeriod: _visualCandidate?.releasePeriod,
        productMethod: _visualCandidate?.formFactor,
        isVisualMatch: _visualCandidate != null,
      );
    }
    final now = DateTime.now();
    return ZoneItem(
      id: id,
      zoneId: _selectedSpaceId,
      scannedCode: _scannedCode,
      scannedCodeFormat: _scannedCodeFormat,
      scannedSourceUrl: _scannedSourceUrl,
      visualCandidateId: _visualCandidate?.id,
      releasePeriod: _visualCandidate?.releasePeriod,
      name: category,
      nickname: nickname.isEmpty ? null : nickname,
      purchaseDate: _purchaseDate,
      installedDate: _installedDate,
      note: note.isEmpty ? null : note,
      type: _selectedType,
      summary: '$category 제품의 세부 관리법은 아직 준비 중이에요.',
      frequency: '제품 설명서의 권장 주기 확인',
      supplies: const [],
      cautions: const [
        '정확한 제품 종류와 재질을 확인하기 전에는 세제나 물을 사용하지 마세요.',
        '가전은 전원을 분리하고 제조사 안전 지침을 우선하세요.',
      ],
      steps: [
        '$category의 브랜드, 모델명과 관리 라벨을 확인해요.',
        '앱에서 정확한 관리법을 찾을 때까지 제조사 설명서를 우선해요.',
      ],
      manufacturer: brand.isEmpty ? null : brand,
      modelName: model.isEmpty ? null : model,
      productMethod: _visualCandidate?.formFactor,
      guideStatus: '이 제품군의 검수된 세부 관리법을 준비하고 있어요.',
      guideBasis: '잘못된 공통 청소법을 제공하지 않고 제조사 설명서를 우선하도록 안내해요.',
      guideSourceType: GuideSourceType.general,
      matchLevelLabel: model.isEmpty ? '사용자 입력 제품군' : '사용자 입력 모델',
      sourceTitle: '사용자 등록 정보',
      sourceCheckedAt: now,
      productSpecs: [
        if (brand.isNotEmpty) '브랜드/제조사: $brand',
        if (model.isNotEmpty) '모델명: $model',
      ],
      recurrenceDays: 30,
      recommendedSupplies: const [],
    );
  }

  ZoneItem? _findDuplicate(ZoneItem product) {
    final nickname = _normalize(product.nickname ?? '');
    final model = _normalize(product.modelName ?? '');
    for (final existing in widget.existingProducts) {
      if (existing.zoneId != product.zoneId) {
        continue;
      }
      if (product.catalogProductId != null &&
          existing.catalogProductId == product.catalogProductId) {
        return existing;
      }
      if (model.isNotEmpty && _normalize(existing.modelName ?? '') == model) {
        return existing;
      }
      if (nickname.isNotEmpty &&
          _normalize(existing.nickname ?? '') == nickname) {
        return existing;
      }
    }
    return null;
  }

  Future<_DuplicateDecision?> _showDuplicateDialog(ZoneItem existing) {
    return showDialog<_DuplicateDecision>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비슷한 제품이 이미 있어요'),
        content: Text(
          '${existing.displayName} 제품이 ${_selectedSpace.name}에 등록되어 있어요. '
          '같은 모델을 여러 대 등록하는 경우에는 별도 제품으로 계속할 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('별칭 확인'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              _DuplicateDecision.openExisting,
            ),
            child: const Text('기존 제품 보기'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              _DuplicateDecision.registerSeparate,
            ),
            child: const Text('별도 제품으로 등록'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestProductInformation() async {
    final query = _searchController.text.trim();
    final now = DateTime.now();
    final existing =
        await widget.dataRepository.loadProductSearchRequests() ?? [];
    final request = ProductSearchRequest(
      id: 'request-${now.microsecondsSinceEpoch}',
      query: query,
      requestedAt: now,
      registeredAsGeneral: false,
    );
    await widget.dataRepository.saveProductSearchRequests([
      request,
      ...existing,
    ]);
    await _saveMissingProductSubmission(
      id: request.id,
      query: query,
      now: now,
      registeredAsGeneral: false,
    );
    if (mounted) {
      _showMessage('제품 정보 요청을 요청 내역에 저장했어요.');
    }
  }

  Future<void> _loadRecentSearches() async {
    final searches = await widget.dataRepository.loadRecentProductSearches();
    if (mounted) {
      setState(() => _recentSearches = searches.take(5).toList());
    }
  }

  Future<void> _openCodeScanner() async {
    final result = await Navigator.of(context).push<ProductCodeScanResult>(
      MaterialPageRoute(
        builder: (context) => const ProductCodeScannerScreen(),
      ),
    );
    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _scannedCode = result.rawValue;
      _scannedCodeFormat = result.format;
      _scannedSourceUrl = result.sourceUrl;
      _searchController.text = result.searchQuery;
    });
    _searchCatalog(result.searchQuery);
    _showMessage('코드를 읽었어요. 연결된 제품 정보를 찾고 있어요.');
  }

  Future<void> _openProductFinder() async {
    final category = _categoryController.text.trim();
    final brand = _brandController.text.trim();
    if (brand.isEmpty) {
      return;
    }
    final result = await Navigator.of(context).push<ProductFinderResult>(
      MaterialPageRoute(
        builder: (context) => ModelSelectionScreen(
          categoryName: category,
          brand: brand,
          catalogRepository: widget.catalogRepository,
          selectedModel: _modelController.text.trim().isEmpty
              ? null
              : _modelController.text.trim(),
        ),
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      if (result.isExactModel) {
        _modelController.text = result.modelName;
        _visualCandidate = null;
      } else {
        final candidate = result.visualCandidate;
        if (candidate != null) {
          _visualCandidate = candidate;
          _categoryController.text = candidate.categoryName;
          _modelController.clear();
          _selectedType = ZoneItemType.appliance;
        }
      }
    });
  }

  void _searchCatalog(String value) {
    final query = value.trim();
    _searchDebounce?.cancel();
    setState(() {
      _searchQuery = query;
      _searchResults = [];
      _isSearching = query.isNotEmpty;
    });
    if (query.isEmpty) {
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await widget.catalogRepository.search(query, limit: 8);
      if (!mounted || query != _searchQuery) {
        return;
      }
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  Future<void> _selectEntry(ProductCatalogEntry entry) async {
    await _rememberSearch(_searchController.text.trim());
    setState(() {
      _selectedEntry = entry;
      _manualMode = false;
      _step = 1;
    });
  }

  void _startManualRegistration({
    _ProductPreset? preset,
    bool fromSearchFailure = false,
  }) {
    setState(() {
      _manualMode = true;
      _startedFromSearchFailure = fromSearchFailure;
      _selectedEntry = null;
      if (preset != null) {
        _categoryController.text = preset.name;
        _selectedType = preset.type;
      } else if (_searchQuery.isNotEmpty) {
        _categoryController.text = _searchQuery;
      }
      _step = 1;
    });
    _loadBrandOptions();
  }

  Future<void> _loadBrandOptions() async {
    final category = _categoryController.text.trim();
    if (category.isEmpty) {
      if (mounted) {
        setState(() {
          _brandOptions = [];
          _isLoadingBrands = false;
        });
      }
      return;
    }
    setState(() => _isLoadingBrands = true);
    final brands = await widget.catalogRepository.brandsFor(category);
    if (!mounted || category != _categoryController.text.trim()) {
      return;
    }
    setState(() {
      _brandOptions = brands;
      _isLoadingBrands = false;
    });
  }

  Future<void> _rememberSearch(String query) async {
    if (query.isEmpty) {
      return;
    }
    final searches = [
      query,
      for (final item in _recentSearches)
        if (_normalize(item) != _normalize(query)) item,
    ].take(5).toList();
    await widget.dataRepository.saveRecentProductSearches(searches);
    if (mounted) {
      setState(() => _recentSearches = searches);
    }
  }

  Future<void> _pickDate({required bool isPurchaseDate}) async {
    final initialDate =
        (isPurchaseDate ? _purchaseDate : _installedDate) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      initialDate: initialDate,
    );
    if (date == null || !mounted) {
      return;
    }
    setState(() {
      if (isPurchaseDate) {
        _purchaseDate = date;
      } else {
        _installedDate = date;
      }
    });
  }

  Future<void> _finish({required bool openDetails}) async {
    final product = _draftProduct;
    if (product == null) {
      return;
    }
    if (_startedFromSearchFailure) {
      final now = DateTime.now();
      final existing =
          await widget.dataRepository.loadProductSearchRequests() ?? [];
      final request = ProductSearchRequest(
        id: 'request-${now.microsecondsSinceEpoch}',
        query: _searchQuery,
        categoryName: _categoryController.text.trim(),
        brand: _brandController.text.trim(),
        modelName: _modelController.text.trim(),
        requestedAt: now,
        registeredAsGeneral: true,
      );
      await widget.dataRepository.saveProductSearchRequests([
        request,
        ...existing,
      ]);
      await _saveMissingProductSubmission(
        id: request.id,
        query: _searchQuery,
        now: now,
        registeredAsGeneral: true,
      );
      if (!mounted) {
        return;
      }
    }
    Navigator.of(context).pop(
      ProductRegistrationResult.created(
        product,
        openDetails: openDetails,
      ),
    );
  }

  Future<void> _saveMissingProductSubmission({
    required String id,
    required String query,
    required DateTime now,
    required bool registeredAsGeneral,
  }) async {
    final existing = await widget.dataRepository.loadProductSubmissions() ?? [];
    if (existing.any((submission) => submission.id == id)) {
      return;
    }
    final category = _categoryController.text.trim();
    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();
    final detailParts = [
      if (query.isNotEmpty) '검색어: $query',
      if (category.isNotEmpty) '제품 종류: $category',
      if (brand.isNotEmpty) '브랜드: $brand',
      if (model.isNotEmpty) '모델명: $model',
      registeredAsGeneral ? '제품군 일반 정보로 먼저 등록함' : '제품 정보 추가를 요청함',
    ];
    final submission = ProductSubmission(
      id: id,
      type: ProductSubmissionType.missingProduct,
      title: query.isEmpty ? '검색되지 않는 제품 정보 요청' : '$query 제품 정보 요청',
      details: detailParts.join('\n'),
      categoryName: category.isEmpty ? null : category,
      brand: brand.isEmpty ? null : brand,
      modelName: model.isEmpty ? null : model,
      createdAt: now,
      updatedAt: now,
      status: ProductSubmissionStatus.pendingUpload,
    );
    await widget.dataRepository.saveProductSubmissions([
      submission,
      ...existing,
    ]);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
      _isSearching = false;
    });
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  ProductSpace get _selectedSpace {
    return widget.spaces.firstWhere(
      (space) => space.id == _selectedSpaceId,
      orElse: () => widget.space,
    );
  }

  IconData _iconFor(ZoneItemType type) {
    return switch (type) {
      ZoneItemType.appliance => Icons.kitchen_outlined,
      ZoneItemType.furniture => Icons.chair_outlined,
      ZoneItemType.fixture => Icons.countertops_outlined,
      ZoneItemType.other => Icons.inventory_2_outlined,
    };
  }
}

enum _DuplicateDecision { openExisting, registerSeparate }

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['찾기', '확인', '내 정보', '완료'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= currentStep
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: index == currentStep
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (index != labels.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _CatalogResultCard extends StatelessWidget {
  const _CatalogResultCard({
    required this.entry,
    required this.onTap,
  });

  final ProductCatalogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
        title: Text(entry.name),
        subtitle: Text(
          '${[
            entry.brand,
            entry.seriesName,
            entry.modelName
          ].where((value) => value.isNotEmpty).join(' · ')}\n'
          '${entry.categoryName} · ${_reviewStatusLabel(entry.reviewStatus)} · '
          '${_formatDate(entry.sourceCheckedAt)} 확인',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _NoSearchResult extends StatelessWidget {
  const _NoSearchResult({
    required this.query,
    required this.onManual,
    required this.onRequest,
  });

  final String query;
  final VoidCallback onManual;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '"$query" 제품을 찾지 못했어요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text('직접 등록하거나 제품 정보 추가를 요청할 수 있어요.'),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: onManual,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('직접 입력해 등록'),
            ),
            TextButton.icon(
              onPressed: onRequest,
              icon: const Icon(Icons.outbox_outlined),
              label: const Text('제품 정보 추가 요청'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value == null ? '선택하지 않음' : _formatDate(value!)),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      child: Text(value),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ScannedCodeSummary extends StatelessWidget {
  const _ScannedCodeSummary({
    required this.code,
    required this.format,
  });

  final String code;
  final String? format;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '코드 인식 완료',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${format ?? 'unknown'} · $code',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualCandidateSummary extends StatelessWidget {
  const _VisualCandidateSummary({required this.candidate});

  final VisualProductCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(candidate.icon, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(candidate.formFactor),
                Text(
                  candidate.releasePeriod,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Chip(label: Text('유사 제품')),
        ],
      ),
    );
  }
}

class _ProductPreset {
  const _ProductPreset(this.name, this.type, this.icon);

  final String name;
  final ZoneItemType type;
  final IconData icon;
}

List<_ProductPreset> _recommendedProductsFor(String spaceName) {
  final normalized = spaceName.toLowerCase().replaceAll(RegExp(r'\s+'), '');

  if (_containsAny(normalized, const ['주방', '부엌', '키친'])) {
    return _kitchenProducts;
  }
  if (_containsAny(normalized, const ['거실', '응접실', '리빙'])) {
    return _livingRoomProducts;
  }
  if (_containsAny(normalized, const ['욕실', '화장실', '샤워'])) {
    return _bathroomProducts;
  }
  if (_containsAny(
    normalized,
    const ['침실', '안방', '아이방', '자녀방', '게스트룸', '방'],
  )) {
    return _bedroomProducts;
  }
  if (_containsAny(normalized, const ['세탁실', '다용도실'])) {
    return _laundryRoomProducts;
  }
  if (_containsAny(normalized, const ['서재', '공부방', '작업실', '오피스'])) {
    return _officeProducts;
  }
  if (_containsAny(normalized, const ['현관', '입구'])) {
    return _entranceProducts;
  }
  if (_containsAny(normalized, const ['베란다', '발코니'])) {
    return _balconyProducts;
  }
  return _commonProducts;
}

bool _containsAny(String value, List<String> keywords) {
  return keywords.any(value.contains);
}

const _kitchenProducts = [
  _ProductPreset('냉장고', ZoneItemType.appliance, Icons.kitchen_outlined),
  _ProductPreset('음식물처리기', ZoneItemType.appliance, Icons.delete_outline),
  _ProductPreset('전자레인지', ZoneItemType.appliance, Icons.microwave_outlined),
  _ProductPreset('식기세척기', ZoneItemType.appliance, Icons.local_dining_outlined),
  _ProductPreset('정수기', ZoneItemType.appliance, Icons.water_drop_outlined),
  _ProductPreset('싱크대', ZoneItemType.fixture, Icons.countertops_outlined),
];

const _livingRoomProducts = [
  _ProductPreset('TV', ZoneItemType.appliance, Icons.tv_outlined),
  _ProductPreset('소파', ZoneItemType.furniture, Icons.weekend_outlined),
  _ProductPreset(
      '테이블', ZoneItemType.furniture, Icons.table_restaurant_outlined),
  _ProductPreset('공기청정기', ZoneItemType.appliance, Icons.air),
  _ProductPreset('에어컨', ZoneItemType.appliance, Icons.ac_unit_outlined),
  _ProductPreset('러그', ZoneItemType.furniture, Icons.grid_on_outlined),
];

const _bathroomProducts = [
  _ProductPreset('세면대', ZoneItemType.fixture, Icons.wash_outlined),
  _ProductPreset('변기', ZoneItemType.fixture, Icons.wc_outlined),
  _ProductPreset('샤워부스', ZoneItemType.fixture, Icons.shower_outlined),
  _ProductPreset('욕조', ZoneItemType.fixture, Icons.bathtub_outlined),
  _ProductPreset('환풍기', ZoneItemType.appliance, Icons.air_outlined),
  _ProductPreset('욕실장', ZoneItemType.furniture, Icons.inventory_2_outlined),
];

const _bedroomProducts = [
  _ProductPreset('침대', ZoneItemType.furniture, Icons.bed_outlined),
  _ProductPreset('매트리스', ZoneItemType.furniture, Icons.bedroom_parent_outlined),
  _ProductPreset('옷장', ZoneItemType.furniture, Icons.checkroom_outlined),
  _ProductPreset('화장대', ZoneItemType.furniture, Icons.desk_outlined),
  _ProductPreset('에어컨', ZoneItemType.appliance, Icons.ac_unit_outlined),
  _ProductPreset('공기청정기', ZoneItemType.appliance, Icons.air),
];

const _laundryRoomProducts = [
  _ProductPreset('세탁기', ZoneItemType.appliance, Icons.local_laundry_service),
  _ProductPreset('건조기', ZoneItemType.appliance, Icons.dry_cleaning_outlined),
  _ProductPreset('세탁조', ZoneItemType.fixture, Icons.countertops_outlined),
  _ProductPreset('빨래건조대', ZoneItemType.fixture, Icons.dry_outlined),
];

const _officeProducts = [
  _ProductPreset('책상', ZoneItemType.furniture, Icons.desk_outlined),
  _ProductPreset('의자', ZoneItemType.furniture, Icons.chair_outlined),
  _ProductPreset('모니터', ZoneItemType.appliance, Icons.desktop_windows_outlined),
  _ProductPreset('컴퓨터', ZoneItemType.appliance, Icons.computer_outlined),
  _ProductPreset('책장', ZoneItemType.furniture, Icons.menu_book_outlined),
];

const _entranceProducts = [
  _ProductPreset('신발장', ZoneItemType.furniture, Icons.checkroom_outlined),
  _ProductPreset('현관문', ZoneItemType.fixture, Icons.door_front_door_outlined),
  _ProductPreset('중문', ZoneItemType.fixture, Icons.meeting_room_outlined),
  _ProductPreset('현관 매트', ZoneItemType.furniture, Icons.grid_on_outlined),
];

const _balconyProducts = [
  _ProductPreset('창문', ZoneItemType.fixture, Icons.window_outlined),
  _ProductPreset('방충망', ZoneItemType.fixture, Icons.grid_4x4_outlined),
  _ProductPreset('실외기', ZoneItemType.appliance, Icons.ac_unit_outlined),
  _ProductPreset('수납장', ZoneItemType.furniture, Icons.inventory_2_outlined),
];

const _commonProducts = [
  _ProductPreset('에어컨', ZoneItemType.appliance, Icons.ac_unit_outlined),
  _ProductPreset('공기청정기', ZoneItemType.appliance, Icons.air),
  _ProductPreset('수납장', ZoneItemType.furniture, Icons.inventory_2_outlined),
  _ProductPreset(
      '테이블', ZoneItemType.furniture, Icons.table_restaurant_outlined),
];

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}

String _reviewStatusLabel(String status) {
  return switch (status) {
    'verified' => '확인됨',
    'reviewed' => '검수됨',
    _ => '검토 중',
  };
}
