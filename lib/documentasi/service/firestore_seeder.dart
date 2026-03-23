// import 'package:cloud_firestore/cloud_firestore.dart';

// class FirestoreSeeder {
//   // Collection target
//   static const String _colProducts = 'products';

//   /// Fungsi untuk mengisi data awal (Hanya jalan jika collection kosong)
//   static Future<void> seedProducts() async {
//     final FirebaseFirestore db = FirebaseFirestore.instance;

//     // 1. Cek apakah sudah ada data (Mencegah duplikasi)
//     var snapshot = await db.collection(_colProducts).limit(1).get();
//     if (snapshot.docs.isNotEmpty) {
//       print("⚠️ Seeder dibatalkan: Data produk sudah ada di Firestore.");
//       return;
//     }

//     print("🚀 Memulai proses seeding data Fungi Bites ke Firestore...");
//     WriteBatch batch = db.batch();

//     // 2. Data Mentah Produk Berdasarkan Gambar Menu
//     List<Map<String, dynamic>> products = [
//       // ==============================================
//       // KATEGORI: MAKANAN
//       // ==============================================

//       // --- MAIN COURSE ---
//       {
//         'name': 'Buttermilk Fungi Bawl',
//         'price': 20000,
//         'imagePath': 'assets/images/nasi.png',
//         'category': 'Makanan',
//         'subCategory': 'Main Course',
//         'quantity': 0,
//         'variant_data': {},
//       },
//       {
//         'name': 'Fungi Teriyaki Bawl',
//         'price': 20000,
//         'imagePath': 'assets/images/nasi.png',
//         'category': 'Makanan',
//         'subCategory': 'Main Course',
//         'quantity': 0,
//         'variant_data': {},
//       },
//       {
//         'name': 'Nasi Jamur Sambal Bawang',
//         'price': 20000,
//         'imagePath': 'assets/images/nasi.png',
//         'category': 'Makanan',
//         'subCategory': 'Main Course',
//         'quantity': 0,
//         'variant_data': {},
//       },
//       {
//         'name': 'Black Papper Fungi Bawl',
//         'price': 20000,
//         'imagePath': 'assets/images/nasi.png',
//         'category': 'Makanan',
//         'subCategory': 'Main Course',
//         'quantity': 0,
//         'variant_data': {},
//       },
//       {
//         'name': 'Fungi Pop Honey Sauce',
//         'price': 20000,
//         'imagePath': 'assets/images/nasi.png',
//         'category': 'Makanan',
//         'subCategory': 'Main Course',
//         'quantity': 0,
//         'variant_data': {},
//       },
//       {
//         'name': 'Fungi Pop Hot Glaze',
//         'price': 20000,
//         'imagePath': 'assets/images/nasi.png',
//         'category': 'Makanan',
//         'subCategory': 'Main Course',
//         'quantity': 0,
//         'variant_data': {},
//       },
//       {
//         'name': 'Fungi Pop Butter Sauce',
//         'price': 20000,
//         'imagePath': 'assets/images/nasi.png',
//         'category': 'Makanan',
//         'subCategory': 'Main Course',
//         'quantity': 0,
//         'variant_data': {},
//       },

//       // --- SNACK ---
//       {
//         'name': 'Crisjom',
//         'price': 20000,
//         'imagePath': 'assets/images/snack.png',
//         'category': 'Makanan',
//         'subCategory': 'Snack',
//         'quantity': 0,
//         'variant_data': {},
//       },
//       {
//         'name': 'Zamur (Gyoza)',
//         'price': 20000,
//         'imagePath': 'assets/images/snack.png',
//         'category': 'Makanan',
//         'subCategory': 'Snack',
//         'quantity': 0,
//         'variant_data': {},
//       },
//       {
//         'name': 'Dimur (Dimsum)',
//         'price': 20000,
//         'imagePath': 'assets/images/snack.png',
//         'category': 'Makanan',
//         'subCategory': 'Snack',
//         'quantity': 0,
//         'variant_data': {},
//       },
//       {
//         'name': 'Bajimut',
//         'price': 20000,
//         'imagePath': 'assets/images/snack.png',
//         'category': 'Makanan',
//         'subCategory': 'Snack',
//         'quantity': 0,
//         'variant_data': {},
//       },
//       {
//         'name': 'Fungi Mix Platter',
//         'price': 30000,
//         'imagePath': 'assets/images/snack.png',
//         'category': 'Makanan',
//         'subCategory': 'Snack',
//         'quantity': 0,
//         'variant_data': {},
//       },

//       // --- MIE INSTAN SERIES ---
//       {
//         'name': 'Mie Instan Single',
//         'price': 8000,
//         'imagePath': 'assets/images/mie.png',
//         'category': 'Makanan',
//         'subCategory': 'Mie',
//         'quantity': 0,
//         'variant_data': {},
//       },
//       {
//         'name': 'Mie Instan Double',
//         'price': 13000,
//         'imagePath': 'assets/images/mie.png',
//         'category': 'Makanan',
//         'subCategory': 'Mie',
//         'quantity': 0,
//         'variant_data': {},
//       },
//       {
//         'name': 'Intel Single',
//         'price': 12000,
//         'imagePath': 'assets/images/mie.png',
//         'category': 'Makanan',
//         'subCategory': 'Mie',
//         'quantity': 0,
//         'variant_data': {},
//       },
//       {
//         'name': 'Intel Double',
//         'price': 17000,
//         'imagePath': 'assets/images/mie.png',
//         'category': 'Makanan',
//         'subCategory': 'Mie',
//         'quantity': 0,
//         'variant_data': {},
//       },
//       // Tambahan dari list Mie
//       {
//         'name': 'Nasi',
//         'price': 5000,
//         'imagePath': 'assets/images/nasi.png',
//         'category': 'Makanan',
//         'subCategory': 'Tambahan',
//         'quantity': 0,
//         'variant_data': {},
//       },
//       {
//         'name': 'Telur',
//         'price': 4000,
//         'imagePath': 'assets/images/snack.png',
//         'category': 'Makanan',
//         'subCategory': 'Tambahan',
//         'quantity': 0,
//         'variant_data': {},
//       },

