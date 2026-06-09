import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../utils/product_code_parser.dart';

class ProductCodeScanResult {
  const ProductCodeScanResult({
    required this.rawValue,
    required this.searchQuery,
    required this.format,
    this.sourceUrl,
  });

  final String rawValue;
  final String searchQuery;
  final String format;
  final String? sourceUrl;
}

class ProductCodeScannerScreen extends StatefulWidget {
  const ProductCodeScannerScreen({super.key});

  @override
  State<ProductCodeScannerScreen> createState() =>
      _ProductCodeScannerScreenState();
}

class _ProductCodeScannerScreenState extends State<ProductCodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('QR·바코드 스캔'),
        actions: [
          IconButton(
            tooltip: '손전등',
            onPressed: _controller.toggleTorch,
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
          IconButton(
            tooltip: '카메라 전환',
            onPressed: _controller.switchCamera,
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleCapture,
            errorBuilder: (context, error) => _ScannerError(error: error),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 270,
                height: 190,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Text(
                '제품이나 설명서의 QR 코드 또는 바코드를 사각형 안에 맞춰주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_handled) {
      return;
    }
    final barcode = capture.barcodes
        .where((item) => item.rawValue?.trim().isNotEmpty == true)
        .firstOrNull;
    final rawValue = barcode?.rawValue?.trim();
    if (barcode == null || rawValue == null) {
      return;
    }

    _handled = true;
    await _controller.stop();
    if (!mounted) {
      return;
    }
    final parsed = parseProductCode(rawValue);
    Navigator.of(context).pop(
      ProductCodeScanResult(
        rawValue: parsed.rawValue,
        searchQuery: parsed.searchQuery,
        sourceUrl: parsed.sourceUrl,
        format: barcode.format.name,
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white,
                size: 44,
              ),
              const SizedBox(height: 14),
              const Text(
                '카메라를 사용할 수 없어요.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.errorDetails?.message ?? '카메라 권한과 기기 설정을 확인해주세요.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
