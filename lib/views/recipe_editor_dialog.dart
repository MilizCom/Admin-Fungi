import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/admin_product_model.dart';
import '../models/ingredient_model.dart';
import '../controllers/ingredient_controller.dart';

class RecipeEditorDialog extends StatefulWidget {
  final AdminProductModel product;
  const RecipeEditorDialog({super.key, required this.product});

  @override
  State<RecipeEditorDialog> createState() => _RecipeEditorDialogState();
}

class _RecipeEditorDialogState extends State<RecipeEditorDialog> {
  final IngredientController ingController =
      Get.isRegistered<IngredientController>()
      ? Get.find<IngredientController>()
      : Get.put(IngredientController());

  String selectedVariant = "Default";
  List<String> availableVariants = ["Default"];
  List<RecipeItem> currentDisplayRecipe = [];

  // Cache lokal
  Map<String, List<RecipeItem>> stagedRecipes = {};
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    // 1. Siapkan Varian
    if (widget.product.variantData.isNotEmpty) {
      availableVariants.clear();
      availableVariants.addAll(widget.product.variantData.keys);
      selectedVariant = availableVariants.first;
    } else {
      availableVariants = ["Default"];
      selectedVariant = "Default";
    }

    // 2. Inisialisasi Map
    stagedRecipes["Default"] = List<RecipeItem>.from(widget.product.recipe);

    for (var v in availableVariants) {
      if (v != "Default") {
        if (widget.product.variantRecipes.containsKey(v)) {
          stagedRecipes[v] = List<RecipeItem>.from(
            widget.product.variantRecipes[v]!,
          );
        } else {
          stagedRecipes[v] = [];
        }
      }
    }

    for (var v in availableVariants) {
      if (!stagedRecipes.containsKey(v)) {
        stagedRecipes[v] = [];
      }
    }

    // 3. Tampilkan
    _loadRecipeToDisplay();
  }

  void _loadRecipeToDisplay() {
    setState(() {
      currentDisplayRecipe = List.from(stagedRecipes[selectedVariant]!);
    });
  }

  void _switchVariant(String newVariant) {
    setState(() {
      selectedVariant = newVariant;
      if (!stagedRecipes.containsKey(newVariant)) {
        stagedRecipes[newVariant] = [];
      }
      _loadRecipeToDisplay();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Resep: ${widget.product.name}"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // --- TAB VARIAN ---
          if (availableVariants.length > 1)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: availableVariants.length,
                separatorBuilder: (c, i) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  String vName = availableVariants[index];
                  bool isSelected = vName == selectedVariant;
                  return ChoiceChip(
                    label: Text(vName == "Default" ? "Dasar" : "Varian $vName"),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) _switchVariant(vName);
                    },
                    selectedColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                },
              ),
            ),

          const Divider(height: 1),

          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue[50],
            width: double.infinity,
            child: Text(
              "Edit Resep: ${selectedVariant == 'Default' ? 'Tanpa Varian' : 'Varian $selectedVariant'}",
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // --- LIST BAHAN ---
          Expanded(
            child: currentDisplayRecipe.isEmpty
                ? Center(
                    child: Text(
                      "Belum ada bahan.\nTambah sekarang.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: currentDisplayRecipe.length,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (context, index) {
                      var item = currentDisplayRecipe[index];
                      return ListTile(
                        title: Text(
                          item.ingredientName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("${item.amount}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              stagedRecipes[selectedVariant]!.removeAt(index);
                              _loadRecipeToDisplay();
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),

          // --- TOMBOL TAMBAH & SIMPAN ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showAddIngredientSheet(context), // Panggil Fungsi Baru
                    icon: const Icon(Icons.search),
                    label: const Text("CARI & TAMBAH BAHAN"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: isSaving ? null : _saveCurrentVariant,
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "SIMPAN RESEP $selectedVariant",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCurrentVariant() async {
    setState(() => isSaving = true);
    await ingController.saveRecipeToProduct(
      widget.product.id,
      stagedRecipes[selectedVariant]!,
      variantName: selectedVariant == "Default" ? null : selectedVariant,
    );
    setState(() => isSaving = false);
  }

  // =======================================================
  // FITUR PENCARIAN (BOTTOM SHEET BARU)
  // =======================================================
  void _showAddIngredientSheet(BuildContext context) {
    if (ingController.ingredients.isEmpty) {
      Get.snackbar("Info", "Stok bahan kosong");
      return;
    }

    // Menggunakan RxList untuk filtering realtime
    RxList<IngredientModel> filteredList = <IngredientModel>[].obs;
    filteredList.assignAll(ingController.ingredients); // Awalnya isi semua

    TextEditingController searchC = TextEditingController();

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        height: Get.height * 0.8, // Tinggi sheet 80% layar
        child: Column(
          children: [
            // Indikator geser
            Container(
              width: 40,
              height: 4,
              color: Colors.grey[300],
              margin: const EdgeInsets.only(bottom: 15),
            ),

            const Text(
              "Pilih Bahan Baku",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 15),

            // SEARCH BAR
            TextField(
              controller: searchC,
              autofocus:
                  false, // Jangan autofocus biar keyboard ga langsung nutupin
              decoration: InputDecoration(
                hintText: "Cari bahan (contoh: Susu, Gula)...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 15,
                ),
              ),
              onChanged: (val) {
                // LOGIKA FILTER
                if (val.isEmpty) {
                  filteredList.assignAll(ingController.ingredients);
                } else {
                  var result = ingController.ingredients
                      .where(
                        (ing) =>
                            ing.name.toLowerCase().contains(val.toLowerCase()),
                      )
                      .toList();
                  filteredList.assignAll(result);
                }
              },
            ),
            const SizedBox(height: 10),

            // LIST HASIL PENCARIAN
            Expanded(
              child: Obx(() {
                if (filteredList.isEmpty) {
                  return const Center(
                    child: Text(
                      "Bahan tidak ditemukan.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: filteredList.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    var ing = filteredList[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 5,
                      ),
                      title: Text(
                        ing.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "Sisa Stok: ${ing.stock} ${ing.unit}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.blue,
                      ),
                      onTap: () {
                        // Tutup search sheet, buka input jumlah
                        Get.back();
                        _inputAmount(ing);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true, // Agar bisa full height
    );
  }

  void _inputAmount(IngredientModel ing) {
    final amountC = TextEditingController();
    Get.defaultDialog(
      title: "Takaran ${ing.name}",
      content: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            TextField(
              controller: amountC,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Jumlah (${ing.unit})",
                hintText: "Contoh: 15",
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Varian Aktif: $selectedVariant",
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
      ),
      textConfirm: "Simpan",
      confirmTextColor: Colors.white,
      buttonColor: Colors.blue,
      onConfirm: () {
        int amount = int.tryParse(amountC.text) ?? 0;
        if (amount > 0) {
          // Tambahkan ke Map
          stagedRecipes[selectedVariant]!.add(
            RecipeItem(
              ingredientId: ing.id,
              ingredientName: ing.name,
              amount: amount,
            ),
          );
          // Refresh UI List
          _loadRecipeToDisplay();
          Get.back();
        }
      },
    );
  }
}
