class IngredientModel {
  final String id;
  final String name;
  final String unit; // Satuan: "gr", "ml", "pcs"
  final int stock; // Stok saat ini (misal: 1000 gr)
  final int minStock; // Batas aman

  IngredientModel({
    required this.id,
    required this.name,
    required this.unit,
    required this.stock,
    required this.minStock,
  });

  factory IngredientModel.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return IngredientModel(
      id: docId,
      name: data['name'] ?? 'Bahan',
      unit: data['unit'] ?? 'pcs',
      stock: (data['stock'] ?? 0).toInt(),
      minStock: (data['min_stock'] ?? 10).toInt(),
    );
  }
}
