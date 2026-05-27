import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

class CartProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.subtotal;
    });
    return total;
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
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.remove(productId);
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
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  Future<bool> checkout(String paymentMethod) async {
    if (_items.isEmpty) return false;

    try {
      final orderItems = _items.values.map((item) => {
        'productId': item.product.id,
        'quantity': item.quantity,
        'unitPrice': item.product.sellPrice,
      }).toList();

      final success = await _apiService.createTransaction(paymentMethod, orderItems);
      if (success) {
        clearCart();
        return true;
      }
      return false;
    } catch (e) {
      print('Checkout error: $e');
      return false;
    }
  }
}
