import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Category> _categories = [];
  List<Product> _products = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _apiService.getCategories();
      _products = await _apiService.getProducts();
    } catch (e) {
      print('Error fetching data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createProduct(Map<String, dynamic> data, {String? imagePath}) async {
    bool success = await _apiService.createProduct(data, imagePath: imagePath);
    if (success) await fetchData();
    return success;
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data, {String? imagePath}) async {
    bool success = await _apiService.updateProduct(id, data, imagePath: imagePath);
    if (success) await fetchData();
    return success;
  }

  Future<bool> deleteProduct(int id) async {
    bool success = await _apiService.deleteProduct(id);
    if (success) await fetchData();
    return success;
  }

  Future<bool> adjustStock(int productId, String type, int quantity, String note) async {
    bool success = await _apiService.adjustStock(productId, type, quantity, note);
    if (success) await fetchData();
    return success;
  }
}
