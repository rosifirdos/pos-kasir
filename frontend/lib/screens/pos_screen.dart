import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import 'admin_screen.dart';
import 'dashboard_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({Key? key}) : super(key: key);

  @override
  _PosScreenState createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchData();
    });
  }

  void _showCheckoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Metode Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('CASH'),
              onTap: () async {
                Navigator.pop(ctx);
                bool success = await Provider.of<CartProvider>(context, listen: false).checkout('CASH');
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi Berhasil!')));
                  Provider.of<ProductProvider>(context, listen: false).fetchData(); // Refresh stock
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi Gagal!')));
                }
              },
            ),
            ListTile(
              title: const Text('DEBIT'),
              onTap: () async {
                Navigator.pop(ctx);
                bool success = await Provider.of<CartProvider>(context, listen: false).checkout('DEBIT');
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi Berhasil!')));
                  Provider.of<ProductProvider>(context, listen: false).fetchData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi Gagal!')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Garis Awan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Dashboard Bisnis',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Manajemen Toko',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminScreen()),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side: Catalog
          Expanded(
            flex: 2,
            child: Consumer<ProductProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.products.isEmpty) {
                  return const Center(child: Text('Tidak ada produk tersedia.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                  ),
                  itemCount: provider.products.length,
                  itemBuilder: (context, index) {
                    final product = provider.products[index];
                    return ProductCard(product: product);
                  },
                );
              },
            ),
          ),
          // Right side: Cart
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[100],
              child: Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        color: Colors.blue,
                        width: double.infinity,
                        child: Text(
                          'Keranjang (${cartProvider.itemCount})',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: cartProvider.items.isEmpty
                            ? const Center(child: Text('Keranjang kosong'))
                            : ListView.builder(
                                itemCount: cartProvider.items.length,
                                itemBuilder: (context, index) {
                                  final itemKey = cartProvider.items.keys.elementAt(index);
                                  final cartItem = cartProvider.items[itemKey]!;
                                  return CartItemWidget(
                                    key: ValueKey(itemKey),
                                    itemKey: itemKey,
                                    cartItem: cartItem,
                                  );
                                },
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.grey.shade300, offset: const Offset(0, -1), blurRadius: 4)
                          ]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text('Rp ${cartProvider.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: cartProvider.items.isEmpty ? null : () => _showCheckoutDialog(context),
                              child: const Text('BAYAR', style: TextStyle(fontSize: 18, color: Colors.white)),
                            )
                          ],
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CartItemWidget extends StatefulWidget {
  final int itemKey;
  final CartItem cartItem;

  const CartItemWidget({
    required Key key,
    required this.itemKey,
    required this.cartItem,
  }) : super(key: key);

  @override
  _CartItemWidgetState createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.cartItem.quantity.toString());
  }

  @override
  void didUpdateWidget(CartItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller if provider value changed from outside (e.g. +/- buttons)
    if (widget.cartItem.quantity.toString() != _controller.text) {
      _controller.text = widget.cartItem.quantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      title: Text(widget.cartItem.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text('Rp ${widget.cartItem.product.sellPrice.toStringAsFixed(0)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
            onPressed: () => cartProvider.decreaseQuantity(widget.itemKey),
          ),
          SizedBox(
            width: 50,
            child: TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                int? newQty = int.tryParse(val);
                if (newQty != null) {
                  cartProvider.updateQuantity(widget.itemKey, newQty);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
            onPressed: () => cartProvider.addItem(widget.cartItem.product),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Colors.blue[50],
                  child: const Icon(Icons.shopping_bag, size: 50, color: Colors.blue),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.currentStock <= 5 ? Colors.red : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Stok: ${product.currentStock}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Rp ${product.sellPrice.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: product.currentStock > 0
                        ? () {
                            Provider.of<CartProvider>(context, listen: false).addItem(product);
                          }
                        : null,
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('TAMBAH'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
