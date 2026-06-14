import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/product.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, or actual IP for physical devices.
  static const String baseUrl = 'http://localhost:3000/api';
  static const String siteUrl = 'http://localhost:3000';

  Future<Map<String, String>> _getHeaders({bool isJson = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final headers = <String, String>{};
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      Iterable json = jsonDecode(response.body);
      return json.map((category) => Category.fromJson(category)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<bool> createCategory(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: await _getHeaders(isJson: true),
      body: jsonEncode({'name': name}),
    );
    return response.statusCode == 201;
  }

  Future<List<Product>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: await _getHeaders(),
    );
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
      headers: await _getHeaders(isJson: true),
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
    request.headers.addAll(await _getHeaders());
    
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
    request.headers.addAll(await _getHeaders());
    
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
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  Future<bool> adjustStock(int productId, String type, int quantity, String note) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stocks'),
      headers: await _getHeaders(isJson: true),
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
    final response = await http.get(
      Uri.parse('$baseUrl/reports/daily-summary'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load daily summary');
    }
  }

  Future<List<dynamic>> getTopProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/top-products'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load top products');
    }
  }

  Future<List<dynamic>> getActivityLogs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/activities'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load activity logs');
    }
  }

  Future<Map<String, dynamic>?> getActiveShift() async {
    final response = await http.get(
      Uri.parse('$baseUrl/shifts/active'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      if (response.body.trim() == 'null' || response.body.trim().isEmpty) return null;
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<bool> openShift(double startingCash) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shifts/open'),
      headers: await _getHeaders(isJson: true),
      body: jsonEncode({'startingCash': startingCash}),
    );
    return response.statusCode == 201;
  }

  Future<bool> closeShift(double actualCash) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shifts/close'),
      headers: await _getHeaders(isJson: true),
      body: jsonEncode({'actualCash': actualCash}),
    );
    return response.statusCode == 200;
  }

  Future<bool> voidTransaction(int transactionId, String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/$transactionId/void'),
      headers: await _getHeaders(isJson: true),
      body: jsonEncode({'pin': pin}),
    );
    return response.statusCode == 200;
  }

  // ==========================================
  // PROMO ENGINE ENDPOINTS
  // ==========================================
  
  Future<List<dynamic>> getPromos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/promos'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load promos');
    }
  }

  Future<List<dynamic>> getActivePromos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/promos/active'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load active promos');
    }
  }

  Future<bool> createPromo(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/promos'),
      headers: await _getHeaders(isJson: true),
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  Future<bool> updatePromo(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/promos/$id'),
      headers: await _getHeaders(isJson: true),
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  Future<bool> deletePromo(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/promos/$id'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  // ==========================================
  // RECIPE / BOM ENDPOINTS
  // ==========================================

  Future<List<dynamic>> getUnits() async {
    final response = await http.get(Uri.parse('$baseUrl/units'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load units');
  }

  Future<bool> createUnit(Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$baseUrl/units'), headers: await _getHeaders(isJson: true), body: jsonEncode(data));
    return response.statusCode == 201;
  }

  Future<bool> updateUnit(int id, Map<String, dynamic> data) async {
    final response = await http.put(Uri.parse('$baseUrl/units/$id'), headers: await _getHeaders(isJson: true), body: jsonEncode(data));
    return response.statusCode == 200;
  }

  Future<bool> deleteUnit(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/units/$id'), headers: await _getHeaders());
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getRawMaterials() async {
    final response = await http.get(Uri.parse('$baseUrl/raw-materials'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load raw materials');
  }

  Future<bool> createRawMaterial(Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$baseUrl/raw-materials'), headers: await _getHeaders(isJson: true), body: jsonEncode(data));
    return response.statusCode == 201;
  }

  Future<bool> updateRawMaterial(int id, Map<String, dynamic> data) async {
    final response = await http.put(Uri.parse('$baseUrl/raw-materials/$id'), headers: await _getHeaders(isJson: true), body: jsonEncode(data));
    return response.statusCode == 200;
  }

  Future<bool> deleteRawMaterial(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/raw-materials/$id'), headers: await _getHeaders());
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getRecipesByProduct(int productId) async {
    final response = await http.get(Uri.parse('$baseUrl/recipes/product/$productId'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load recipes');
  }

  Future<bool> saveRecipes(int productId, List<Map<String, dynamic>> recipes) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recipes/product/$productId'),
      headers: await _getHeaders(isJson: true),
      body: jsonEncode({'recipes': recipes}),
    );
    return response.statusCode == 200;
  }
}
