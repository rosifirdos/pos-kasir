import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {

  void _showProductForm({Product? product}) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    if (provider.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tunggu kategori dimuat atau tambahkan kategori.')));
      return;
    }

    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: isEdit ? product.name : '');
    final skuCtrl = TextEditingController(text: isEdit ? product.sku : '');
    final buyPriceCtrl = TextEditingController(text: isEdit ? product.buyPrice.toStringAsFixed(0) : '');
    final sellPriceCtrl = TextEditingController(text: isEdit ? product.sellPrice.toStringAsFixed(0) : '');
    final stockCtrl = TextEditingController(text: isEdit ? product.currentStock.toString() : '0');
    
    int selectedCategoryId = isEdit ? product.categoryId : provider.categories.first.id;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  items: provider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (val) {
                    if (val != null) selectedCategoryId = val;
                  },
                  decoration: const InputDecoration(labelText: 'Kategori'),
                ),
                TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU')),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Produk')),
                TextField(controller: buyPriceCtrl, decoration: const InputDecoration(labelText: 'Harga Beli (Rp)'), keyboardType: TextInputType.number),
                TextField(controller: sellPriceCtrl, decoration: const InputDecoration(labelText: 'Harga Jual (Rp)'), keyboardType: TextInputType.number),
                if (!isEdit)
                  TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stok Awal'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'categoryId': selectedCategoryId,
                  'sku': skuCtrl.text,
                  'name': nameCtrl.text,
                  'buyPrice': double.tryParse(buyPriceCtrl.text) ?? 0,
                  'sellPrice': double.tryParse(sellPriceCtrl.text) ?? 0,
                  'currentStock': int.tryParse(stockCtrl.text) ?? 0,
                };
                
                Navigator.pop(ctx);
                bool success = false;
                if (isEdit) {
                  success = await provider.updateProduct(product.id, data);
                } else {
                  success = await provider.createProduct(data);
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Berhasil disimpan!' : 'Gagal menyimpan!')));
                }
              },
              child: const Text('Simpan'),
            )
          ],
        );
      }
    );
  }

  void _showRestockForm(Product product) {
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController(text: 'Restock manual');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Restok: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Jumlah Ditambahkan'), keyboardType: TextInputType.number),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Catatan')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                if (qty <= 0) return;
                
                Navigator.pop(ctx);
                final success = await Provider.of<ProductProvider>(context, listen: false).adjustStock(product.id, 'IN', qty, noteCtrl.text);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Restok berhasil!' : 'Restok gagal!')));
                }
              },
              child: const Text('Simpan'),
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Toko & Stok'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: provider.products.length,
            itemBuilder: (context, index) {
              final product = provider.products[index];
              final isLowStock = product.currentStock <= 5;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLowStock ? Colors.red : Colors.blue,
                  child: Text(product.currentStock.toString(), style: const TextStyle(color: Colors.white, fontSize: 14)),
                ),
                title: Text('${product.sku} - ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Kategori: ${product.category?.name ?? '-'} | Beli: Rp${product.buyPrice.toStringAsFixed(0)} | Jual: Rp${product.sellPrice.toStringAsFixed(0)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_box, color: Colors.green),
                      tooltip: 'Restok',
                      onPressed: () => _showRestockForm(product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit Produk',
                      onPressed: () => _showProductForm(product: product),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add),
        onPressed: () => _showProductForm(),
      ),
    );
  }
}
