import 'dart:convert';

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/ingredient_model.dart';
import '../models/admin_product_model.dart';
import 'package:http/http.dart' as http; // <--- TAMBAHKAN INI

class IngredientController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var ingredients = <IngredientModel>[].obs;
  var isLoading = false.obs;
  var isSyncing = false.obs;
  var lastSyncTimeDisplay = "Belum pernah".obs;

  @override
  void onInit() {
    super.onInit();
    bindIngredients();
    fetchLastSyncTime();

    // Opsional: Langsung sync saat dibuka pertama kali
    // syncStockFromTransactions();
  }

  // 1. MONITOR STOK BAHAN BAKU
  void bindIngredients() {
    _firestore.collection('ingredients').snapshots().listen((snapshot) {
      var list = snapshot.docs
          .map((doc) => IngredientModel.fromFirestore(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.stock.compareTo(b.stock));
      ingredients.assignAll(list);
    });
  }

  // 2. CEK WAKTU TERAKHIR SYNC
  Future<void> fetchLastSyncTime() async {
    try {
      var doc = await _firestore
          .collection('system_settings')
          .doc('stock_sync')
          .get();
      if (doc.exists) {
        String lastTime = doc.data()?['last_checked_at'] ?? '';
        if (lastTime.isNotEmpty) {
          try {
            // Coba parse format "2026-02-05 19:54:14"
            DateTime dt = DateTime.parse(lastTime);
            lastSyncTimeDisplay.value =
                "${dt.day}/${dt.month} ${dt.hour}:${dt.minute}";
          } catch (e) {
            lastSyncTimeDisplay.value = lastTime;
          }
        }
      } else {
        // Set default waktu sekarang agar transaksi lama tidak ikut terhitung
        await setInitialSyncPoint();
      }
    } catch (e) {
      print("Error time: $e");
    }
  }

  Future<void> setInitialSyncPoint() async {
    // Format String: "YYYY-MM-DD HH:mm:ss"
    String now = DateTime.now().toString().substring(0, 19);
    await _firestore.collection('system_settings').doc('stock_sync').set({
      'last_checked_at': now,
    });
    lastSyncTimeDisplay.value = "Reset (Baru Saja)";
  }

  // ==========================================================
  // 3. LOGIKA SYNC DENGAN "TRIPLE LOCK" (ANTI DOUBLE)
  // ==========================================================
  Future<void> syncStockFromTransactions() async {
    // [LOCK 1] UI Guard: Cegah tombol ditekan 2x saat loading
    if (isSyncing.value) {
      print("⚠️ Sync sedang berjalan, permintaan kedua ditolak.");
      return;
    }

    isSyncing.value = true;

    try {
      // A. Ambil Waktu Terakhir Cek (Time-based filter)
      var settingsDoc = await _firestore
          .collection('system_settings')
          .doc('stock_sync')
          .get();
      String lastCheck =
          settingsDoc.data()?['last_checked_at'] ?? DateTime.now().toString();

      print("🔍 Mencari transaksi setelah: $lastCheck");

      // B. Query Transaksi Baru
      QuerySnapshot trxSnapshot = await _firestore
          .collection('transaksi')
          .where('transaction_date', isGreaterThan: lastCheck)
          .orderBy('transaction_date', descending: false)
          .get();

      if (trxSnapshot.docs.isEmpty) {
        Get.snackbar(
          "Info",
          "Tidak ada transaksi baru.",
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
        isSyncing.value = false;
        return;
      }

      // Siapkan Batch (Atomic Operation)
      // Ini memastikan Potong Stok & Update Status terjadi bersamaan
      WriteBatch batch = _firestore.batch();
      int processedCount = 0;

      // C. Ambil Master Produk (untuk Resep)
      QuerySnapshot productSnapshot = await _firestore
          .collection('products')
          .get();
      Map<String, AdminProductModel> productMapByName = {};
      for (var doc in productSnapshot.docs) {
        var p = AdminProductModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        productMapByName[p.name.toLowerCase().trim()] = p;
      }

      // D. Loop Setiap Transaksi
      for (var doc in trxSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> items = data['items'] ?? [];

        for (var item in items) {
          String productName = (item['product_name'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          String variantName = (item['variant'] ?? '-')
              .toString()
              .trim(); // Ambil Variant (misal "L" atau "M")
          int qtySold = (item['qty'] ?? 0) as int;

          // Pencocokan Nama Produk
          if (productMapByName.containsKey(productName)) {
            var productMaster = productMapByName[productName]!;
            List<RecipeItem> targetRecipe = [];

            // LOGIKA PEMILIHAN RESEP:
            // 1. Cek apakah ada resep KHUSUS untuk varian ini? (Misal varian "L")
            if (variantName != '-' &&
                productMaster.variantRecipes.containsKey(variantName)) {
              targetRecipe = productMaster.variantRecipes[variantName]!;
              print(" -> Pakai Resep Varian [$variantName] untuk $productName");
            }
            // 2. Jika tidak ada resep varian, pakai resep DEFAULT
            else {
              targetRecipe = productMaster.recipe;
              print(" -> Pakai Resep Default untuk $productName");
            }

            // Eksekusi Potong Stok
            if (targetRecipe.isNotEmpty) {
              for (var recipeItem in targetRecipe) {
                int totalDeduct = recipeItem.amount * qtySold;
                DocumentReference ingRef = _firestore
                    .collection('ingredients')
                    .doc(recipeItem.ingredientId);
                batch.update(ingRef, {
                  'stock': FieldValue.increment(-totalDeduct),
                });
              }
            }
          }
        }
        processedCount++;
      }

      // E. Update Waktu Terakhir Cek (Hanya jika ada data)
      if (trxSnapshot.docs.isNotEmpty) {
        String newLastCheck = trxSnapshot.docs.last['transaction_date'];
        batch.set(_firestore.collection('system_settings').doc('stock_sync'), {
          'last_checked_at': newLastCheck,
        });
      }

      // F. EKSEKUSI SEMUA PERUBAHAN
      if (processedCount > 0) {
        await batch.commit();
        print("✅ $processedCount transaksi berhasil diproses & dikunci.");

        fetchLastSyncTime(); // Update jam di UI
        Get.snackbar(
          "Sukses",
          "$processedCount transaksi diproses & stok dipotong.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // Jika masuk sini, berarti ada transaksi baru TAPI semuanya sudah berstatus true (sudah diproses sebelumnya)
        Get.snackbar(
          "Info",
          "Semua transaksi baru sudah terhitung sebelumnya (Aman).",
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("❌ Sync Error: $e");
      Get.snackbar(
        "Error",
        "Gagal sync: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      // Buka Lock UI
      isSyncing.value = false;
    }
  }

  // ==========================================================
  // 4. CRUD BAHAN BAKU (SAVE INGREDIENT)
  // ==========================================================
  Future<void> saveIngredient({
    String? id,
    required String name,
    required String unit,
    required int stock,
    int minStock = 10,
  }) async {
    isLoading.value = true;
    try {
      if (id == null) {
        await _firestore.collection('ingredients').add({
          'name': name,
          'unit': unit,
          'stock': stock,
          'min_stock': minStock,
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('ingredients').doc(id).update({
          'name': name,
          'unit': unit,
          'stock': stock,
          'min_stock': minStock,
        });
      }
      Get.back();
    } catch (e) {
      Get.snackbar("Error", "$e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveRecipeToProduct(
    String productId,
    List<RecipeItem> newRecipe, {
    String? variantName,
  }) async {
    try {
      if (variantName != null && variantName != "Default") {
        await _firestore.collection('products').doc(productId).update({
          'variant_recipes.$variantName': newRecipe
              .map((e) => e.toMap())
              .toList(),
        });
      } else {
        // Simpan sebagai Resep Utama
        await _firestore.collection('products').doc(productId).update({
          'recipe': newRecipe.map((e) => e.toMap()).toList(),
        });
      }
      Get.snackbar(
        "Sukses",
        "Resep ${variantName ?? 'Default'} berhasil disimpan",
      );
    } catch (e) {
      Get.snackbar("Gagal", "$e");
    }
  }
  // Masukkan di dalam class IngredientController

  Future<void> exportStockToSpreadsheet() async {
    try {
      // 1. Indikator Loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      if (ingredients.isEmpty) {
        Get.back();
        Get.snackbar("Info", "Data stok kosong, tidak ada yang diexport.");
        return;
      }

      // 2. Siapkan Data JSON
      List<Map<String, dynamic>> stockData = ingredients.map((ing) {
        return {
          "name": ing.name,
          "unit": ing.unit,
          "stock": ing.stock,
          "min": ing.minStock,
        };
      }).toList();

      // 3. Siapkan Body Request
      Map<String, dynamic> payload = {
        "reportType": "stock", // <--- KUNCI PENTING
        "filterLabel": "Semua Stok",
        "items": stockData,
      };

      // 4. Kirim ke Google Script
      // GANTI URL INI DENGAN URL DEPLOYMENT ANDA YANG BARU
      const String url =
          "https://script.google.com/macros/s/AKfycbzJDQZAuJTdCecUU5rsXfSLy4tM0WYsEjWnIGSMby4KUE5zE1SZ3tMSHNuWBUNX5Bib/exec";

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(payload),
        headers: {"Content-Type": "text/plain"},
      );

      Get.back(); // Tutup Loading

      if (response.statusCode == 200 || response.statusCode == 302) {
        Get.snackbar(
          "Sukses",
          "Laporan Stok berhasil dikirim ke Spreadsheet!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw "Server error: ${response.statusCode}";
      }
    } catch (e) {
      Get.back(); // Tutup Loading jika error
      Get.snackbar(
        "Gagal",
        "Gagal export stok: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
