import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';

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
    final imageCtrl = TextEditingController(text: isEdit ? product.imageUrl : '');
    
    String? selectedImagePath;
    int selectedCategoryId = isEdit ? product.categoryId : provider.categories.first.id;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'URL Gambar'))),
                        IconButton(
                          icon: const Icon(Icons.image),
                          onPressed: () async {
                            try {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1024,
                                maxHeight: 1024,
                                imageQuality: 85,
                              );
                              if (pickedFile != null) {
                                setDialogState(() {
                                  selectedImagePath = pickedFile.path;
                                  imageCtrl.text = pickedFile.name;
                                });
                              }
                            } catch (e) {
                              print('Error picking image: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal membuka galeri: $e'))
                                );
                              }
                            }
                          },
                        )
                      ],
                    ),
                    if (selectedImagePath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Image.file(File(selectedImagePath!), height: 100),
                      )
                    else if (isEdit && product.imageUrl != null && product.imageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Image.network(
                          product.imageUrl!.startsWith('http') 
                            ? product.imageUrl! 
                            : '${ApiService.siteUrl}${product.imageUrl}',
                          height: 100,
                        ),
                      ),
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
                      'imageUrl': selectedImagePath != null ? '' : imageCtrl.text,
                      'buyPrice': double.tryParse(buyPriceCtrl.text) ?? 0,
                      'sellPrice': double.tryParse(sellPriceCtrl.text) ?? 0,
                      'currentStock': int.tryParse(stockCtrl.text) ?? 0,
                    };
                    
                    Navigator.pop(ctx);
                    bool success = false;
                    if (isEdit) {
                      success = await provider.updateProduct(product.id, data, imagePath: selectedImagePath);
                    } else {
                      success = await provider.createProduct(data, imagePath: selectedImagePath);
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
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await Provider.of<ProductProvider>(context, listen: false).deleteProduct(product.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Produk dihapus!' : 'Gagal menghapus produk!')));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          )
        ],
      )
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
                leading: SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: isLowStock ? Colors.red : Colors.blue,
                        backgroundImage: (product.imageUrl != null && product.imageUrl!.isNotEmpty) 
                          ? NetworkImage(product.imageUrl!.startsWith('http') ? product.imageUrl! : '${ApiService.siteUrl}${product.imageUrl}') 
                          : null,
                        child: (product.imageUrl == null || product.imageUrl!.isEmpty)
                          ? Text(product.currentStock.toString(), style: const TextStyle(color: Colors.white, fontSize: 14))
                          : null,
                      ),
                      if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isLowStock ? Colors.red : Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              product.currentStock.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                    ],
                  ),
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
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Hapus Produk',
                      onPressed: () => _confirmDelete(product),
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
