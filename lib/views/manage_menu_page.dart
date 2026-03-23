import 'package:admin_fungi/views/recipe_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_menu_controller.dart';
import '../models/admin_product_model.dart';

class ManageMenuPage extends StatefulWidget {
  const ManageMenuPage({super.key});

  @override
  State<ManageMenuPage> createState() => _ManageMenuPageState();
}

class _ManageMenuPageState extends State<ManageMenuPage> {
  final AdminMenuController controller = Get.put(AdminMenuController());

  // State Lokal untuk Pencarian & Filter
  final TextEditingController searchC = TextEditingController();
  String selectedCategory = "Semua"; // Semua, Makanan, Minuman, Snack

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Kelola Menu & Resep",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Menu Baru", style: TextStyle(color: Colors.white)),
        onPressed: () => _showProductForm(context, null),
      ),
      body: Column(
        children: [
          // --- 1. SEARCH & FILTER SECTION ---
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: searchC,
                  onChanged: (val) => setState(() {}), // Refresh UI
                  decoration: InputDecoration(
                    hintText: "Cari menu (Nasi, Kopi, dll)...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Kategori Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip("Semua"),
                      const SizedBox(width: 8),
                      _buildCategoryChip("Makanan"),
                      const SizedBox(width: 8),
                      _buildCategoryChip("Minuman"),
                      const SizedBox(width: 8),
                      _buildCategoryChip("Snack"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- 2. LIST MENU ---
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // LOGIKA FILTER
              var filteredList = controller.products.where((p) {
                // Filter Nama
                bool matchName = p.name.toLowerCase().contains(
                  searchC.text.toLowerCase(),
                );
                // Filter Kategori
                bool matchCat =
                    selectedCategory == "Semua" ||
                    p.category.toLowerCase() == selectedCategory.toLowerCase();
                return matchName && matchCat;
              }).toList();

              if (filteredList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fastfood_outlined,
                        size: 60,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Menu tidak ditemukan.",
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredList.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildProductTile(context, filteredList[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    bool isSelected = selectedCategory == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => selectedCategory = label),
      selectedColor: Colors.orange.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.orange : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? Colors.orange : Colors.grey[300]!),
    );
  }

  Widget _buildProductTile(BuildContext context, AdminProductModel product) {
    // --- PERBAIKAN LOGIKA STATUS RESEP ---
    // Cek resep default ATAU resep varian
    bool hasDefaultRecipe = product.recipe.isNotEmpty;
    bool hasVariantRecipe = product.variantRecipes.values.any(
      (list) => list.isNotEmpty,
    );

    bool hasRecipe = hasDefaultRecipe || hasVariantRecipe;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Produk
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              product.category == 'Minuman'
                  ? Icons.local_cafe
                  : Icons.restaurant,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 15),

          // Info Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Rp ${product.price}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 6),

                // Badge Indikator Resep
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: hasRecipe ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasRecipe ? Icons.check_circle : Icons.warning,
                        size: 12,
                        color: hasRecipe ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasRecipe ? "Resep Aktif" : "Tanpa Resep",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: hasRecipe
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tombol Edit
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showProductForm(context, product),
          ),
        ],
      ),
    );
  }

  // --- FORM INPUT / EDIT PRODUK ---
  void _showProductForm(BuildContext context, AdminProductModel? product) {
    final nameC = TextEditingController(text: product?.name);
    final priceC = TextEditingController(text: product?.price.toString());
    final categoryC = TextEditingController(
      text: product?.category ?? "Makanan",
    );
    bool isEditing = product != null;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        height: Get.height * 0.9,
        child: Column(
          children: [
            // Header Form
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? "Edit Produk" : "Menu Baru",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),

            Expanded(
              child: ListView(
                children: [
                  TextField(
                    controller: nameC,
                    decoration: const InputDecoration(
                      labelText: "Nama Produk",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: priceC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Harga Dasar (Rp)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: categoryC,
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      hintText: "Makanan / Minuman",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // TOMBOL ATUR RESEP (Hanya Muncul saat EDIT)
                  if (isEditing) ...[
                    GestureDetector(
                      onTap: () {
                        Get.back(); // Tutup form edit
                        Get.to(() => RecipeEditorDialog(product: product));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.science,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Atur Resep & Komposisi",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text(
                                    "Hubungkan dengan stok bahan baku",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Tombol Hapus (Hanya Edit)
                  if (isEditing)
                    TextButton.icon(
                      onPressed: () {
                        Get.defaultDialog(
                          title: "Hapus Menu?",
                          middleText: "Menu ini akan dihapus permanen.",
                          textConfirm: "Hapus",
                          confirmTextColor: Colors.white,
                          buttonColor: Colors.red,
                          onConfirm: () {
                            controller.deleteProduct(product.id);
                            Get.back(); // Dialog
                            Get.back(); // Sheet
                          },
                        );
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        "Hapus Menu Ini",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  if (isEditing) {
                    controller.updateProduct(
                      product.id,
                      nameC.text,
                      int.tryParse(priceC.text) ?? 0,
                      categoryC.text,
                    );
                  } else {
                    controller.addProduct(
                      nameC.text,
                      int.tryParse(priceC.text) ?? 0,
                      categoryC.text,
                    );
                  }
                },
                child: Text(
                  isEditing ? "SIMPAN PERUBAHAN" : "TAMBAH MENU",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
