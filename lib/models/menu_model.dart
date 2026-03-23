import 'dart:convert';

class Product {
  final String? id; // <--- UBAH KE STRING (Wajib untuk Firestore)
  final String name;
  final int price;
  final String imagePath;
  final String category;
  final String subCategory;
  int quantity;

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

  bool get hasVariant => variantPrices.isNotEmpty;

  factory Product.fromMap(Map<String, dynamic> map) {
    Map<String, int> parsedVariants = {};

    // --- PERBAIKAN LOGIKA PARSING VARIAN ---
    // Firestore bisa menyimpan data sebagai MAP langsung, tidak selalu JSON String.
    // Jadi kita cek tipenya dulu.
    var rawData = map['variant_data'];

    if (rawData != null) {
      // KASUS 1: Data berupa String JSON (Sisa dari SQLite)
      if (rawData is String && rawData.isNotEmpty) {
        try {
          Map<String, dynamic> decoded = jsonDecode(rawData);
          decoded.forEach((key, value) {
            parsedVariants[key] = (value as num).toInt();
          });
        } catch (e) {
          print("Error parsing variant JSON: $e");
        }
      }
      // KASUS 2: Data berupa MAP (Format Native Firestore)
      else if (rawData is Map) {
        try {
          rawData.forEach((key, value) {
            parsedVariants[key.toString()] = (value as num).toInt();
          });
        } catch (e) {
          print("Error parsing variant Map: $e");
        }
      }
    }

    return Product(
      // Konversi ID ke String dengan aman
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      imagePath: map['imagePath'] ?? '',
      category: map['category'] ?? 'Umum',
      subCategory: map['subCategory'] ?? 'Umum',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      variantPrices: parsedVariants,
    );
  }
}

// Model Kategori (Tidak berubah)
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
