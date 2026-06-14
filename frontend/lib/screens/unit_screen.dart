import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UnitScreen extends StatefulWidget {
  const UnitScreen({Key? key}) : super(key: key);

  @override
  _UnitScreenState createState() => _UnitScreenState();
}

class _UnitScreenState extends State<UnitScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  Future<void> _fetchUnits() async {
    setState(() => _isLoading = true);
    try {
      final units = await _apiService.getUnits();
      setState(() {
        _units = units;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat satuan: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUnitForm([Map<String, dynamic>? unit]) {
    final nameCtrl = TextEditingController(text: unit?['name'] ?? '');
    final abbrCtrl = TextEditingController(text: unit?['abbreviation'] ?? '');
    final isEdit = unit != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Satuan' : 'Tambah Satuan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Satuan (ex: Kilogram)')),
            const SizedBox(height: 16),
            TextField(controller: abbrCtrl, decoration: const InputDecoration(labelText: 'Singkatan (ex: kg)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || abbrCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                if (isEdit) {
                  await _apiService.updateUnit(unit['id'], {'name': nameCtrl.text, 'abbreviation': abbrCtrl.text});
                } else {
                  await _apiService.createUnit({'name': nameCtrl.text, 'abbreviation': abbrCtrl.text});
                }
                _fetchUnits();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan satuan')));
              }
            },
            child: const Text('Simpan'),
          )
        ],
      )
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Satuan'),
        content: const Text('Yakin ingin menghapus satuan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _apiService.deleteUnit(id);
                _fetchUnits();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus satuan')));
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
      appBar: AppBar(title: const Text('Kelola Satuan')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUnitForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _units.length,
            itemBuilder: (context, index) {
              final unit = _units[index];
              return ListTile(
                title: Text(unit['name']),
                subtitle: Text('Singkatan: ${unit['abbreviation']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showUnitForm(unit)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(unit['id'])),
                  ],
                ),
              );
            },
          ),
    );
  }
}
