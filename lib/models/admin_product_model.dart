class RecipeItem {
  final String ingredientId;
  final String ingredientName;
  final int amount;

  RecipeItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.amount,
  });

  factory RecipeItem.fromMap(Map<String, dynamic> data) {
    return RecipeItem(
      ingredientId: data['ingredientId'] ?? '',
      ingredientName: data['ingredientName'] ?? '',
      amount: (data['amount'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'ingredientId': ingredientId,
    'ingredientName': ingredientName,
    'amount': amount,
  };
}

class AdminProductModel {
  final String id;
  final String name;
  final int price;
  final String category;
  final String subCategory;
  final String imagePath;
  // Resep Default (untuk produk tanpa varian)
  final List<RecipeItem> recipe;

  // Data Varian (Harga) -> Contoh: {"M": 19000, "L": 23000}
  final Map<String, int> variantData;

  // Resep Varian -> Contoh: {"M": [Gula 10gr], "L": [Gula 20gr]}
  final Map<String, List<RecipeItem>> variantRecipes;

  AdminProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.subCategory = '',
    this.imagePath = '',
    this.recipe = const [],
    this.variantData = const {},
    this.variantRecipes = const {},
  });

  factory AdminProductModel.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    // Parsing Variant Data (Harga)
    Map<String, int> variants = {};
    if (data['variant_data'] != null) {
      (data['variant_data'] as Map<String, dynamic>).forEach((key, value) {
        variants[key] = (value as num).toInt();
      });
    }

    // Parsing Variant Recipes (Resep per varian)
    Map<String, List<RecipeItem>> vRecipes = {};
    if (data['variant_recipes'] != null) {
      (data['variant_recipes'] as Map<String, dynamic>).forEach((key, value) {
        if (value is List) {
          vRecipes[key] = value.map((e) => RecipeItem.fromMap(e)).toList();
        }
      });
    }

    return AdminProductModel(
      id: docId,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toInt(),
      category: data['category'] ?? '',
      subCategory: data['subCategory'] ?? '',
      imagePath: data['imagePath'] ?? '', // Perbaiki key sesuai JSON Anda
      variantData: variants,
      variantRecipes: vRecipes, // <--- Load Resep Varian
      // Parsing Resep Default
      recipe: (data['recipe'] as List<dynamic>? ?? [])
          .map((item) => RecipeItem.fromMap(item))
          .toList(),
    );
  }
}