//       // ==============================================
//       // KATEGORI: MINUMAN
//       // ==============================================

//       // --- COFFEE SERIES ---
//       {
//         'name': 'Americano',
//         'price': 13000, // Harga terendah (H)
//         'imagePath': 'assets/images/kopi.png',
//         'category': 'Minuman',
//         'subCategory': 'Coffee',
//         'quantity': 0,
//         'variant_data': {'H': 13000, 'M': 17000, 'L': 21000},
//       },
//       {
//         'name': 'Kopi Susu',
//         'price': 15000, // Harga terendah (H)
//         'imagePath': 'assets/images/kopi.png',
//         'category': 'Minuman',
//         'subCategory': 'Coffee',
//         'quantity': 0,
//         'variant_data': {'H': 15000, 'M': 18000, 'L': 22000},
//       },
//       {
//         'name': 'Kopi Aren',
//         'price': 20000, // Harga terendah (M)
//         'imagePath': 'assets/images/kopi.png',
//         'category': 'Minuman',
//         'subCategory': 'Coffee',
//         'quantity': 0,
//         'variant_data': {'M': 20000, 'L': 24000},
//       },
//       {
//         'name': 'Butterscotch',
//         'price': 24000, // Harga terendah (M)
//         'imagePath': 'assets/images/kopi.png',
//         'category': 'Minuman',
//         'subCategory': 'Coffee',
//         'quantity': 0,
//         'variant_data': {'M': 24000, 'L': 28000},
//       },
//       {
//         'name': 'Caramel Machiato',
//         'price': 24000, // Harga terendah (M)
//         'imagePath': 'assets/images/kopi.png',
//         'category': 'Minuman',
//         'subCategory': 'Coffee',
//         'quantity': 0,
//         'variant_data': {'M': 24000, 'L': 28000},
//       },
//       {
//         'name': 'Vanila',
//         'price': 22000, // Harga terendah (M)
//         'imagePath': 'assets/images/kopi.png',
//         'category': 'Minuman',
//         'subCategory': 'Coffee',
//         'quantity': 0,
//         'variant_data': {'M': 22000, 'L': 26000},
//       },

//       // --- NON-COFFEE SERIES ---
//       {
//         'name': 'Taro',
//         'price': 19000, // Harga terendah (M)
//         'imagePath': 'assets/images/matcha.png',
//         'category': 'Minuman',
//         'subCategory': 'Non-Coffee',
//         'quantity': 0,
//         'variant_data': {'M': 19000, 'L': 23000},
//       },
//       {
//         'name': 'Red Velvet',
//         'price': 20000, // Harga terendah (M)
//         'imagePath': 'assets/images/matcha.png',
//         'category': 'Minuman',
//         'subCategory': 'Non-Coffee',
//         'quantity': 0,
//         'variant_data': {'M': 20000, 'L': 24000},
//       },
//       {
//         'name': 'Coklat',
//         'price': 20000, // Harga terendah (M)
//         'imagePath': 'assets/images/matcha.png',
//         'category': 'Minuman',
//         'subCategory': 'Non-Coffee',
//         'quantity': 0,
//         'variant_data': {'M': 20000, 'L': 24000},
//       },
//       {
//         'name': 'Strawberry',
//         'price': 19000, // Harga terendah (M)
//         'imagePath': 'assets/images/teh.png',
//         'category': 'Minuman',
//         'subCategory': 'Non-Coffee',
//         'quantity': 0,
//         'variant_data': {'M': 19000, 'L': 23000},
//       },
//       {
//         'name': 'Thai Tea',
//         'price': 19000, // Harga terendah (M)
//         'imagePath': 'assets/images/teh.png',
//         'category': 'Minuman',
//         'subCategory': 'Non-Coffee',
//         'quantity': 0,
//         'variant_data': {'M': 19000, 'L': 23000},
//       },
//       {
//         'name': 'Green Tea',
//         'price': 19000, // Harga terendah (M)
//         'imagePath': 'assets/images/matcha.png',
//         'category': 'Minuman',
//         'subCategory': 'Non-Coffee',
//         'quantity': 0,
//         'variant_data': {'M': 19000, 'L': 23000},
//       },
//     ];

//     // 3. Eksekusi Batch Insert
//     for (var p in products) {
//       DocumentReference ref = db.collection(_colProducts).doc();
//       batch.set(ref, p);
//     }

//     await batch.commit();
//     print(
//       "✅ Seed Data Fungi Bites Berhasil! ${products.length} produk ditambahkan.",
//     );
//   }
// }
