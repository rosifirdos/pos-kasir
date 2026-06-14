import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import 'package:intl/intl.dart';

final _formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class RecipeBuilderScreen extends StatefulWidget {
  final Product product;

  const RecipeBuilderScreen({Key? key, required this.product}) : super(key: key);

  @override
  _RecipeBuilderScreenState createState() => _RecipeBuilderScreenState();
}

class _RecipeBuilderScreenState extends State<RecipeBuilderScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _materials = [];
  List<Map<String, dynamic>> _recipeItems = [];
  bool _isLoading = true;
  double _totalHpp = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final materials = await _apiService.getRawMaterials();
      final recipes = await _apiService.getRecipesByProduct(widget.product.id);
      
      setState(() {
        _materials = materials;
        _recipeItems = recipes.map<Map<String, dynamic>>((r) => {
          'rawMaterialId': r['rawMaterialId'],
          'quantityNeeded': double.tryParse(r['quantityNeeded'].toString()) ?? 0.0,
          'material': r['rawMaterial']
        }).toList();
        _calculateHpp();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateHpp() {
    double total = 0;
    for (var item in _recipeItems) {
      final qty = item['quantityNeeded'] as double;
      final cost = double.tryParse(item['material']['costPerUnit'].toString()) ?? 0.0;
      total += qty * cost;
    }
    setState(() {
      _totalHpp = total;
    });
  }

  void _addMaterialRow() {
    if (_materials.isEmpty) return;
    setState(() {
      _recipeItems.add({
        'rawMaterialId': _materials.first['id'],
        'quantityNeeded': 0.0,
        'material': _materials.first
      });
      _calculateHpp();
    });
  }

  void _removeMaterialRow(int index) {
    setState(() {
      _recipeItems.removeAt(index);
      _calculateHpp();
    });
  }

  Future<void> _saveRecipe() async {
    setState(() => _isLoading = true);
    try {
      final payload = _recipeItems.map((item) => {
        'rawMaterialId': item['rawMaterialId'],
        'quantityNeeded': item['quantityNeeded'],
      }).toList();

      final success = await _apiService.saveRecipes(widget.product.id, payload);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resep berhasil disimpan!')));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan resep.')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Builder: ${widget.product.name}'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total HPP (Harga Pokok Penjualan):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(_formatter.format(_totalHpp), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _addMaterialRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Bahan Baku'),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _recipeItems.length,
                    itemBuilder: (context, index) {
                      final item = _recipeItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<int>(
                                  value: item['rawMaterialId'],
                                  items: _materials.map((m) => DropdownMenuItem<int>(
                                    value: m['id'], 
                                    child: Text('${m['name']} (${m['unit']['abbreviation']})')
                                  )).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        final mat = _materials.firstWhere((m) => m['id'] == val);
                                        _recipeItems[index]['rawMaterialId'] = val;
                                        _recipeItems[index]['material'] = mat;
                                        _calculateHpp();
                                      });
                                    }
                                  },
                                  decoration: const InputDecoration(labelText: 'Pilih Bahan Baku'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  initialValue: item['quantityNeeded'].toString(),
                                  decoration: InputDecoration(
                                    labelText: 'Takaran',
                                    suffixText: item['material']['unit']['abbreviation'],
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setState(() {
                                      _recipeItems[index]['quantityNeeded'] = double.tryParse(val) ?? 0.0;
                                      _calculateHpp();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeMaterialRow(index),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    onPressed: _saveRecipe,
                    child: const Text('Simpan Resep', style: TextStyle(fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
    );
  }
}
