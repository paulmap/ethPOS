import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/storage/models/local_sale.dart';
import '../../../../core/storage/models/app_settings.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';

class SaleReceiptPage extends StatefulWidget {
  final LocalSale sale;

  const SaleReceiptPage({super.key, required this.sale});

  @override
  State<SaleReceiptPage> createState() => _SaleReceiptPageState();
}

class _SaleReceiptPageState extends State<SaleReceiptPage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareAsImage(AppSettings settings) async {
    final Uint8List? image = await _screenshotController.capture();
    if (image != null) {
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/receipt_${widget.sale.receiptNumber ?? widget.sale.id}.png').create();
      await file.writeAsBytes(image);
      await Share.shareXFiles([XFile(file.path)], text: 'Receipt #${widget.sale.receiptNumber ?? widget.sale.id}');
    }
  }

  Future<void> _shareAsPdf(AppSettings settings) async {
    final pdf = pw.Document();
    final dateString = DateFormat('dd-MMMM-yy').format(widget.sale.timestamp);
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Align(
                  alignment: pw.Alignment.topRight,
                  child: pw.Text('Receipt No: #${widget.sale.receiptNumber ?? widget.sale.id}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Text(settings.effectiveBusinessName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text('${settings.effectiveCity}, ${settings.effectiveCountry}'),
                pw.Text(settings.effectiveEmail),
                pw.Text(settings.effectiveContactNumber),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.Text('ORDER DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Order ID'), pw.Text(widget.sale.customerPO ?? widget.sale.id.toUpperCase())]),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Date'), pw.Text(dateString)]),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Currency'), pw.Text(widget.sale.paymentCurrency ?? 'USD')]),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: const pw.TableBorder(bottom: pw.BorderSide(width: 1)),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                      ],
                    ),
                    ...widget.sale.items.map((item) => pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.productName)),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.unitPrice.toStringAsFixed(2), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text((item.unitPrice * item.quantity).toStringAsFixed(2), textAlign: pw.TextAlign.right)),
                      ],
                    )),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Grand Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(widget.sale.totalAmount.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]),
                pw.SizedBox(height: 40),
                pw.Center(child: pw.Text(settings.effectiveReceiptTagline, style: pw.TextStyle(fontStyle: pw.FontStyle.italic))),
              ],
            ),
          );
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/receipt_${widget.sale.receiptNumber ?? widget.sale.id}.pdf').create();
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Receipt #${widget.sale.receiptNumber ?? widget.sale.id}');
  }

  void _shareAsText(AppSettings settings) {
    final receiptNo = widget.sale.receiptNumber ?? widget.sale.id.substring(widget.sale.id.length - 6).toUpperCase();
    final buffer = StringBuffer();
    buffer.writeln(settings.effectiveBusinessName);
    buffer.writeln('${settings.effectiveCity}, ${settings.effectiveCountry}');
    buffer.writeln('Receipt No: #$receiptNo');
    if (widget.sale.customerPO != null) buffer.writeln('Order ID: ${widget.sale.customerPO}');
    buffer.writeln('--------------------------');
    for (var item in widget.sale.items) {
      buffer.writeln('${item.productName} x ${item.quantity} = ${(item.unitPrice * item.quantity).toStringAsFixed(2)}');
    }
    buffer.writeln('--------------------------');
    buffer.writeln('Total: ${widget.sale.totalAmount.toStringAsFixed(2)} ${widget.sale.paymentCurrency ?? "USD"}');
    buffer.writeln(settings.effectiveReceiptTagline);

    Share.share(buffer.toString(), subject: 'Sale Receipt #$receiptNo');
  }

  void _showShareOptions(BuildContext context, AppSettings settings) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Share Receipt As', style: TextStyle(fontWeight: FontWeight.bold))),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.blue),
                title: const Text('Image (PNG)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareAsImage(settings);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('PDF Document'),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareAsPdf(settings);
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.green),
                title: const Text('Plain Text'),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareAsText(settings);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<InventoryProvider>().settings;
    final dateString = DateFormat('dd-MMMM-yy').format(widget.sale.timestamp);
    final receiptNo = widget.sale.receiptNumber ?? widget.sale.id.substring(widget.sale.id.length - 6).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showShareOptions(context, settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Screenshot(
              controller: _screenshotController,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Header: Receipt No at top right
                    Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        'Receipt No: #$receiptNo',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Company Info
                    Text(
                      settings.effectiveBusinessName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text('${settings.effectiveCity}, ${settings.effectiveCountry}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    Text(settings.effectiveEmail, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    Text(settings.effectiveContactNumber, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    
                    const SizedBox(height: 30),
                    
                    const Divider(thickness: 1),
                    
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('ORDER DETAILS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                      ),
                    ),
                    _buildInfoRow('Order ID', widget.sale.customerPO ?? ''),
                    _buildInfoRow('Date', dateString),
                    _buildInfoRow('Payment Methods', widget.sale.paymentCurrency ?? 'Cash'),
                    
                    const Divider(thickness: 1, height: 40),
                    
                    // Items Table with improved spacing
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(4),
                        1: FixedColumnWidth(60),
                        2: FixedColumnWidth(80),
                        3: FixedColumnWidth(80),
                      },
                      children: [
                        const TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text('Amt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                        ...widget.sale.items.map((item) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(item.productName, style: const TextStyle(fontSize: 12)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text('${item.quantity}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.right),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(item.unitPrice.toStringAsFixed(2), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text((item.unitPrice * item.quantity).toStringAsFixed(2), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                            ),
                          ],
                        )),
                      ],
                    ),
                    
                    const Divider(thickness: 1, height: 40),
                    
                    _buildTotalRow('Sub Total', widget.sale.totalAmount + ((widget.sale.pointsRedeemed ?? 0) / 100)),
                    _buildTotalRow('Tax', 0.0), 
                    _buildTotalRow('Discount', ((widget.sale.pointsRedeemed ?? 0) / 100).toDouble()),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(thickness: 2),
                    ),
                    _buildTotalRow('Grand Total', widget.sale.totalAmount, isBold: true, fontSize: 18),
                    _buildTotalRow('Net Total', widget.sale.totalAmount.roundToDouble(), isBold: true),
                    
                    const SizedBox(height: 50),
                    Text('--- ${settings.effectiveReceiptTagline} ---', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showShareOptions(context, settings),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Placeholder for print
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty && label == 'Order ID') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value.toStringAsFixed(2), style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
