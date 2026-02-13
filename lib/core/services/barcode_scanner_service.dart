/// Barcode scanner service for product lookup
library;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Barcode scanner service
class BarcodeScannerService {
  BarcodeScannerService._();

  /// Show barcode scanner and return scanned code
  static Future<String?> scanBarcode(BuildContext context) async {
    String? scannedCode;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BarcodeScannerModal(
        onScanned: (code) {
          scannedCode = code;
          Navigator.pop(context);
        },
      ),
    );

    return scannedCode;
  }
}

class _BarcodeScannerModal extends StatefulWidget {
  final void Function(String code) onScanned;

  const _BarcodeScannerModal({required this.onScanned});

  @override
  State<_BarcodeScannerModal> createState() => _BarcodeScannerModalState();
}

class _BarcodeScannerModalState extends State<_BarcodeScannerModal> {
  late MobileScannerController _controller;
  bool _isScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _isScanned = true;
        widget.onScanned(barcode.rawValue!);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Scan Barcode',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.flash_off),
                  onPressed: () => _controller.toggleTorch(),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scanner view
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  MobileScanner(controller: _controller, onDetect: _onDetect),
                  // Overlay
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  // Instructions
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Point camera at barcode',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Manual entry option
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: () => _showManualEntry(context),
              icon: const Icon(Icons.keyboard),
              label: const Text('Enter code manually'),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntry(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Barcode'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter barcode number'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context); // Close dialog
                widget.onScanned(controller.text);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
