import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/kasir_controller.dart';
import '../models/menu_model.dart';

class AturMenuPage extends StatelessWidget {
  const AturMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final KasirController controller = Get.find<KasirController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Atur Menu & Produk"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Menu", style: TextStyle(color: Colors.white)),
        onPressed: () => showProductBottomSheet(context, controller, null),
      ),
      body: Obx(() {
        // Flatten Data
        List<Product> allProducts = [];
        for (var cat in controller.menuData) {
          for (var sub in cat.subCategories) {
            allProducts.addAll(sub.products);
          }
        }

        if (allProducts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Text(
                  "Belum ada menu. Tekan tombol +",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: allProducts.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final product = allProducts[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImage(product.imagePath),
                ),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${product.category} > ${product.subCategory}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Dasar: Rp ${product.price}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (product.variantPrices.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          "Opsi: ${product.variantPrices.keys.join(', ')}",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                  ],
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () =>
                          showProductBottomSheet(context, controller, product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Get.defaultDialog(
                          title: "Hapus?",
                          middleText: "Hapus ${product.name}?",
                          textConfirm: "Ya",
                          confirmTextColor: Colors.white,
                          buttonColor: Colors.red,
                          onConfirm: () {
                            controller.deleteProduct(product.id!);
                            Get.back();
                          },
                          textCancel: "Batal",
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } else {
      return Image.file(
        File(path),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
  }

  // ===========================================================================
  // FORM BOTTOM SHEET (DENGAN DROPDOWN AUTOCOMPLETE)
  // ===========================================================================
  void showProductBottomSheet(
    BuildContext context,
    KasirController controller,
    Product? product,
  ) {
    final isEdit = product != null;

    final nameC = TextEditingController(text: isEdit ? product.name : '');
    final priceC = TextEditingController(
      text: isEdit ? product.price.toString() : '',
    );

    // Controller untuk Autocomplete (Bukan TextField biasa)
    // Kita gunakan ValueNotifier untuk kategori agar SubKategori bisa bereaksi
    final TextEditingController catC = TextEditingController(
      text: isEdit ? product.category : '',
    );
    final TextEditingController subC = TextEditingController(
      text: isEdit ? product.subCategory : '',
    );

    // Reactive Trigger untuk update dropdown Sub Kategori saat Kategori berubah
    RxString currentCategory = (isEdit ? product.category : '').obs;

    RxString imagePath = (isEdit ? product.imagePath : '').obs;

    // Harga Varian Controller
    final hPriceC = TextEditingController(
      text: isEdit ? (product.variantPrices['H']?.toString() ?? '') : '',
    );
    final mPriceC = TextEditingController(
      text: isEdit ? (product.variantPrices['M']?.toString() ?? '') : '',
    );
    final lPriceC = TextEditingController(
      text: isEdit ? (product.variantPrices['L']?.toString() ?? '') : '',
    );

    RxBool isH = (isEdit && product.variantPrices.containsKey('H')).obs;
    RxBool isM = (isEdit && product.variantPrices.containsKey('M')).obs;
    RxBool isL = (isEdit && product.variantPrices.containsKey('L')).obs;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.9,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? "Edit Menu" : "Tambah Menu",
                  style: const TextStyle(
                    fontSize: 18,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    // GAMBAR
                    Obx(
                      () => GestureDetector(
                        onTap: () async {
                          String? p = await controller.pickImage();
                          if (p != null) imagePath.value = p;
                        },
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: imagePath.value.isEmpty
                              ? const Icon(Icons.camera_alt, color: Colors.grey)
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildImage(imagePath.value),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // TEXT FIELDS
                    TextField(
                      controller: nameC,
                      decoration: const InputDecoration(
                        labelText: "Nama Menu",
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.fastfood),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceC,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Harga Dasar (Rp)",
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // === AUTOCOMPLETE KATEGORI (DROPDOWN CERDAS) ===
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Autocomplete<String>(
                          initialValue: TextEditingValue(text: catC.text),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            // Ambil list kategori dari controller
                            List<String> options = controller
                                .getExistingCategories();
                            if (textEditingValue.text == '') return options;
                            return options.where(
                              (String option) => option.toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              ),
                            );
                          },
                          onSelected: (String selection) {
                            catC.text = selection;
                            currentCategory.value =
                                selection; // Update trigger sub kategori
                            subC.clear(); // Reset sub kategori karena kategori induk berubah
                          },
                          fieldViewBuilder:
                              (
                                context,
                                textController,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                // Sinkronkan controller internal autocomplete dgn controller kita
                                if (catC.text.isNotEmpty &&
                                    textController.text.isEmpty)
                                  textController.text = catC.text;
                                catC.addListener(() {
                                  if (catC.text != textController.text)
                                    textController.text = catC.text;
                                });
                                textController.addListener(() {
                                  currentCategory.value = textController.text;
                                  catC.text = textController.text;
                                });

                                return TextField(
                                  controller: textController,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: "Kategori (Pilih/Ketik Baru)",
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    prefixIcon: Icon(Icons.category),
                                    suffixIcon: Icon(Icons.arrow_drop_down),
                                  ),
                                );
                              },
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // === AUTOCOMPLETE SUB-KATEGORI (DEPENDENT DROPDOWN) ===
                    Obx(() {
                      // Kode ini akan rebuild saat currentCategory berubah
                      String cat = currentCategory.value;
                      List<String> subOptions = controller
                          .getExistingSubCategories(cat);

                      return Autocomplete<String>(
                        key: ValueKey(
                          cat,
                        ), // Penting agar widget rebuild saat kategori berubah
                        initialValue: TextEditingValue(text: subC.text),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '') return subOptions;
                          return subOptions.where(
                            (String option) => option.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                          );
                        },
                        onSelected: (String selection) {
                          subC.text = selection;
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              // Sinkronisasi controller
                              if (subC.text.isNotEmpty &&
                                  textController.text.isEmpty)
                                textController.text = subC.text;
                              textController.addListener(() {
                                subC.text = textController.text;
                              });

                              return TextField(
                                controller: textController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: "Sub-Kategori",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  prefixIcon: Icon(Icons.layers),
                                  suffixIcon: Icon(Icons.arrow_drop_down),
                                ),
                              );
                            },
                      );
                    }),

                    const SizedBox(height: 20),
                    const Divider(),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Opsi Varian & Harga Khusus:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // VARIAN
                    _buildVariantRow("Hot (Panas)", isH, hPriceC),
                    _buildVariantRow("Medium (Sedang)", isM, mPriceC),
                    _buildVariantRow("Large (Besar)", isL, lPriceC),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  if (nameC.text.isEmpty ||
                      priceC.text.isEmpty ||
                      catC.text.isEmpty ||
                      subC.text.isEmpty) {
                    controller.showNotif(
                      "Error",
                      "Semua kolom teks utama wajib diisi!",
                      isError: true,
                    );
                    return;
                  }

                  Map<String, int> variantsMap = {};
                  if (isH.value && hPriceC.text.isNotEmpty)
                    variantsMap['H'] = int.tryParse(hPriceC.text) ?? 0;
                  if (isM.value && mPriceC.text.isNotEmpty)
                    variantsMap['M'] = int.tryParse(mPriceC.text) ?? 0;
                  if (isL.value && lPriceC.text.isNotEmpty)
                    variantsMap['L'] = int.tryParse(lPriceC.text) ?? 0;

                  if (isEdit) {
                    controller.editProduct(
                      product.id!,
                      nameC.text,
                      priceC.text,
                      catC.text,
                      subC.text,
                      imagePath.value,
                      variantsMap,
                    );
                  } else {
                    controller.addProduct(
                      nameC.text,
                      priceC.text,
                      catC.text,
                      subC.text,
                      imagePath.value,
                      variantsMap,
                    );
                  }
                },
                child: const Text(
                  "SIMPAN",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildVariantRow(
    String label,
    RxBool isChecked,
    TextEditingController priceController,
  ) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Checkbox(
              value: isChecked.value,
              activeColor: Colors.green,
              onChanged: (v) => isChecked.value = v!,
            ),
            Text(label),
            const SizedBox(width: 10),
            Expanded(
              child: isChecked.value
                  ? TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Harga (Rp)",
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
