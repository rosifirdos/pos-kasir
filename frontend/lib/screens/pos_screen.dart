import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';
import 'admin_screen.dart';
import 'dashboard_screen.dart';
import 'receipt_dialog.dart';
import 'history_screen.dart';
import 'shift_dialog.dart';
import 'employee_screen.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

final _formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class PosScreen extends StatefulWidget {
  const PosScreen({Key? key}) : super(key: key);

  @override
  _PosScreenState createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  String _searchQuery = '';
  int? _selectedCategoryId;

  bool _hasActiveShift = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShift();
      Provider.of<ProductProvider>(context, listen: false).fetchData();
      Provider.of<CartProvider>(context, listen: false).fetchActivePromos();
    });
  }

  Future<void> _checkShift() async {
    final api = ApiService();
    final shift = await api.getActiveShift();
    if (shift == null && mounted) {
      ShiftDialog.showOpenShift(context, () {
        setState(() => _hasActiveShift = true);
      });
    } else {
      setState(() => _hasActiveShift = true);
    }
  }

  void _processCheckout(BuildContext context, String paymentMethod) async {
    final transaction = await Provider.of<CartProvider>(context, listen: false).checkout(paymentMethod);
    if (transaction != null) {
      Provider.of<ProductProvider>(context, listen: false).fetchData();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Transaksi Berhasil!'),
          content: ReceiptWidget(transaction: transaction),
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi Gagal!')));
    }
  }

  void _showCheckoutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Pilih Metode Pembayaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.money),
              label: const Text('CASH'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _processCheckout(context, 'CASH');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.credit_card),
              label: const Text('DEBIT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade100,
                foregroundColor: Colors.indigo.shade900,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _processCheckout(context, 'DEBIT');
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('QRIS (CASHLESS)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _showQrisDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showQrisDialog(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final double amount = cartProvider.totalAmount;
    final String formattedAmount = _formatter.format(amount);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Container(
            width: 380,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/qris_logo.png',
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'QRIS',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quick Response Code Indonesian Standard',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24, thickness: 1),
                  const SizedBox(height: 8),
                  Text(
                    'Total Pembayaran',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedAmount,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                      ),
                      child: QrImageView(
                        data: 'https://qris.id/demo/transaction?amount=${amount.toInt()}',
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tunjukkan QR Code di atas kepada pelanggan.\nPelanggan dapat melakukan scan menggunakan aplikasi Gopay, OVO, Dana, LinkAja, atau Mobile Banking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _processCheckout(context, 'QRIS');
                          },
                          child: const Text('Bayar Berhasil', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('POS Kasir Modern - ${auth.user?['username'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo.shade900,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Riwayat Aktifitas',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen()));
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.people_alt_rounded),
              tooltip: 'Manajemen Pegawai',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeeScreen()));
              },
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded),
              tooltip: 'Dashboard Bisnis',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
              },
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              tooltip: 'Manajemen Toko',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen()));
              },
            ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'close_shift') {
                ShiftDialog.showCloseShift(context, () {
                  setState(() => _hasActiveShift = false);
                  auth.logout();
                });
              } else if (val == 'logout') {
                auth.logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'close_shift', child: Text('Tutup Shift & Keluar')),
              const PopupMenuItem(value: 'logout', child: Text('Keluar (Tanpa Tutup Shift)')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: !_hasActiveShift 
          ? const Center(child: CircularProgressIndicator()) 
          : Row(
        children: [
          // Kiri: Katalog
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Search & Filter
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari produk...',
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<ProductProvider>(
                        builder: (context, provider, child) {
                          if (provider.categories.isEmpty) return const SizedBox();
                          return SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: const Text('Semua'),
                                    selected: _selectedCategoryId == null,
                                    onSelected: (selected) {
                                      setState(() => _selectedCategoryId = null);
                                    },
                                  ),
                                ),
                                ...provider.categories.map((cat) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(cat.name),
                                      selected: _selectedCategoryId == cat.id,
                                      onSelected: (selected) {
                                        setState(() => _selectedCategoryId = selected ? cat.id : null);
                                      },
                                    ),
                                  );
                                }).toList()
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Grid Produk
                Expanded(
                  child: Consumer<ProductProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      List<Product> filtered = provider.products.where((p) {
                        final matchSearch = p.name.toLowerCase().contains(_searchQuery);
                        final matchCat = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
                        return matchSearch && matchCat;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text('Produk tidak ditemukan.'));
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(24.0),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 20.0,
                          mainAxisSpacing: 20.0,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return ProductCard(product: filtered[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Kanan: Keranjang
          Container(
            width: 400,
            color: Colors.white,
            child: Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      color: Colors.indigo.shade50,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Keranjang',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.indigo,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${cartProvider.itemCount} Item',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: cartProvider.items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text('Keranjang kosong', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: cartProvider.items.length,
                              separatorBuilder: (c, i) => const Divider(),
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
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (cartProvider.totalDiscountAmount > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Subtotal', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                                Text(_formatter.format(cartProvider.originalTotalAmount), style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text('Diskon', style: TextStyle(fontSize: 14, color: Colors.green.shade700)),
                                    if (cartProvider.appliedPromoName != null) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.green.shade200),
                                        ),
                                        child: Text(
                                          cartProvider.appliedPromoName!,
                                          style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text('-${_formatter.format(cartProvider.totalDiscountAmount)}', style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 24),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Tagihan', style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                              Text(_formatter.format(cartProvider.totalAmount), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: cartProvider.items.isEmpty ? null : () => _showCheckoutDialog(context),
                            child: const Text('CHECKOUT', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    )
                  ],
                );
              },
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
    final cartProvider = Provider.of<CartProvider>(context);
    final discount = cartProvider.getItemDiscount(widget.cartItem.product.id);
    final hasDiscount = discount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.cartItem.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                if (hasDiscount) ...[
                  Row(
                    children: [
                      Text(
                        _formatter.format(widget.cartItem.product.sellPrice),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatter.format(widget.cartItem.product.sellPrice - (discount / widget.cartItem.quantity)),
                        style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Diskon: -${_formatter.format(discount)}',
                    style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ] else ...[
                  Text(_formatter.format(widget.cartItem.product.sellPrice), style: TextStyle(color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                onPressed: () => cartProvider.decreaseQuantity(widget.itemKey),
              ),
              SizedBox(
                width: 40,
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
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
                icon: const Icon(Icons.add_circle, color: Colors.indigo),
                onPressed: () => cartProvider.addItem(widget.cartItem.product),
              ),
            ],
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Colors.grey.shade100,
                  child: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                      ? Image.network(
                          product.imageUrl!.startsWith('http') ? product.imageUrl! : '${ApiService.siteUrl}${product.imageUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 40, color: Colors.grey.shade400),
                        )
                      : Icon(Icons.image, size: 40, color: Colors.grey.shade400),
                ),
                if (product.currentStock <= 5)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.currentStock == 0 ? Colors.grey.shade800 : Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.currentStock == 0 ? 'HABIS' : 'Sisa ${product.currentStock}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatter.format(product.sellPrice),
                            style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stok: ${product.currentStock}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: product.currentStock > 0 ? Colors.indigo : Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.all(8),
                        ),
                        onPressed: product.currentStock > 0
                            ? () => Provider.of<CartProvider>(context, listen: false).addItem(product)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
