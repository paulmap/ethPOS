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
            // Allow scanning another item after a short delay
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        onDetect: _handleDetect,
      ),
    );
  }
}
