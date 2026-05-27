import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import '../models/category.dart';
import '../models/product.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, or actual IP for physical devices.
  static const String baseUrl = 'http://localhost:3000/api';
  static const String siteUrl = 'http://localhost:3000';

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

  Future<dynamic> createTransaction(String paymentMethod, List<Map<String, dynamic>> items) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'paymentMethod': paymentMethod,
        'items': items,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<bool> createProduct(Map<String, dynamic> data, {String? imagePath}) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/products'));
    
    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    if (imagePath != null && imagePath.isNotEmpty) {
      String ext = p.extension(imagePath).replaceFirst('.', '').toLowerCase();
      request.files.add(await http.MultipartFile.fromPath(
        'image', 
        imagePath,
        contentType: MediaType('image', ext.isEmpty ? 'jpeg' : (ext == 'jpg' ? 'jpeg' : ext)),
      ));
    }

    final response = await request.send();
    return response.statusCode == 201;
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data, {String? imagePath}) async {
    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/products/$id'));
    
    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    if (imagePath != null && imagePath.isNotEmpty) {
      String ext = p.extension(imagePath).replaceFirst('.', '').toLowerCase();
      request.files.add(await http.MultipartFile.fromPath(
        'image', 
        imagePath,
        contentType: MediaType('image', ext.isEmpty ? 'jpeg' : (ext == 'jpg' ? 'jpeg' : ext)),
      ));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  Future<bool> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
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

  Future<Map<String, dynamic>> getDailySummary() async {
    final response = await http.get(Uri.parse('$baseUrl/reports/daily-summary'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load daily summary');
    }
  }

  Future<List<dynamic>> getTopProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/reports/top-products'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load top products');
    }
  }
}
