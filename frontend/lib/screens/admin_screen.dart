import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'promo_admin_screen.dart';

final _formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _searchQuery = '';

  String _generateSku(String categoryName) {
    final cleanName = categoryName.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim().toUpperCase();
    if (cleanName.isEmpty) return 'PRD-${DateTime.now().millisecondsSinceEpoch}';
    final words = cleanName.split(RegExp(r'\s+'));
    String prefix;
    if (words.length > 1) {
      // e.g. "Makanan Ringan" -> "MR"
      prefix = words.map((w) => w.isNotEmpty ? w[0] : '').join();
    } else {
      // e.g. "Minuman" -> "MIN"
      prefix = cleanName.length >= 3 ? cleanName.substring(0, 3) : cleanName;
    }
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}';
  }

  void _showProductForm({Product? product}) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    if (provider.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tunggu kategori dimuat atau tambahkan kategori terlebih dahulu.')));
      return;
    }

    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: isEdit ? product.name : '');
    
    int selectedCategoryId = isEdit ? product.categoryId : provider.categories.first.id;
    final initialCategory = provider.categories.firstWhere((c) => c.id == selectedCategoryId);

    final skuCtrl = TextEditingController(
      text: isEdit ? product.sku : _generateSku(initialCategory.name),
    );
    final buyPriceCtrl = TextEditingController(text: isEdit ? product.buyPrice.toStringAsFixed(0) : '');
    final sellPriceCtrl = TextEditingController(text: isEdit ? product.sellPrice.toStringAsFixed(0) : '');
    final stockCtrl = TextEditingController(text: isEdit ? product.currentStock.toString() : '0');
    final imageCtrl = TextEditingController(text: isEdit ? product.imageUrl : '');
    
    String? selectedImagePath;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEdit ? 'Edit Produk' : 'Tambah Produk Baru',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        items: provider.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedCategoryId = val;
                              if (!isEdit) {
                                final selectedCat = provider.categories.firstWhere((c) => c.id == val);
                                skuCtrl.text = _generateSku(selectedCat.name);
                              }
                            });
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Kategori'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: skuCtrl,
                              decoration: InputDecoration(
                                labelText: 'SKU (Kode)',
                                suffixIcon: !isEdit
                                    ? IconButton(
                                        icon: const Icon(Icons.autorenew_rounded),
                                        tooltip: 'Acak SKU',
                                        onPressed: () {
                                          setDialogState(() {
                                            final selectedCat = provider.categories.firstWhere((c) => c.id == selectedCategoryId);
                                            skuCtrl.text = _generateSku(selectedCat.name);
                                          });
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Produk'))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: imageCtrl, 
                              decoration: InputDecoration(
                                labelText: 'Pilih Gambar (File)',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.upload_file),
                                  onPressed: () async {
                                    try {
                                      final picker = ImagePicker();
                                      final pickedFile = await picker.pickImage(
                                        source: ImageSource.gallery,
                                        maxWidth: 800,
                                        maxHeight: 800,
                                        imageQuality: 85,
                                      );
                                      if (pickedFile != null) {
                                        setDialogState(() {
                                          selectedImagePath = pickedFile.path;
                                          imageCtrl.text = pickedFile.name;
                                        });
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuka file: $e')));
                                      }
                                    }
                                  },
                                ),
                              ),
                              readOnly: true,
                            ),
                          ),
                        ],
                      ),
                      if (selectedImagePath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(selectedImagePath!), height: 120, fit: BoxFit.cover),
                          ),
                        )
                      else if (isEdit && product.imageUrl != null && product.imageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.imageUrl!.startsWith('http') ? product.imageUrl! : '${ApiService.siteUrl}${product.imageUrl}',
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: buyPriceCtrl, decoration: const InputDecoration(labelText: 'Harga Beli (Rp)', prefixText: 'Rp '), keyboardType: TextInputType.number)),
                          const SizedBox(width: 16),
                          Expanded(child: TextField(controller: sellPriceCtrl, decoration: const InputDecoration(labelText: 'Harga Jual (Rp)', prefixText: 'Rp '), keyboardType: TextInputType.number)),
                        ],
                      ),
                      if (!isEdit) ...[
                        const SizedBox(height: 16),
                        TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stok Awal'), keyboardType: TextInputType.number),
                      ],
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx), 
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
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
                            child: const Text('Simpan Produk'),
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

  void _showCategoryForm() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tambah Kategori Baru'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Nama Kategori'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                
                Navigator.pop(ctx);
                final success = await Provider.of<ProductProvider>(context, listen: false).createCategory(name);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Kategori berhasil ditambahkan!' : 'Gagal menambahkan kategori!')));
                }
              },
              child: const Text('Simpan'),
            )
          ],
        );
      }
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}"? Data yang dihapus tidak dapat dikembalikan.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await Provider.of<ProductProvider>(context, listen: false).deleteProduct(product.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Produk dihapus!' : 'Gagal menghapus produk!')));
              }
            },
            child: const Text('Ya, Hapus'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Jumlah Ditambahkan'), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Catatan')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () async {
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                if (qty <= 0) return;
                
                Navigator.pop(ctx);
                final success = await Provider.of<ProductProvider>(context, listen: false).adjustStock(product.id, 'IN', qty, noteCtrl.text);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Restok berhasil!' : 'Restok gagal!')));
                }
              },
              child: const Text('Proses Restok'),
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Manajemen Inventaris'),
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
                  hintText: 'Cari SKU atau Nama...',
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
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.indigo,
              side: const BorderSide(color: Colors.indigo),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            icon: const Icon(Icons.discount_outlined),
            label: const Text('Kelola Promo'),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PromoAdminScreen()));
            },
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.indigo,
              side: const BorderSide(color: Colors.indigo),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Kategori'),
            onPressed: () => _showCategoryForm(),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Produk'),
            onPressed: () => _showProductForm(),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredProducts = provider.products.where((p) => 
            p.name.toLowerCase().contains(_searchQuery) || 
            p.sku.toLowerCase().contains(_searchQuery)
          ).toList();

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
                        headingRowColor: MaterialStateProperty.resolveWith((states) => Colors.grey.shade50),
                        columns: const [
                          DataColumn(label: Text('Produk', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Harga Beli', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Harga Jual', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Stok', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filteredProducts.map((product) {
                          final isLowStock = product.currentStock <= 5;
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                        image: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                                            ? DecorationImage(
                                                image: NetworkImage(product.imageUrl!.startsWith('http') ? product.imageUrl! : '${ApiService.siteUrl}${product.imageUrl}'),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: (product.imageUrl == null || product.imageUrl!.isEmpty) 
                                          ? Icon(Icons.image, color: Colors.grey.shade400, size: 20) : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text(product.sku, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(product.category?.name ?? '-', style: TextStyle(color: Colors.indigo.shade900, fontSize: 12)),
                                )
                              ),
                              DataCell(Text(_formatter.format(product.buyPrice))),
                              DataCell(Text(_formatter.format(product.sellPrice), style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(
                                Row(
                                  children: [
                                    if (isLowStock) const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                                    if (isLowStock) const SizedBox(width: 4),
                                    Text(
                                      product.currentStock.toString(),
                                      style: TextStyle(
                                        color: isLowStock ? Colors.orange.shade800 : Colors.black87,
                                        fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                )
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add_shopping_cart, color: Colors.teal),
                                      tooltip: 'Restok',
                                      onPressed: () => _showRestockForm(product),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                      tooltip: 'Edit Produk',
                                      onPressed: () => _showProductForm(product: product),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      tooltip: 'Hapus Produk',
                                      onPressed: () => _confirmDelete(product),
                                    ),
                                  ],
                                )
                              ),
                            ]
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
