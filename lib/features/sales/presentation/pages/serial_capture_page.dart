import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../core/storage/models/product_extras.dart';
import '../../../../core/storage/models/serial_unit.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/widgets/pos/pos_bits.dart';
import '../../../../core/widgets/pos/pos_scaffold.dart';

/// A serialised line in the cart awaiting its serial.
class SerialRequirement {
  SerialRequirement({
    required this.productId,
    required this.productName,
    required this.binLabel,
    required this.warrantyMonths,
    this.serial,
  });

  final String productId;
  final String productName;
  final String binLabel;
  final int warrantyMonths;
  String? serial;

  bool get satisfied => (serial?.trim().isNotEmpty ?? false);

  DateTime get warrantyEnds =>
      DateTime.now().add(Duration(days: 30 * warrantyMonths));
}

/// A dedicated step between cart and payment, rather than friction on every
/// cart line: the assistant scans them all in one pass and payment stays
/// blocked until each tracked item has a serial.
class SerialCapturePage extends StatefulWidget {
  const SerialCapturePage({
    super.key,
    required this.requirements,
    required this.serials,
    required this.saleId,
    this.customerId,
  });

  final List<SerialRequirement> requirements;
  final Box<SerialUnit> serials;
  final String saleId;
  final String? customerId;

  /// Build the list from a cart. Services and non-serialised lines are skipped.
  static List<SerialRequirement> requirementsFor({
    required Map<String, String> cartProductNames,
    required Map<String, int> cartQuantities,
    required Box<ProductExtras> extras,
    required String Function(String productId) binLabelFor,
  }) {
    final out = <SerialRequirement>[];
    cartProductNames.forEach((productId, name) {
      final meta = extras.get(productId);
      if (meta == null || !meta.serialised || meta.isService) return;
      final qty = cartQuantities[productId] ?? 1;
      for (var i = 0; i < qty; i++) {
        out.add(SerialRequirement(
          productId: productId,
          productName: name,
          binLabel: binLabelFor(productId),
          warrantyMonths: meta.warrantyMonths,
        ));
      }
    });
    return out;
  }

  @override
  State<SerialCapturePage> createState() => _SerialCapturePageState();
}

class _SerialCapturePageState extends State<SerialCapturePage> {
  late final List<SerialRequirement> _items = widget.requirements;

  int get _done => _items.where((r) => r.satisfied).length;
  bool get _allDone => _done == _items.length;

  @override
  Widget build(BuildContext context) {
    return PosScaffold(
      title: 'Serial numbers',
      subtitle: '$_done of ${_items.length}',
      commandBar: false,
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
        child: ElevatedButton(
          onPressed: _allDone ? () => Navigator.pop(context, _persist()) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _allDone ? AppColors.primary : AppColors.hairlineStrong,
            disabledBackgroundColor: AppColors.hairlineStrong,
            disabledForegroundColor: AppColors.placeholder,
          ),
          child: const Text('Continue to payment'),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
            child: Text(
              '${_items.length} items in this sale are tracked. '
              'Scan or type each serial before payment.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.mutedLight,
              ),
            ),
          ),
          for (final item in _items) ...[
            _SerialCard(
              item: item,
              onChanged: (value) => setState(() => item.serial = value),
              onScan: () => _scan(item),
            ),
            const SizedBox(height: 12),
          ],
          if (_items.any((i) => i.warrantyMonths > 0))
            AiNote(
              text: 'Warranty dates are set from today and printed on the '
                  'receipt, so a customer can be checked later by serial.',
            ),
        ],
      ),
    );
  }

  /// Wire this to the existing BarcodeScannerWidget; the manual field is the
  /// fallback on platforms where scanning is unavailable.
  Future<void> _scan(SerialRequirement item) async {
    final code = await Navigator.pushNamed<String?>(context, '/scanner');
    if (code == null || !mounted) return;
    setState(() => item.serial = code);
  }

  List<SerialUnit> _persist() {
    final units = <SerialUnit>[];
    for (final item in _items) {
      final unit = SerialUnit(
        id: 'sn-${DateTime.now().microsecondsSinceEpoch}-${units.length}',
        productId: item.productId,
        serial: item.serial!.trim(),
        soldAt: DateTime.now(),
        saleId: widget.saleId,
        customerId: widget.customerId,
        warrantyEnds:
            item.warrantyMonths > 0 ? item.warrantyEnds : null,
      );
      widget.serials.put(unit.id, unit);
      units.add(unit);
    }
    return units;
  }
}

class _SerialCard extends StatelessWidget {
  const _SerialCard({
    required this.item,
    required this.onChanged,
    required this.onScan,
  });

  final SerialRequirement item;
  final ValueChanged<String> onChanged;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final done = item.satisfied;

    return PaperCard(
      padding: const EdgeInsets.all(18),
      radius: 20,
      borderColor: done ? AppColors.primary : AppColors.hairline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.warrantyMonths > 0
                          ? '${item.binLabel} · ${item.warrantyMonths}-month warranty'
                          : item.binLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ],
                ),
              ),
              if (done)
                const Icon(Icons.check, size: 19, color: AppColors.primary)
              else
                const Text(
                  'NEEDED',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.6,
                    color: AppColors.warning,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: onChanged,
            controller: TextEditingController(text: item.serial ?? '')
              ..selection = TextSelection.collapsed(
                offset: (item.serial ?? '').length,
              ),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              hintText: 'Scan or type serial',
              fillColor: done ? AppColors.background : AppColors.surface,
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                color: AppColors.primary,
                onPressed: onScan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
