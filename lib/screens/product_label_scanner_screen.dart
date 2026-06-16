import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/product_label_parser.dart';

class ProductLabelScanResult {
  const ProductLabelScanResult({
    required this.searchQuery,
    required this.recognizedText,
  });

  final String searchQuery;
  final String recognizedText;
}

class ProductLabelScannerScreen extends StatefulWidget {
  const ProductLabelScannerScreen({super.key});

  @override
  State<ProductLabelScannerScreen> createState() =>
      _ProductLabelScannerScreenState();
}

class _ProductLabelScannerScreenState extends State<ProductLabelScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isReading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('제품 라벨 읽기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            '모델명이 적힌 라벨을 촬영하세요',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('제품 옆면이나 뒷면의 모델명·형명 부분이 선명하게 보이면 좋아요.'),
          const SizedBox(height: 28),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.document_scanner_outlined, size: 72),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isReading ? null : () => _readLabel(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('라벨 촬영'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed:
                _isReading ? null : () => _readLabel(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('사진에서 선택'),
          ),
          if (_isReading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 24),
          Text(
            '인식 결과는 제품 검색에만 사용하며 사진은 앱에 저장하지 않아요.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _readLabel(ImageSource source) async {
    setState(() {
      _isReading = true;
      _errorMessage = null;
    });
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2200,
    );
    if (image == null) {
      if (mounted) setState(() => _isReading = false);
      return;
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(image.path),
      );
      final candidates = extractProductLabelCandidates(recognized.text);
      if (!mounted) {
        return;
      }
      if (candidates.isEmpty) {
        setState(() {
          _isReading = false;
          _errorMessage = '모델명 후보를 찾지 못했어요. 라벨을 더 가까이 촬영해보세요.';
        });
        return;
      }
      final selected = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  '모델명 후보를 선택하세요',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('제품 라벨과 같은 문자를 골라주세요.'),
              ),
              for (final candidate in candidates)
                ListTile(
                  leading: const Icon(Icons.qr_code_2),
                  title: Text(candidate.value),
                  onTap: () => Navigator.of(context).pop(candidate.value),
                ),
            ],
          ),
        ),
      );
      if (selected != null && mounted) {
        Navigator.of(context).pop(
          ProductLabelScanResult(
            searchQuery: selected,
            recognizedText: recognized.text,
          ),
        );
      } else if (mounted) {
        setState(() => _isReading = false);
      }
    } on Object {
      if (mounted) {
        setState(() {
          _isReading = false;
          _errorMessage = '사진의 글자를 읽지 못했어요. 다시 촬영해보세요.';
        });
      }
    } finally {
      await recognizer.close();
    }
  }
}
