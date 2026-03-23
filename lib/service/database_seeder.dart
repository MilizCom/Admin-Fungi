import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class DatabaseSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedDatabase() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      print("🌱 Memulai Seeder Khusus Bahan Baku...");

      final List<Map<String, dynamic>> rawIngredients = [
        // --- KATEGORI: BAHAN MAKANAN UTAMA ---
        {'name': 'Jamur Tiram', 'unit': 'gram', 'stock': 0, 'min': 1000},
        {'name': 'Kulit Dimsum', 'unit': 'pcs', 'stock': 0, 'min': 50},
        {'name': 'Wortel', 'unit': 'gram', 'stock': 0, 'min': 200},

        // --- KATEGORI: BUMBU DAPUR (Siung/Butir) ---
        {'name': 'Bawang Putih', 'unit': 'siung', 'stock': 0, 'min': 50},
        {'name': 'Bawang Merah', 'unit': 'siung', 'stock': 0, 'min': 50},
        {'name': 'Bawang Bombai', 'unit': 'siung', 'stock': 0, 'min': 10},
        {'name': 'Cabe Rawit', 'unit': 'butir', 'stock': 0, 'min': 100},
        {'name': 'Jeruk Limau', 'unit': 'butir', 'stock': 0, 'min': 10},
        {'name': 'Daun Jeruk', 'unit': 'helai', 'stock': 0, 'min': 20},
        {'name': 'Daun Kari', 'unit': 'pcs', 'stock': 0, 'min': 10},

        // --- KATEGORI: TEPUNG & BUBUK (Standard ke Gram) ---
        {'name': 'Tepung Terigu', 'unit': 'gram', 'stock': 0, 'min': 500},
        {'name': 'Tepung Maizena', 'unit': 'gram', 'stock': 0, 'min': 200},
        {'name': 'Tepung Tapioka', 'unit': 'gram', 'stock': 0, 'min': 300},
        {'name': 'Tepung Serbaguna', 'unit': 'gram', 'stock': 0, 'min': 300},
        {'name': 'Tepung Panir', 'unit': 'gram', 'stock': 0, 'min': 200},
        {'name': 'Soda Kue', 'unit': 'gram', 'stock': 0, 'min': 50},
        {'name': 'Baking Powder', 'unit': 'gram', 'stock': 0, 'min': 50},
        {'name': 'Garam', 'unit': 'gram', 'stock': 0, 'min': 200},
        {'name': 'Gula Pasir', 'unit': 'gram', 'stock': 0, 'min': 500},
        {'name': 'Kaldu Jamur', 'unit': 'gram', 'stock': 0, 'min': 200},
        {'name': 'Kaldu Bubuk', 'unit': 'gram', 'stock': 0, 'min': 200},
        {'name': 'Lada Bubuk', 'unit': 'gram', 'stock': 0, 'min': 50},
        {'name': 'Bubuk Cabai', 'unit': 'gram', 'stock': 0, 'min': 50},
        {'name': 'Penyedap Rasa', 'unit': 'gram', 'stock': 0, 'min': 100},

        // --- KATEGORI: CAIRAN & SAUS (Ml/Gram) ---
        {'name': 'Air', 'unit': 'ml', 'stock': 0, 'min': 5000},
        {'name': 'Minyak Goreng', 'unit': 'ml', 'stock': 0, 'min': 1000},
        {'name': 'Minyak Wijen', 'unit': 'ml', 'stock': 0, 'min': 100},
        {'name': 'Kecap Asin', 'unit': 'ml', 'stock': 0, 'min': 200},
        {'name': 'Kecap Manis', 'unit': 'ml', 'stock': 0, 'min': 300},
        {'name': 'Kecap Inggris', 'unit': 'ml', 'stock': 0, 'min': 100},
        {'name': 'Saus Tiram', 'unit': 'gram', 'stock': 0, 'min': 200},
        {'name': 'Saus Teriyaki', 'unit': 'gram', 'stock': 0, 'min': 200},
        {'name': 'Saus Tomat', 'unit': 'gram', 'stock': 0, 'min': 200},
        {'name': 'Saus Sambal', 'unit': 'gram', 'stock': 0, 'min': 300},
        {'name': 'Saus Pasta', 'unit': 'gram', 'stock': 0, 'min': 100},
        {'name': 'Madu', 'unit': 'gram', 'stock': 0, 'min': 100},
        {'name': 'Mentega', 'unit': 'gram', 'stock': 0, 'min': 200},
        {'name': 'Putih Telur', 'unit': 'gram', 'stock': 0, 'min': 300},

        // --- KATEGORI: BAHAN MINUMAN ---
        {'name': 'Espresso', 'unit': 'ml', 'stock': 0, 'min': 500},
        {'name': 'Susu UHT', 'unit': 'ml', 'stock': 0, 'min': 2000},
        {'name': 'Susu Full Cream', 'unit': 'ml', 'stock': 0, 'min': 500},
        {
          'name': 'Susu Bubuk Full Cream',
          'unit': 'gram',
          'stock': 0,
          'min': 200,
        },
        {'name': 'SKM', 'unit': 'ml', 'stock': 0, 'min': 500},
        {'name': 'Aren Cair', 'unit': 'ml', 'stock': 0, 'min': 300},
        {'name': 'Creamer', 'unit': 'ml', 'stock': 0, 'min': 200},
        {'name': 'Sirup Butterscotch', 'unit': 'ml', 'stock': 0, 'min': 100},
        {'name': 'Sauce Caramel', 'unit': 'ml', 'stock': 0, 'min': 100},
        {'name': 'Sirup Vanila', 'unit': 'ml', 'stock': 0, 'min': 100},
        {'name': 'Es Batu', 'unit': 'gram', 'stock': 0, 'min': 5000},
        {'name': 'Cup', 'unit': 'pcs', 'stock': 0, 'min': 50},

        // --- KATEGORI: BUBUK MINUMAN ---
        {'name': 'Bubuk Taro', 'unit': 'gram', 'stock': 0, 'min': 100},
        {'name': 'Bubuk Red Velvet', 'unit': 'gram', 'stock': 0, 'min': 100},
        {'name': 'Bubuk Coklat', 'unit': 'gram', 'stock': 0, 'min': 100},
        {'name': 'Bubuk Strawberry', 'unit': 'gram', 'stock': 0, 'min': 100},
        {'name': 'Bubuk Thai Tea', 'unit': 'gram', 'stock': 0, 'min': 100},
        {'name': 'Bubuk Green Tea', 'unit': 'gram', 'stock': 0, 'min': 100},
      ];

      // TULIS KE DATABASE (Cek Duplikat dulu)
      for (var item in rawIngredients) {
        await _addIngredientIfNotExists(item);
      }

      Get.back(); // Tutup Loading

      Get.snackbar(
        "Seeder Bahan Selesai",
        "Semua bahan dari dokumen telah dimasukkan ke database Ingredients.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        "Error",
        "$e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print(e);
    }
  }

  // Fungsi helper untuk mencegah duplikat bahan
  Future<void> _addIngredientIfNotExists(Map<String, dynamic> item) async {
    final query = await _firestore
        .collection('ingredients')
        .where('name', isEqualTo: item['name'])
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      // Jika belum ada, buat baru
      await _firestore.collection('ingredients').add({
        'name': item['name'],
        'unit': item['unit'],
        'stock': item['stock'],
        'min_stock': item['min'], // Sesuaikan nama field dengan model Anda
        'created_at': FieldValue.serverTimestamp(),
      });
      print("✅ Menambahkan: ${item['name']}");
    } else {
      print("⏭️ Skip (Sudah ada): ${item['name']}");
    }
  }
}
