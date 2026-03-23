import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/admin_product_model.dart';

class AdminMenuController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var products = <AdminProductModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    bindProducts();
  }

  // 1. LIHAT SEMUA PRODUK (REALTIME)
  void bindProducts() {
    isLoading.value = true;
    // Kita urutkan berdasarkan Nama agar rapi di layar
    _firestore.collection('products').orderBy('name').snapshots().listen((
      snapshot,
    ) {
      products.value = snapshot.docs
          .map((doc) => AdminProductModel.fromFirestore(doc.data(), doc.id))
          .toList();
      isLoading.value = false;
    });
  }

  // 2. TAMBAH PRODUK BARU
  Future<void> addProduct(String name, int price, String category) async {
    try {
      await _firestore.collection('products').add({
        'name': name,
        'price': price,
        'category': category,
        'image_path': '',
        // Kita hapus 'stock' dan 'min_stock' karena sekarang pakai Bahan Baku
        'recipe': [], // Default resep kosong saat dibuat
        'created_at': FieldValue.serverTimestamp(),
      });
      Get.back();
      Get.snackbar(
        "Sukses",
        "Produk berhasil ditambahkan. Jangan lupa atur Resep-nya!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "$e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // 3. EDIT PRODUK (Nama, Harga, Kategori)
  // Note: Resep tidak diubah di sini, tapi di RecipeEditorDialog
  Future<void> updateProduct(
    String id,
    String name,
    int price,
    String category,
  ) async {
    try {
      await _firestore.collection('products').doc(id).update({
        'name': name,
        'price': price,
        'category': category,
      });
      Get.back(); // Tutup dialog/sheet
      Get.snackbar(
        "Sukses",
        "Data produk diperbarui",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Error", "$e");
    }
  }

  // 4. HAPUS PRODUK
  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection('products').doc(id).delete();
      Get.snackbar(
        "Dihapus",
        "Produk telah dihapus dari menu",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Error", "$e");
    }
  }
}
