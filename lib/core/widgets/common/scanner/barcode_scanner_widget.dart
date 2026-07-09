import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final Future<void> Function(String)? onDetectAsync;
  final Function(String)? onDetect;
  final bool continuous;

  const BarcodeScannerWidget({super.key, this.onDetect, this.onDetectAsync, this.continuous = false});

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  bool _isProcessing = false;
  final TextEditingController _manualController = TextEditingController();
  final FocusNode _manualFocus = FocusNode();

  static bool get _isMobilePlatform =>
      Platform.isAndroid || Platform.isIOS;

  void _handleDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() {
          _isProcessing = true;
        });

        if (widget.onDetectAsync != null) {
          await widget.onDetectAsync!(code);
          if (widget.continuous && mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        } else if (widget.onDetect != null) {
          widget.onDetect!(code);
          if (widget.continuous) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _isProcessing = false;
                });
              }
            });
          }
        }
      }
    }
  }

  void _handleManualSubmit(String value) {
    if (value.trim().isNotEmpty) {
      widget.onDetect?.call(value.trim());
      widget.onDetectAsync?.call(value.trim());
    }
  }

  @override
  void dispose() {
    _manualController.dispose();
    _manualFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: _isMobilePlatform
          ? MobileScanner(onDetect: _handleDetect)
          : _buildManualEntry(),
    );
  }

  Widget _buildManualEntry() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            'Barcode scanner is not available on this platform.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the barcode manually below:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _manualController,
            focusNode: _manualFocus,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter barcode',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleManualSubmit(_manualController.text),
              ),
            ),
            onSubmitted: _handleManualSubmit,
          ),
        ],
      ),
    );
  }
}
