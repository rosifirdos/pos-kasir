import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

final _formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class RawMaterialScreen extends StatefulWidget {
  const RawMaterialScreen({Key? key}) : super(key: key);

  @override
  _RawMaterialScreenState createState() => _RawMaterialScreenState();
}

class _RawMaterialScreenState extends State<RawMaterialScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _materials = [];
  List<dynamic> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final materials = await _apiService.getRawMaterials();
      final units = await _apiService.getUnits();
      setState(() {
        _materials = materials;
        _units = units;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForm([Map<String, dynamic>? material]) {
    if (_units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan tambahkan Satuan terlebih dahulu')));
      return;
    }

    final isEdit = material != null;
    final nameCtrl = TextEditingController(text: material?['name'] ?? '');
    final stockCtrl = TextEditingController(text: material?['stockQuantity']?.toString() ?? '0');
    final minStockCtrl = TextEditingController(text: material?['minimumStock']?.toString() ?? '0');
    final costCtrl = TextEditingController(text: material?['costPerUnit']?.toString() ?? '0');
    int selectedUnitId = isEdit ? material['unitId'] : _units.first['id'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Bahan Baku' : 'Tambah Bahan Baku'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Bahan')),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedUnitId,
                    items: _units.map((u) => DropdownMenuItem<int>(value: u['id'], child: Text('${u['name']} (${u['abbreviation']})'))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedUnitId = val);
                    },
                    decoration: const InputDecoration(labelText: 'Satuan'),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stok Saat Ini'), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  TextField(controller: minStockCtrl, decoration: const InputDecoration(labelText: 'Batas Minimum Stok'), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Harga Beli (HPP per satuan)', prefixText: 'Rp '), keyboardType: TextInputType.number),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  Navigator.pop(ctx);
                  final data = {
                    'name': nameCtrl.text,
                    'unitId': selectedUnitId,
                    'stockQuantity': double.tryParse(stockCtrl.text) ?? 0,
                    'minimumStock': double.tryParse(minStockCtrl.text) ?? 0,
                    'costPerUnit': double.tryParse(costCtrl.text) ?? 0,
                  };
                  try {
                    if (isEdit) {
                      await _apiService.updateRawMaterial(material['id'], data);
                    } else {
                      await _apiService.createRawMaterial(data);
                    }
                    _fetchData();
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan bahan baku')));
                  }
                },
                child: const Text('Simpan'),
              )
            ],
          );
        }
      )
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Bahan Baku'),
        content: const Text('Yakin ingin menghapus bahan baku ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _apiService.deleteRawMaterial(id);
                _fetchData();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus bahan baku')));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Bahan Baku')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _materials.length,
            itemBuilder: (context, index) {
              final mat = _materials[index];
              final stock = double.tryParse(mat['stockQuantity'].toString()) ?? 0;
              final minStock = double.tryParse(mat['minimumStock'].toString()) ?? 0;
              final isLow = stock <= minStock;
              final unitAbbr = mat['unit']['abbreviation'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Row(
                    children: [
                      Text(mat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (isLow) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                          child: const Text('LOW', style: TextStyle(color: Colors.white, fontSize: 10)),
                        )
                      ]
                    ],
                  ),
                  subtitle: Text('Stok: $stock $unitAbbr (Min: $minStock $unitAbbr)\nHPP: ${_formatter.format(double.parse(mat['costPerUnit'].toString()))}/$unitAbbr'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showForm(mat)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(mat['id'])),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
