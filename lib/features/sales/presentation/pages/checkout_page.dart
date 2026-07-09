import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/common/custom_button.dart';
import '../../../../core/storage/models/local_product.dart';
import '../../../../core/storage/models/local_customer.dart';
import '../../../../core/widgets/common/scanner/barcode_scanner_widget.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../loyalty/presentation/providers/loyalty_provider.dart';
import '../providers/sales_provider.dart';
import 'sale_receipt_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _paymentCurrency = 'USD';
  final TextEditingController _tenderedController = TextEditingController();
  final TextEditingController _customerPOController = TextEditingController();
  bool _convertChangeToPoints = false;

  @override
  void initState() {
    super.initState();
    // Use base currency as default payment currency if possible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inventory = context.read<InventoryProvider>();
      setState(() => _paymentCurrency = inventory.settings.baseCurrency);
    });
  }

  @override
  void dispose() {
    _tenderedController.dispose();
    _customerPOController.dispose();
    super.dispose();
  }

  /// Shows the quantity dialog and returns true if the user wants to keep scanning/browsing,
  /// or false if they clicked "Checkout"
  Future<bool> _showScanQuantityDialog(BuildContext context, LocalProduct product, {bool isScanning = true}) async {
    int tempQty = 1;
    final inventory = context.read<InventoryProvider>();
    final baseCurrency = inventory.settings.baseCurrency;
    final unitPriceInBase = inventory.convertToCurrency(product.price, product.currency ?? 'USD', baseCurrency);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isScanning ? 'Scanned: ${product.name}' : 'Selected: ${product.name}', 
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Price: ${product.currency ?? 'USD'} ${product.price.toStringAsFixed(2)}', 
                    style: const TextStyle(fontSize: 14, color: Colors.grey)
                  ),
                  Text(
                    'Total ($baseCurrency): \$${unitPriceInBase.toStringAsFixed(2)}', 
                    style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  Text('Available Stock: ${product.currentStock}', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 24),
                  const Text('Enter Quantity:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 32,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: tempQty > 1 ? () => setState(() => tempQty--) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('$tempQty', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        iconSize: 32,
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: tempQty < product.currentStock 
                            ? () => setState(() => tempQty++) 
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Checkout'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(isScanning ? 'Scan Next' : 'Next Item'),
                ),
              ],
            );
          }
        );
      },
    );

    if (result != null && context.mounted) {
       context.read<SalesProvider>().addToCart(product, tempQty);
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Added $tempQty x ${product.name} to cart'))
       );
    }
    
    return result ?? false;
  }

  Future<void> _scanBarcode(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (scannerCtx) => BarcodeScannerWidget(
          continuous: true,
          onDetectAsync: (code) async {
            final inventory = scannerCtx.read<InventoryProvider>();
            final product = inventory.products.where((p) => p.barcode == code).firstOrNull;
            
            if (product != null) {
              if (product.currentStock > 0) {
                 bool shouldContinue = await _showScanQuantityDialog(scannerCtx, product, isScanning: true);
                 if (!shouldContinue && scannerCtx.mounted) {
                    Navigator.pop(scannerCtx);
                 }
              } else {
                 ScaffoldMessenger.of(scannerCtx).showSnackBar(
                   const SnackBar(content: Text('Out of stock!'), backgroundColor: Colors.red)
                 );
                 await Future.delayed(const Duration(seconds: 2));
              }
            } else {
              ScaffoldMessenger.of(scannerCtx).showSnackBar(
                SnackBar(content: Text('Unknown barcode: $code'), backgroundColor: Colors.orange)
              );
              await Future.delayed(const Duration(seconds: 2));
            }
          },
        ),
      ),
    );
  }

  void _showProductSelector(BuildContext context) {
    String query = ''; // Persistent for the life of the modal
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  final inventory = context.watch<InventoryProvider>();
                  final products = inventory.products.where((p) => p.effectiveIsDiscontinued == false && p.currentStock > 0).toList();
                  final filtered = products.where((p) {
                    final q = query.toLowerCase();
                    return p.name.toLowerCase().contains(q) || 
                           (p.barcode?.toLowerCase().contains(q) ?? false);
                  }).toList();

                  return Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Select Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(modalCtx)),
                          ],
                        ),
                      ),
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          onChanged: (v) => setModalState(() => query = v),
                          decoration: InputDecoration(
                            hintText: 'Search by name or stock code...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Product List
                      Expanded(
                        child: filtered.isEmpty
                          ? const Center(child: Text('No products found'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final p = filtered[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade50,
                                    child: Text(p.name[0].toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('${p.currency ?? 'USD'} ${p.price.toStringAsFixed(2)} • Stock: ${p.currentStock}'),
                                  trailing: const Icon(Icons.add_circle_outline, color: Colors.blue),
                                  onTap: () async {
                                    // Don't close modal, just show quantity dialog
                                    bool shouldContinue = await _showScanQuantityDialog(modalCtx, p, isScanning: false);
                                    if (!shouldContinue && modalCtx.mounted) {
                                      Navigator.pop(modalCtx);
                                    } else {
                                      setModalState(() {});
                                    }
                                  },
                                );
                              },
                            ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showCustomerSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer<LoyaltyProvider>(
          builder: (context, loyalty, child) {
            final customers = loyalty.customers;
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Select Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: customers.isEmpty 
                    ? const Center(child: Text('No customers found'))
                    : ListView.builder(
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final c = customers[index];
                          return ListTile(
                            title: Text(c.name),
                            subtitle: Text(c.phoneNumber),
                            trailing: Text('${c.points} pts'),
                            onTap: () {
                              context.read<SalesProvider>().selectCustomer(c.id);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRedeemDialog(BuildContext context, int maxPoints) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Redeem Points'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Points to redeem (Max: $maxPoints)',
              helperText: '100 points = \$1.00',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final pts = int.tryParse(controller.text) ?? 0;
                if (pts > maxPoints) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Insufficient points')),
                  );
                  return;
                }
                context.read<SalesProvider>().setPointsToRedeem(pts);
                Navigator.pop(ctx);
              },
              child: const Text('Redeem'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final baseCurrency = inventory.settings.baseCurrency;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Cart')),
      body: Consumer<SalesProvider>(
        builder: (context, provider, child) {
          final items = provider.cart;
          final totalInBase = provider.getCartTotalInBase(inventory);
          final discountInUSD = provider.pointsToRedeem / 100.0;
          final discountInBase = inventory.convertToCurrency(discountInUSD, 'USD', baseCurrency);
          final netTotalInBase = totalInBase - discountInBase;
          
          final netTotalInPaymentCurrency = provider.convertAmount(
            netTotalInBase, 
            baseCurrency, 
            _paymentCurrency, 
            inventory
          );

          final double tendered = double.tryParse(_tenderedController.text) ?? 0;
          final double change = (tendered > netTotalInPaymentCurrency) ? (tendered - netTotalInPaymentCurrency) : 0;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Scan/Browse Buttons (More compact)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 2,
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.qr_code_scanner, size: 18),
                          label: const Text('SCAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () => _scanBarcode(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.list_alt, size: 18),
                          label: const Text('BROWSE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () => _showProductSelector(context),
                        ),
                      ),
                    ],
                  ),
                ),

                // Cart Items Section
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: Text('Cart is empty', style: TextStyle(color: Colors.grey.shade600))),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      final unitPriceInBase = inventory.convertToCurrency(item.unitPrice, item.currency ?? 'USD', baseCurrency);
                      return ListTile(
                        dense: true,
                        title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('x${item.quantity} - \$${unitPriceInBase.toStringAsFixed(2)} $baseCurrency', style: const TextStyle(fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                          onPressed: () => provider.removeFromCart(item.productId),
                        ),
                      );
                    },
                  ),

                // Customer & Loyalty Section
                if (items.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(top: BorderSide(color: Colors.grey.shade200))),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: provider.selectedCustomerId == null
                            ? const Text('Add Loyalty Customer', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12))
                            : Consumer<LoyaltyProvider>(
                                builder: (context, loyalty, child) {
                                  final customer = loyalty.customers.cast<LocalCustomer?>().firstWhere((c) => c?.id == provider.selectedCustomerId, orElse: () => null);
                                  if (customer == null) return const SizedBox.shrink();
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('${customer.points} pts available', style: const TextStyle(fontSize: 10)),
                                    ],
                                  );
                                },
                              ),
                        ),
                        TextButton(
                          onPressed: () => _showCustomerSelector(context),
                          child: Text(provider.selectedCustomerId == null ? 'Select' : 'Change', style: const TextStyle(fontSize: 12)),
                        ),
                        if (provider.selectedCustomerId != null)
                          IconButton(
                            icon: const Icon(Icons.card_giftcard, color: Colors.orange, size: 18),
                            onPressed: () {
                              final loyalty = context.read<LoyaltyProvider>();
                              final customer = loyalty.customers.firstWhere((c) => c.id == provider.selectedCustomerId);
                              _showRedeemDialog(context, customer.points);
                            },
                          ),
                      ],
                    ),
                  ),

                  // Payment Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Column(
                      children: [
                        // Currency and Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            DropdownButton<String>(
                              value: _paymentCurrency,
                              underline: const SizedBox(),
                              items: ['USD', 'ZWL', 'ZAR', 'BP'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (v) => setState(() => _paymentCurrency = v!),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Total ($baseCurrency): \$${netTotalInBase.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                Text('Payable: $_paymentCurrency ${netTotalInPaymentCurrency.toStringAsFixed(2)}', 
                                     style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // Tender and Change
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _tenderedController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Tendered ($_paymentCurrency)',
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                style: const TextStyle(fontSize: 14),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Change Due:', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Text('$_paymentCurrency ${change.toStringAsFixed(2)}', 
                                     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ],
                            ),
                          ],
                        ),
                        
                        // Convert Change to Points
                        if (change > 0 && provider.selectedCustomerId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _convertChangeToPoints, 
                                    onChanged: (v) => setState(() => _convertChangeToPoints = v!)
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text('Convert change to points?', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                        ),

                        const SizedBox(height: 12),
                        TextField(
                          controller: _customerPOController,
                          decoration: const InputDecoration(
                            labelText: 'Customer Purchase Order # (Optional)',
                            isDense: true,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.receipt_long, size: 18),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),

                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'COMPLETE SALE',
                          onPressed: (tendered < netTotalInPaymentCurrency) 
                            ? null 
                            : () => _completeSale(inventory, provider),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
  void _completeSale(InventoryProvider inventory, SalesProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    final loyalty = context.read<LoyaltyProvider>();
    final tendered = double.tryParse(_tenderedController.text) ?? 0;
    final baseCurrency = inventory.settings.baseCurrency;
    
    // Calculate these before the async gap to be safe, though provider.convertAmount is sync
    final totalInBase = provider.getCartTotalInBase(inventory).toDouble();
    final discountInUSD = provider.pointsToRedeem / 100.0;
    final discountInBase = inventory.convertToCurrency(discountInUSD, 'USD', baseCurrency);
    final netTotalInBase = totalInBase - discountInBase;
    final netTotalInPaymentCurrency = provider.convertAmount(
      netTotalInBase, 
      baseCurrency, 
      _paymentCurrency, 
      inventory
    ).toDouble();
    final change = (tendered > netTotalInPaymentCurrency) ? (tendered - netTotalInPaymentCurrency) : 0.0;

    final sale = await provider.processSale(
      inventory: inventory,
      loyalty: loyalty,
      paymentCurrency: _paymentCurrency,
      tenderedAmount: tendered,
      change: change,
      changeConvertedToPoints: _convertChangeToPoints,
      customerPO: _customerPOController.text.isNotEmpty ? _customerPOController.text : null,
    );
    
    if (sale != null && mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sale processed successfully!'))
      );
      // Reset local state
      setState(() {
        _tenderedController.clear();
        _customerPOController.clear();
        _convertChangeToPoints = false;
      });
      // Navigate to Receipt Page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SaleReceiptPage(sale: sale)),
        );
      }
    }
  }
}
