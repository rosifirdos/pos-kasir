import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';

final _formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class ReceiptWidget extends StatelessWidget {
  final dynamic transaction;

  const ReceiptWidget({Key? key, required this.transaction}) : super(key: key);

  Future<void> _printReceipt() async {
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
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text('${item['product']['name']} x${item['quantity']}')),
                    pw.Text(_formatter.format(double.parse(item['subtotal'].toString()))),
                  ],
                );
              }).toList(),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
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

    final String invoiceNumber = transaction['invoiceNumber'] ?? 'INV';
    final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final String fileName = 'Struk_${invoiceNumber}_$timestamp';

    await Printing.layoutPdf(
      name: fileName,
      onLayout: (PdfPageFormat format) async => pdf.save(),
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text('${item['product']['name']}\n${item['quantity']} x ${_formatter.format(double.parse(item['unitPrice'].toString()))}', style: receiptTextStyle)),
                        Text(_formatter.format(double.parse(item['subtotal'].toString())), style: receiptTextStyle),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
                _buildDashedLine(),
                const SizedBox(height: 16),
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
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
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
