import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/product.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, or actual IP for physical devices.
  static const String baseUrl = 'http://localhost:3000/api';

  Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));
    if (response.statusCode == 200) {
      Iterable json = jsonDecode(response.body);
      return json.map((category) => Category.fromJson(category)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));
    if (response.statusCode == 200) {
      Iterable json = jsonDecode(response.body);
      return json.map((product) => Product.fromJson(product)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<bool> createTransaction(String paymentMethod, List<Map<String, dynamic>> items) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'paymentMethod': paymentMethod,
        'items': items,
      }),
    );
    return response.statusCode == 201;
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  Future<bool> adjustStock(int productId, String type, int quantity, String note) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stocks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'productId': productId,
        'adjustmentType': type,
        'quantity': quantity,
        'note': note,
      }),
    );
    return response.statusCode == 201;
  }
}
