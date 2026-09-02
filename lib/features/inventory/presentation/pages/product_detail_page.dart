import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/session/session_provider.dart';
import '../../../../core/storage/models/local_product.dart';
import '../../../../core/storage/models/stock_bin.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/widgets/pos/pos_bits.dart';
import '../../../../core/widgets/pos/pos_scaffold.dart';
import '../providers/bin_service.dart';

/// A product card with a compact bin strip; the deep dive is a tap away.
/// Cost and margin appear only when a supervisor has unlocked.
class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});

  final LocalProduct product;

  @override
  Widget build(BuildContext context) {
    final bins = context.watch<BinService>();
    final myBins = bins.forProduct(product.id);
    final canSeeMoney = context.watch<SessionProvider>().canSeeMoney;

    return PosScaffold(
      title: 'Product',
      trailing: TextButton(
        onPressed: () => Navigator.pushNamed(context, '/product/edit'),
        child: const Text('Edit'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        children: [
          PaperCard(
            padding: const EdgeInsets.all(20),
            radius: 20,
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
                            product.name,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.38,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SKU ${product.effectiveSku} · ${product.effectiveProductCode}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.placeholder,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Money(product.price, size: 22),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Metric(label: 'On hand', value: '${product.currentStock}'),
                    const SizedBox(width: 22),
                    _Metric(
                      label: 'Reorder at',
                      value: '${product.effectiveReorderLevel}',
                    ),
                    if (canSeeMoney) ...[
                      const SizedBox(width: 22),
                      _Metric(
                        label: 'Cost',
                        value:
                            '\$${product.effectiveCostPrice.toStringAsFixed(2)}',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Eyebrow('WHERE IT IS')),
              TextButton(
                onPressed: () => _moveSheet(context, myBins),
                child: const Text('Move stock'),
              ),
            ],
          ),
          if (myBins.isEmpty)
            PaperCard(
              child: Text(
                'No bin assigned yet. Add one so it can be found.',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            )
          else
            StackedList(
              children: [
                for (final bin in myBins)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bin.label,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bin.pickOrder <= 10
                                  ? 'picked from first'
                                  : 'backup stock',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.placeholder,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${bin.quantity}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          if (myBins.length > 1) ...[
            const SizedBox(height: 12),
            AiNote(
              text: 'Total across ${myBins.length} bins is '
                  '${bins.totalFor(product.id)}. '
                  '${myBins.first.label} is drawn down first.',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _moveSheet(BuildContext context, List<StockBin> myBins) async {
    if (myBins.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a second bin first')),
      );
      return;
    }
    final service = context.read<BinService>();
    final qtyController = TextEditingController(text: '1');
    var fromId = myBins.first.id;
    var toId = myBins[1].id;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Move stock',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: fromId,
                decoration: const InputDecoration(labelText: 'From'),
                items: [
                  for (final b in myBins)
                    DropdownMenuItem(
                      value: b.id,
                      child: Text('${b.label} (${b.quantity})'),
                    ),
                ],
                onChanged: (v) => setSheetState(() => fromId = v ?? fromId),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: toId,
                decoration: const InputDecoration(labelText: 'To'),
                items: [
                  for (final b in myBins)
                    DropdownMenuItem(value: b.id, child: Text(b.label)),
                ],
                onChanged: (v) => setSheetState(() => toId = v ?? toId),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final qty = int.tryParse(qtyController.text) ?? 0;
                  final ok = await service.move(
                    fromBinId: fromId,
                    toBinId: toId,
                    quantity: qty,
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Not enough in that bin')),
                    );
                  }
                },
                child: const Text('Move'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.mutedLight),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
