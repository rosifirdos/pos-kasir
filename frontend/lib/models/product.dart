import 'category.dart';

class Product {
  final int id;
  final int categoryId;
  final String sku;
  final String name;
  final String? imageUrl;
  final double buyPrice;
  final double sellPrice;
  final int currentStock;
  final bool isRecipeBased;
  final Category? category;

  Product({
    required this.id,
    required this.categoryId,
    required this.sku,
    required this.name,
    this.imageUrl,
    required this.buyPrice,
    required this.sellPrice,
    required this.currentStock,
    this.isRecipeBased = false,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      categoryId: json['categoryId'],
      sku: json['sku'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      buyPrice: double.parse(json['buyPrice'].toString()),
      sellPrice: double.parse(json['sellPrice'].toString()),
      currentStock: json['currentStock'],
      isRecipeBased: json['isRecipeBased'] ?? false,
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
    );
  }
}
