import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
                    pw.Text('Jl. Digitalisasi UMKM No. 1'),
                    pw.Text('Telp: 0812-3456-7890'),
                    pw.SizedBox(height: 10),
                    pw.Text('STRUK PEMBAYARAN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Divider(),
                  ],
                ),
              ),
              pw.Text('No. Invoice: ${transaction['invoiceNumber']}'),
              pw.Text('Tanggal: $date'),
              pw.Text('Metode: ${transaction['paymentMethod']}'),
              pw.Divider(),
              pw.SizedBox(height: 5),
              ... (transaction['details'] as List).map((item) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text('${item['product']['name']} x${item['quantity']}')),
                    pw.Text('Rp ${item['subtotal']}'),
                  ],
                );
              }).toList(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.Text('Rp ${transaction['totalAmount']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Terima Kasih atas Kunjungan Anda!')),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final details = transaction['details'] as List;
    final date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(transaction['createdAt']));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Column(
              children: [
                Text('GARIS AWAN POS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Text('Jl. Digitalisasi UMKM No. 1'),
                Divider(),
              ],
            ),
          ),
          Text('Invoice: ${transaction['invoiceNumber']}'),
          Text('Tanggal: $date'),
          Text('Pembayaran: ${transaction['paymentMethod']}'),
          const Divider(),
          const SizedBox(height: 8),
          ...details.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${item['product']['name']} x${item['quantity']}')),
                  Text('Rp ${double.parse(item['subtotal'].toString()).toStringAsFixed(0)}'),
                ],
              ),
            );
          }).toList(),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Rp ${double.parse(transaction['totalAmount'].toString()).toStringAsFixed(0)}', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _printReceipt,
                  icon: const Icon(Icons.print),
                  label: const Text('Cetak'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
