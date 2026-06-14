import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

final _formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class PromoAdminScreen extends StatefulWidget {
  const PromoAdminScreen({super.key});

  @override
  State<PromoAdminScreen> createState() => _PromoAdminScreenState();
}

class _PromoAdminScreenState extends State<PromoAdminScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _promos = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPromos();
  }

  Future<void> _fetchPromos() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getPromos();
      if (!mounted) return;
      setState(() {
        _promos = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat promo: $e')));
    }
  }

  void _showPromoForm({Map<String, dynamic>? promo}) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final isEdit = promo != null;

    final nameCtrl = TextEditingController(text: isEdit ? promo['name'] : '');
    final descCtrl = TextEditingController(text: isEdit ? promo['description'] ?? '' : '');
    final valueCtrl = TextEditingController(text: isEdit ? promo['value'].toString() : '');
    final maxDiscCtrl = TextEditingController(text: isEdit ? (promo['maxDiscount']?.toString() ?? '') : '');
    final minPurchCtrl = TextEditingController(text: isEdit ? (promo['minPurchase']?.toString() ?? '') : '');
    final quotaCtrl = TextEditingController(text: isEdit ? (promo['quota']?.toString() ?? '') : '');

    String selectedType = isEdit ? promo['type'] : 'PERCENTAGE';
    bool isActive = isEdit ? promo['isActive'] : true;
    bool isStackable = isEdit ? promo['isStackable'] : false;

    DateTime? startDate = isEdit && promo['startDate'] != null ? DateTime.parse(promo['startDate']) : null;
    DateTime? endDate = isEdit && promo['endDate'] != null ? DateTime.parse(promo['endDate']) : null;
    TimeOfDay? startTime = isEdit && promo['startTime'] != null ? TimeOfDay(
      hour: int.parse(promo['startTime'].split(':')[0]),
      minute: int.parse(promo['startTime'].split(':')[1]),
    ) : null;
    TimeOfDay? endTime = isEdit && promo['endTime'] != null ? TimeOfDay(
      hour: int.parse(promo['endTime'].split(':')[0]),
      minute: int.parse(promo['endTime'].split(':')[1]),
    ) : null;

    // Get selected product IDs
    List<int> selectedProductIds = [];
    if (isEdit && promo['promoItems'] != null) {
      for (var pi in promo['promoItems']) {
        selectedProductIds.add(pi['productId']);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 600,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEdit ? 'Edit Promo' : 'Tambah Promo Baru',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Promo')),
                      const SizedBox(height: 12),
                      TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi')),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedType,
                              decoration: const InputDecoration(labelText: 'Tipe Promo'),
                              items: const [
                                DropdownMenuItem(value: 'PERCENTAGE', child: Text('Persentase Diskon')),
                                DropdownMenuItem(value: 'FIXED_AMOUNT', child: Text('Nominal Diskon')),
                                DropdownMenuItem(value: 'BOGO', child: Text('Buy 1 Get 1 (BOGO)')),
                                DropdownMenuItem(value: 'HAPPY_HOUR', child: Text('Happy Hour')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    selectedType = val;
                                    if (val == 'BOGO') {
                                      valueCtrl.text = '1'; // Default: Buy 1 Get 1
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: valueCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: selectedType == 'BOGO' 
                                    ? 'Kuantitas Pembelian (X)' 
                                    : (selectedType == 'PERCENTAGE' || selectedType == 'HAPPY_HOUR' ? 'Persentase (%)' : 'Nominal Diskon (Rp)'),
                                suffixText: (selectedType == 'PERCENTAGE' || selectedType == 'HAPPY_HOUR') ? '%' : null,
                              ),
                              enabled: selectedType != 'BOGO', // BOGO automatically set buy 1 get 1 (value=1)
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: minPurchCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Minimal Belanja (Rp)', prefixText: 'Rp '),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: maxDiscCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Maksimal Diskon (Rp)', prefixText: 'Rp '),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('Tanggal Mulai', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              subtitle: Text(startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : 'Pilih Tanggal'),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setDialogState(() => startDate = picked);
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: const Text('Tanggal Selesai', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              subtitle: Text(endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : 'Pilih Tanggal'),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setDialogState(() => endDate = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (selectedType == 'HAPPY_HOUR') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: const Text('Jam Mulai', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                subtitle: Text(startTime != null ? startTime!.format(context) : 'Pilih Jam'),
                                trailing: const Icon(Icons.access_time),
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: startTime ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => startTime = picked);
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                title: const Text('Jam Selesai', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                subtitle: Text(endTime != null ? endTime!.format(context) : 'Pilih Jam'),
                                trailing: const Icon(Icons.access_time),
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: endTime ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => endTime = picked);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: quotaCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Kuota Transaksi (Kosongkan jika tidak terbatas)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('Promo Aktif'),
                              value: isActive,
                              onChanged: (val) => setDialogState(() => isActive = val),
                            ),
                          ),
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('Bisa Ditumpuk'),
                              value: isStackable,
                              onChanged: (val) => setDialogState(() => isStackable = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('Pilih Produk (Terapkan untuk produk tertentu. Kosongkan jika berlaku global)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          itemCount: productProvider.products.length,
                          itemBuilder: (ctx, index) {
                            final p = productProvider.products[index];
                            final isSelected = selectedProductIds.contains(p.id);
                            return CheckboxListTile(
                              title: Text(p.name),
                              subtitle: Text(p.sku),
                              value: isSelected,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    selectedProductIds.add(p.id);
                                  } else {
                                    selectedProductIds.remove(p.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                            onPressed: () async {
                              final data = {
                                'name': nameCtrl.text.trim(),
                                'description': descCtrl.text.trim(),
                                'type': selectedType,
                                'value': double.tryParse(valueCtrl.text) ?? 0,
                                'maxDiscount': double.tryParse(maxDiscCtrl.text),
                                'minPurchase': double.tryParse(minPurchCtrl.text),
                                'startDate': startDate?.toIso8601String(),
                                'endDate': endDate?.toIso8601String(),
                                'startTime': startTime != null ? '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}' : null,
                                'endTime': endTime != null ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}' : null,
                                'quota': int.tryParse(quotaCtrl.text),
                                'isActive': isActive,
                                'isStackable': isStackable,
                                'productIds': selectedProductIds,
                              };

                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(ctx);

                              final success = isEdit 
                                  ? await _apiService.updatePromo(promo['id'], data)
                                  : await _apiService.createPromo(data);

                              navigator.pop();
                              
                              messenger.showSnackBar(SnackBar(content: Text(success ? 'Promo berhasil disimpan!' : 'Gagal menyimpan promo!')));
                              _fetchPromos();
                            },
                            child: const Text('Simpan Promo'),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  void _confirmDelete(Map<String, dynamic> promo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Promo'),
        content: Text('Apakah Anda yakin ingin menghapus promo "${promo['name']}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);

              final success = await _apiService.deletePromo(promo['id']);
              
              navigator.pop();
              messenger.showSnackBar(SnackBar(content: Text(success ? 'Promo berhasil dihapus!' : 'Gagal menghapus promo!')));
              _fetchPromos();
            },
            child: const Text('Ya, Hapus'),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Manajemen Promosi & Diskon'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo.shade900,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: 250,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari Promo...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Promo'),
            onPressed: () => _showPromoForm(),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                final filtered = _promos.where((p) => p['name'].toString().toLowerCase().contains(_searchQuery)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.discount_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Belum ada promo terdaftar.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.resolveWith((states) => Colors.grey.shade50),
                              columns: const [
                                DataColumn(label: Text('Nama Promo', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Tipe', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Nilai', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Kriteria Waktu / Batas', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Kuota / Dipakai', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filtered.map<DataRow>((promo) {
                                final typeStr = promo['type'] == 'PERCENTAGE' 
                                    ? 'Persentase' 
                                    : (promo['type'] == 'FIXED_AMOUNT' 
                                        ? 'Nominal Potongan' 
                                        : (promo['type'] == 'BOGO' ? 'Buy 1 Get 1' : 'Happy Hour'));

                                String valueStr = '';
                                if (promo['type'] == 'PERCENTAGE' || promo['type'] == 'HAPPY_HOUR') {
                                  valueStr = '${double.parse(promo['value'].toString()).toStringAsFixed(0)}%';
                                } else if (promo['type'] == 'BOGO') {
                                  valueStr = 'Buy ${double.parse(promo['value'].toString()).toStringAsFixed(0)} Free 1';
                                } else {
                                  valueStr = _formatter.format(double.parse(promo['value'].toString()));
                                }

                                final startDateStr = promo['startDate'] != null 
                                    ? DateFormat('dd MMM yy').format(DateTime.parse(promo['startDate'])) : '';
                                final endDateStr = promo['endDate'] != null 
                                    ? DateFormat('dd MMM yy').format(DateTime.parse(promo['endDate'])) : '';
                                final dateRange = startDateStr.isNotEmpty ? '$startDateStr - $endDateStr' : 'Selamanya';

                                final timeRange = promo['type'] == 'HAPPY_HOUR' 
                                    ? '\n⏱ ${promo['startTime']} - ${promo['endTime']}' : '';

                                final minPurch = promo['minPurchase'] != null 
                                    ? '\nMin: ${_formatter.format(double.parse(promo['minPurchase'].toString()))}' : '';

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(promo['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                          if (promo['description'] != null && promo['description'].toString().isNotEmpty)
                                            Text(promo['description'], style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(typeStr)),
                                    DataCell(Text(valueStr, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text('$dateRange$timeRange$minPurch', style: const TextStyle(fontSize: 12))),
                                    DataCell(Text('${promo['quota'] ?? 'Unlimited'} / ${promo['usedCount']}')),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: promo['isActive'] ? Colors.green.shade50 : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          promo['isActive'] ? 'AKTIF' : 'NONAKTIF',
                                          style: TextStyle(color: promo['isActive'] ? Colors.green.shade800 : Colors.red.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                            onPressed: () => _showPromoForm(promo: promo),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                            onPressed: () => _confirmDelete(promo),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
