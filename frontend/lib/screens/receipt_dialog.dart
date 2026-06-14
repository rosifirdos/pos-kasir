import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

final _formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class ReceiptWidget extends StatelessWidget {
  final dynamic transaction;

  const ReceiptWidget({Key? key, required this.transaction}) : super(key: key);

  pw.Document _generatePdfDocument() {
    final pdf = pw.Document();
    final date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(transaction['createdAt']));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('GARIS AWAN POS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.Text('Jl. Digitalisasi Bangsa No. 1'),
                    pw.Text('Telp: 0812-3456-7890'),
                    pw.SizedBox(height: 10),
                    pw.Text('STRUK PEMBAYARAN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Divider(borderStyle: pw.BorderStyle.dashed),
                  ],
                ),
              ),
              pw.Text('No. Invoice: ${transaction['invoiceNumber']}'),
              pw.Text('Tanggal: $date'),
              pw.Text('Metode: ${transaction['paymentMethod']}'),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),
              ...(transaction['details'] as List).map((item) {
                final double discount = double.tryParse(item['discountAmount']?.toString() ?? '0') ?? 0.0;
                final double unitPrice = double.tryParse(item['unitPrice']?.toString() ?? '0') ?? 0.0;
                final double originalSubtotal = unitPrice * item['quantity'];

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(child: pw.Text('${item['product']['name']} x${item['quantity']}')),
                        pw.Text(_formatter.format(originalSubtotal)),
                      ],
                    ),
                    if (discount > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 10),
                            child: pw.Text('  Diskon Item', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10, color: PdfColors.grey700)),
                          ),
                          pw.Text('-${_formatter.format(discount)}', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10, color: PdfColors.grey700)),
                        ],
                      ),
                  ],
                );
              }).toList(),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              if (double.parse(transaction['discountAmount']?.toString() ?? '0') > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal'),
                    pw.Text(_formatter.format(double.parse(transaction['totalAmount'].toString()) + double.parse(transaction['discountAmount'].toString()))),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Diskon'),
                    pw.Text('-${_formatter.format(double.parse(transaction['discountAmount'].toString()))}'),
                  ],
                ),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
              ],
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.Text(_formatter.format(double.parse(transaction['totalAmount'].toString())), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Terima Kasih atas Kunjungan Anda!')),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  Future<void> _printReceipt() async {
    final pdf = _generatePdfDocument();
    final String invoiceNumber = transaction['invoiceNumber'] ?? 'INV';
    final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final String fileName = 'Struk_${invoiceNumber}_$timestamp';

    // Temporary update app title for Web printing default filename
    try {
      await SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(
          label: fileName,
          primaryColor: 0xFF000000,
        ),
      );
    } catch (_) {}

    await Printing.layoutPdf(
      name: fileName,
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );

    try {
      await SystemChrome.setApplicationSwitcherDescription(
        const ApplicationSwitcherDescription(
          label: 'Garis Awan POS',
          primaryColor: 0xFF000000,
        ),
      );
    } catch (_) {}
  }

  Future<void> _savePdf() async {
    final pdf = _generatePdfDocument();
    final String invoiceNumber = transaction['invoiceNumber'] ?? 'INV';
    final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final String fileName = 'Struk_${invoiceNumber}_$timestamp.pdf';

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: fileName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final details = transaction['details'] as List;
    final date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(transaction['createdAt']));
    
    final receiptTextStyle = GoogleFonts.firaCode(
      fontSize: 13,
      color: Colors.black87,
    );

    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simulate paper top edge
          Container(height: 10, decoration: const BoxDecoration(color: Colors.white)),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text('GARIS AWAN POS', style: receiptTextStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
                      Text('Jl. Digitalisasi Bangsa No. 1', style: receiptTextStyle),
                      Text('Telp: 0812-3456-7890', style: receiptTextStyle),
                      const SizedBox(height: 16),
                      Text('STRUK PEMBAYARAN', style: receiptTextStyle.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDashedLine(),
                const SizedBox(height: 16),
                Text('No. Invoice : ${transaction['invoiceNumber']}', style: receiptTextStyle),
                Text('Tanggal     : $date', style: receiptTextStyle),
                Text('Metode      : ${transaction['paymentMethod']}', style: receiptTextStyle),
                const SizedBox(height: 16),
                _buildDashedLine(),
                const SizedBox(height: 16),
                 ...details.map((item) {
                  final double discount = double.tryParse(item['discountAmount']?.toString() ?? '0') ?? 0.0;
                  final double unitPrice = double.tryParse(item['unitPrice']?.toString() ?? '0') ?? 0.0;
                  final double originalSubtotal = unitPrice * item['quantity'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text('${item['product']['name']}\n${item['quantity']} x ${_formatter.format(unitPrice)}', style: receiptTextStyle)),
                            Text(_formatter.format(originalSubtotal), style: receiptTextStyle),
                          ],
                        ),
                        if (discount > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('  Diskon Item', style: receiptTextStyle.copyWith(color: Colors.green, fontStyle: FontStyle.italic, fontSize: 11)),
                                Text('-${_formatter.format(discount)}', style: receiptTextStyle.copyWith(color: Colors.green, fontStyle: FontStyle.italic, fontSize: 11)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
                _buildDashedLine(),
                const SizedBox(height: 16),
                if (double.parse(transaction['discountAmount']?.toString() ?? '0') > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SUBTOTAL', style: receiptTextStyle),
                      Text(_formatter.format(double.parse(transaction['totalAmount'].toString()) + double.parse(transaction['discountAmount'].toString())), style: receiptTextStyle),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('DISKON', style: receiptTextStyle.copyWith(color: Colors.green)),
                      Text('-${_formatter.format(double.parse(transaction['discountAmount'].toString()))}', style: receiptTextStyle.copyWith(color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDashedLine(),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL', style: receiptTextStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(_formatter.format(double.parse(transaction['totalAmount'].toString())), 
                      style: receiptTextStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 32),
                Center(child: Text('Terima Kasih atas Kunjungan Anda!', style: receiptTextStyle, textAlign: TextAlign.center)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: _savePdf,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Simpan PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _printReceipt,
                  icon: const Icon(Icons.print),
                  label: const Text('Cetak Struk', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: Colors.black54)),
            );
          }),
        );
      },
    );
  }
}
