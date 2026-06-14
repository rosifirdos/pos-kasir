import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

class CartProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Map<int, CartItem> _items = {};
  List<dynamic> _activePromos = [];

  double _totalDiscountAmount = 0.0;
  int? _appliedPromoId;
  String? _appliedPromoName;
  final Map<int, double> _itemDiscounts = {};
  final Map<int, int?> _itemPromoIds = {};

  Map<int, CartItem> get items => _items;

  int get itemCount => _items.length;

  List<dynamic> get activePromos => _activePromos;

  double get originalTotalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.product.sellPrice * cartItem.quantity;
    });
    return total;
  }

  double get totalDiscountAmount => _totalDiscountAmount;

  double get totalAmount => originalTotalAmount - _totalDiscountAmount;

  double getItemDiscount(int productId) => _itemDiscounts[productId] ?? 0.0;
  int? getItemPromoId(int productId) => _itemPromoIds[productId];
  int? get appliedPromoId => _appliedPromoId;
  String? get appliedPromoName => _appliedPromoName;

  Future<void> fetchActivePromos() async {
    try {
      _activePromos = await _apiService.getActivePromos();
      _calculatePromos();
      notifyListeners();
    } catch (e) {
      print('Failed to fetch active promos: $e');
    }
  }

  void _calculatePromos() {
    _itemDiscounts.clear();
    _itemPromoIds.clear();
    _appliedPromoId = null;
    _appliedPromoName = null;
    _totalDiscountAmount = 0.0;

    if (_items.isEmpty || _activePromos.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final currentTimeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    // Separate promos
    final itemLevelPromos = _activePromos.where((p) {
      final type = p['type'];
      final promoItems = p['promoItems'] as List? ?? [];
      return type == 'BOGO' || type == 'HAPPY_HOUR' || promoItems.isNotEmpty;
    }).toList();

    final transactionLevelPromos = _activePromos.where((p) {
      final type = p['type'];
      final promoItems = p['promoItems'] as List? ?? [];
      return (type == 'PERCENTAGE' || type == 'FIXED_AMOUNT') && promoItems.isEmpty;
    }).toList();

    // SCENARIO A: Item-level calculations
    double scenarioATotalDiscount = 0.0;
    final Map<int, double> scenarioAItemDiscounts = {};
    final Map<int, int?> scenarioAItemPromoIds = {};

    _items.forEach((productId, cartItem) {
      double bestDiscount = 0.0;
      int? bestPromoId;

      final eligiblePromos = itemLevelPromos.where((promo) {
        final promoItems = promo['promoItems'] as List? ?? [];
        final hasItem = promoItems.any((pi) => pi['productId'] == productId);
        final appliesToAll = promoItems.isEmpty;

        if (!hasItem && !appliesToAll) return false;

        if (promo['type'] == 'HAPPY_HOUR') {
          final startTime = promo['startTime'];
          final endTime = promo['endTime'];
          if (startTime != null && endTime != null) {
            return currentTimeStr.compareTo(startTime) >= 0 && currentTimeStr.compareTo(endTime) <= 0;
          }
        }
        return true;
      }).toList();

      for (final promo in eligiblePromos) {
        double discount = 0.0;
        final double val = double.tryParse(promo['value'].toString()) ?? 0.0;

        if (promo['type'] == 'BOGO') {
          final buyQty = val > 0 ? val.toInt() : 1;
          final freeQty = cartItem.quantity ~/ (buyQty + 1);
          discount = freeQty * cartItem.product.sellPrice;
        } else if (promo['type'] == 'PERCENTAGE' || promo['type'] == 'HAPPY_HOUR') {
          discount = cartItem.quantity * cartItem.product.sellPrice * (val / 100);
        } else if (promo['type'] == 'FIXED_AMOUNT') {
          discount = cartItem.quantity * val;
        }

        final maxDiscRaw = promo['maxDiscount'];
        if (maxDiscRaw != null) {
          final maxDisc = double.tryParse(maxDiscRaw.toString()) ?? 0.0;
          if (discount > maxDisc) {
            discount = maxDisc;
          }
        }

        if (discount > bestDiscount) {
          bestDiscount = discount;
          bestPromoId = promo['id'];
        }
      }

      scenarioAItemDiscounts[productId] = bestDiscount;
      scenarioAItemPromoIds[productId] = bestPromoId;
      scenarioATotalDiscount += bestDiscount;
    });

    // SCENARIO B: Transaction-level calculations
    double bestTxDiscount = 0.0;
    int? bestTxPromoId;
    String? bestTxPromoName;
    final originalTotal = originalTotalAmount;

    for (final promo in transactionLevelPromos) {
      final minPurchaseRaw = promo['minPurchase'];
      final minPurchase = minPurchaseRaw != null ? (double.tryParse(minPurchaseRaw.toString()) ?? 0.0) : 0.0;
      if (originalTotal < minPurchase) continue;

      double discount = 0.0;
      final double val = double.tryParse(promo['value'].toString()) ?? 0.0;

      if (promo['type'] == 'PERCENTAGE') {
        discount = originalTotal * (val / 100);
      } else if (promo['type'] == 'FIXED_AMOUNT') {
        discount = val;
      }

      final maxDiscRaw = promo['maxDiscount'];
      if (maxDiscRaw != null) {
        final maxDisc = double.tryParse(maxDiscRaw.toString()) ?? 0.0;
        if (discount > maxDisc) {
          discount = maxDisc;
        }
      }

      if (discount > bestTxDiscount) {
        bestTxDiscount = discount;
        bestTxPromoId = promo['id'];
        bestTxPromoName = promo['name'];
      }
    }

    // Compare Scenario A vs B
    if (scenarioATotalDiscount >= bestTxDiscount) {
      _totalDiscountAmount = scenarioATotalDiscount;
      _itemDiscounts.addAll(scenarioAItemDiscounts);
      _itemPromoIds.addAll(scenarioAItemPromoIds);
    } else {
      _totalDiscountAmount = bestTxDiscount;
      _appliedPromoId = bestTxPromoId;
      _appliedPromoName = bestTxPromoName;
    }
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      if (_items[product.id]!.quantity < product.currentStock) {
        _items.update(
          product.id,
          (existingCartItem) => CartItem(
            product: existingCartItem.product,
            quantity: existingCartItem.quantity + 1,
          ),
        );
      }
    } else {
      if (product.currentStock > 0) {
        _items.putIfAbsent(
          product.id,
          () => CartItem(product: product),
        );
      }
    }
    _calculatePromos();
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.remove(productId);
    _calculatePromos();
    notifyListeners();
  }

  void decreaseQuantity(int productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          product: existingCartItem.product,
          quantity: existingCartItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    _calculatePromos();
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    if (!_items.containsKey(productId)) return;

    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      int availableStock = _items[productId]!.product.currentStock;
      int finalQty = quantity > availableStock ? availableStock : quantity;

      _items.update(
        productId,
        (existingCartItem) => CartItem(
          product: existingCartItem.product,
          quantity: finalQty,
        ),
      );
    }
    _calculatePromos();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _calculatePromos();
    notifyListeners();
  }

  Future<dynamic> checkout(String paymentMethod) async {
    if (_items.isEmpty) return null;

    try {
      final orderItems = _items.values.map((item) => {
        'productId': item.product.id,
        'quantity': item.quantity,
        'unitPrice': item.product.sellPrice,
      }).toList();

      final transaction = await _apiService.createTransaction(paymentMethod, orderItems);
      if (transaction != null) {
        clearCart();
        return transaction;
      }
      return null;
    } catch (e) {
      print('Checkout error: $e');
      return null;
    }
  }
}
