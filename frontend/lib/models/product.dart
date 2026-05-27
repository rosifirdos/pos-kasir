import 'category.dart';

class Product {
  final int id;
  final int categoryId;
  final String sku;
  final String name;
  final double buyPrice;
  final double sellPrice;
  final int currentStock;
  final Category? category;

  Product({
    required this.id,
    required this.categoryId,
    required this.sku,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.currentStock,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      categoryId: json['categoryId'],
      sku: json['sku'],
      name: json['name'],
      buyPrice: double.parse(json['buyPrice'].toString()),
      sellPrice: double.parse(json['sellPrice'].toString()),
      currentStock: json['currentStock'],
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
    );
  }
}
