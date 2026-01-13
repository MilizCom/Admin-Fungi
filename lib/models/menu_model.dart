import 'dart:convert';

class Product {
  final int? id;
  final String name;
  final int price; // Harga Tampilan (misal harga terendah)
  final String imagePath;
  final String category;
  final String subCategory;
  int quantity;

  // LOGIKA BARU: Map Kode -> Harga (Contoh: {'H': 15000, 'L': 22000})
  Map<String, int> variantPrices;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.category,
    required this.subCategory,
    this.quantity = 0,
    this.variantPrices = const {},
  });

  // Helper: Cek apakah punya varian
  bool get hasVariant => variantPrices.isNotEmpty;

  factory Product.fromMap(Map<String, dynamic> map) {
    // Decode JSON String dari database ke Map Dart
    Map<String, int> parsedVariants = {};
    if (map['variant_data'] != null &&
        map['variant_data'].toString().isNotEmpty) {
      try {
        Map<String, dynamic> decoded = jsonDecode(map['variant_data']);
        decoded.forEach((key, value) {
          parsedVariants[key] = value as int;
        });
      } catch (e) {
        print("Error parsing variants: $e");
      }
    }

    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      imagePath: map['imagePath'],
      category: map['category'],
      subCategory: map['subCategory'],
      quantity: map['quantity'],
      variantPrices: parsedVariants,
    );
  }
}

// Model Kategori (Hanya untuk Tampilan UI, tidak masuk DB)
class SubCategory {
  final String name;
  final List<Product> products;
  SubCategory({required this.name, required this.products});
}

class MenuCategory {
  final String name;
  final List<SubCategory> subCategories;
  MenuCategory({required this.name, required this.subCategories});
}
