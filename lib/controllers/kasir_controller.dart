import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../data/db_helper.dart';
import '../models/menu_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KasirController extends GetxController {
  // === 1. VARIABEL STATE ===
  var menuData = <MenuCategory>[].obs;
  var isLoading = true.obs;
  var tableTierList = <Map<String, dynamic>>[].obs;
  var isSyncing = false.obs; // Untuk loading indicator
  var selectedCategoryIndex = 0.obs;
  var selectedSubCategoryIndex = 0.obs;
  var searchText = ''.obs;

  var activeTransactions =
      <Map<String, dynamic>>[].obs; // List Pesanan Berjalan
  final TextEditingController tableController =
      TextEditingController(); // Kontroller Input Meja
  var cartItems = <Map<String, dynamic>>[].obs;
  final TextEditingController nameController =
      TextEditingController(); // [BARU]

  @override
  void onInit() {
    super.onInit();
    loadData();
    loadActiveTransactions();
  }

  Future<List<Map<String, dynamic>>> getOrderDetails(
    String transactionId,
  ) async {
    return await DatabaseHelper.instance.getTransactionItems(transactionId);
  }

  // 3. FUNGSI BARU: LANJUTKAN ORDER (AUTO FILL)
  void resumeOrder(String table, String name) {
    tableController.text = table; // Isi otomatis No Meja
    nameController.text = name; // Isi otomatis Nama
    Get.back(); // Kembali ke halaman Kasir
  }

  void loadActiveTransactions() async {
    activeTransactions.value = await DatabaseHelper.instance
        .getActiveTransactions();
  }

  Future<void> processTransaction({
    required String customerName,
    required String tableNumber,
    required String orderType,
    required String paymentMethod,
    required bool isRunningOrder,
  }) async {
    if (cartItems.isEmpty) return;

    try {
      await DatabaseHelper.instance.saveOrder(
        cartItems: cartItems,
        customerName: customerName,
        tableNumber: tableNumber,
        orderType: orderType,
        paymentMethod: paymentMethod,
        isRunningOrder: isRunningOrder,
      );

      await resetAll();
      tableController.clear();
      nameController.clear();
      loadActiveTransactions();

      // TIDAK ADA NOTIFIKASI SUKSES
    } catch (e) {
      print(
        "Error processTransaction: $e",
      ); // Ganti notif error jadi print console
    }
  }

  Future<void> payRunningOrder(String transactionId, String method) async {
    // 1. Update Database
    await DatabaseHelper.instance.checkoutOpenBill(transactionId, method);

    // 2. Refresh List
    loadActiveTransactions();

    // Note: Error dilempar otomatis ke UI (catch block di widget)
  }

  // === 3. SYNC FIREBASE (LOGIKA FIX) ===
  Future<void> syncDataToFirebase() async {
    try {
      isSyncing.value = true;
      final firestore = FirebaseFirestore.instance;
      int successCount = 0;
      int cancelCount = 0;

      // ===========================================
      // BAGIAN 1: UPLOAD TRANSAKSI SUKSES
      // ===========================================
      final List<Map<String, dynamic>> unsyncedRows = await DatabaseHelper
          .instance
          .getUnsyncedTransactions();

      if (unsyncedRows.isNotEmpty) {
        // Grouping Data
        Map<String, List<Map<String, dynamic>>> grouped = {};
        for (var row in unsyncedRows) {
          String trId = row['transaction_id'];
          if (!grouped.containsKey(trId)) grouped[trId] = [];
          grouped[trId]!.add(row);
        }

        for (String trId in grouped.keys) {
          List<Map<String, dynamic>> items = grouped[trId]!;
          var header = items.first;

          Map<String, dynamic> strukData = {
            'transaction_id': trId,
            'customer_name': header['customer_name'],
            'table_number': header['table_number'],
            'payment_method': header['payment_method'],
            'order_type': header['order_type'],
            'transaction_date': header['transaction_date'],
            'total_bill': items.fold(
              0,
              (sum, item) => sum + (item['total_price'] as int),
            ),
            'items': items
                .map(
                  (item) => {
                    'product_name': item['product_name'],
                    'qty': item['qty'],
                    'variant': item['variant'] ?? '-',
                    'price': item['product_price'],
                    'discount': item['discount'] ?? 0,
                    'total': item['total_price'],
                  },
                )
                .toList(),
            'uploaded_at': FieldValue.serverTimestamp(),
          };

          // Upload ke koleksi 'transaksi'
          await firestore.collection('transaksi').doc(trId).set(strukData);
          await DatabaseHelper.instance.markTransactionAsSynced(trId);
          successCount++;
        }
      }

      // ===========================================
      // BAGIAN 2: UPLOAD DATA PEMBATALAN (VOID)
      // ===========================================
      final List<Map<String, dynamic>> unsyncedCancels = await DatabaseHelper
          .instance
          .getUnsyncedCancellations();

      if (unsyncedCancels.isNotEmpty) {
        for (var row in unsyncedCancels) {
          // Upload ke koleksi 'pembatalan'
          await firestore.collection('pembatalan').add({
            'transaction_id': row['transaction_id'],
            'product_name': row['product_name'],
            'qty': row['qty'],
            'total_lost': row['total_lost'],
            'reason': row['reason'],
            'cancel_date': row['cancel_date'],
            'uploaded_at': FieldValue.serverTimestamp(),
          });

          // Tandai synced di lokal
          await DatabaseHelper.instance.markCancellationAsSynced(row['id']);
          cancelCount++;
        }
      }

      // ===========================================
      // FEEDBACK USER
      // ===========================================
      if (successCount == 0 && cancelCount == 0) {
        showNotif("Info", "Semua data (Transaksi & Void) sudah terkirim.");
      } else {
        showNotif(
          "Sync Selesai",
          "Berhasil upload: $successCount Transaksi, $cancelCount Void.",
        );
      }
    } catch (e) {
      showNotif("Gagal Kirim", "Cek internet. Error: $e", isError: true);
      print(e);
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> voidRunningOrder(String transactionId, String reason) async {
    try {
      await DatabaseHelper.instance.cancelTransaction(transactionId, reason);

      // Refresh list agar pesanan hilang dari layar
      loadActiveTransactions();

      Get.back(); // Tutup Dialog
    } catch (e) {
      showNotif("Error", "Gagal membatalkan: $e", isError: true);
    }
  }

  void showNotif(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      maxWidth: 300,
      margin: const EdgeInsets.all(10),
      backgroundColor: isError
          ? Colors.red.withOpacity(0.9)
          : Colors.green.withOpacity(0.9),
      colorText: Colors.white,
      borderRadius: 12,
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
      ),
      duration: const Duration(seconds: 2),
    );
  }

  int get totalPrice {
    int total = 0;
    for (var item in cartItems) {
      Product p = item['product'];
      int finalPrice = item['price_used'] ?? p.price;
      int qty = item['qty'];
      int discount = item['discount'] ?? 0; // Ambil nilai diskon

      // Rumus: (Harga - Diskon) * Jumlah
      int totalPerItem = (finalPrice - discount) * qty;
      total += totalPerItem;
    }
    return total;
  }

  // Logika Menampilkan Produk (Search vs Filter Kategori)
  List<Product> get displayedProducts {
    if (searchText.value.isNotEmpty) {
      List<Product> results = [];
      for (var cat in menuData) {
        for (var sub in cat.subCategories) {
          for (var p in sub.products) {
            if (p.name.toLowerCase().contains(searchText.value.toLowerCase()))
              results.add(p);
          }
        }
      }
      return results;
    }
    if (menuData.isEmpty) return [];
    if (selectedCategoryIndex.value >= menuData.length)
      selectedCategoryIndex.value = 0;
    var currentCat = menuData[selectedCategoryIndex.value];
    if (selectedSubCategoryIndex.value >= currentCat.subCategories.length)
      selectedSubCategoryIndex.value = 0;
    if (currentCat.subCategories.isEmpty) return [];
    return currentCat.subCategories[selectedSubCategoryIndex.value].products;
  }

  void loadData() async {
    isLoading.value = true;
    final List<Product> rawProducts = await DatabaseHelper.instance
        .getAllProducts();
    // Logic grouping sama kayak v7/v8...
    Map<String, Map<String, List<Product>>> grouped = {};
    for (var p in rawProducts) {
      if (cartItems.isEmpty) p.quantity = 0;
      if (!grouped.containsKey(p.category)) grouped[p.category] = {};
      if (!grouped[p.category]!.containsKey(p.subCategory))
        grouped[p.category]![p.subCategory] = [];
      grouped[p.category]![p.subCategory]!.add(p);
    }
    List<MenuCategory> tempData = [];
    grouped.forEach((catName, subMap) {
      List<SubCategory> tempSubs = [];
      subMap.forEach(
        (subName, pList) =>
            tempSubs.add(SubCategory(name: subName, products: pList)),
      );
      tempData.add(MenuCategory(name: catName, subCategories: tempSubs));
    });
    menuData.value = tempData;
    isLoading.value = false;
  }

  void changeCategory(int i) {
    selectedCategoryIndex.value = i;
    selectedSubCategoryIndex.value = 0;
  }

  // === 5. CART LOGIC ===
  void addToCart(Product product, String variant, int priceUsed) {
    int index = cartItems.indexWhere(
      (item) => item['product'].id == product.id && item['variant'] == variant,
    );

    if (index != -1) {
      var currentItem = cartItems[index];
      currentItem['qty'] = currentItem['qty'] + 1;
      cartItems[index] = currentItem;
    } else {
      cartItems.add({
        'product': product,
        'qty': 1,
        'variant': variant,
        'price_used': priceUsed,
        'discount': 0, // <--- PENTING: Default Diskon 0
      });
    }
    product.quantity++;
    menuData.refresh();
  }

  void updateItemDiscount(int index, int discountAmount) {
    var item = cartItems[index];
    int price = item['price_used'] ?? item['product'].price;

    // Validasi: Diskon tidak boleh lebih besar dari harga
    if (discountAmount > price) {
      showNotif("Gagal", "Diskon melebihi harga produk!", isError: true);
      return;
    }

    item['discount'] = discountAmount;
    cartItems[index] = item;

    cartItems.refresh(); // Update UI Total Harga
    Get.back(); // Tutup Dialog
    showNotif("Sukses", "Diskon diterapkan.");
  }

  void removeFromCart(Product product) {
    int index = cartItems.lastIndexWhere(
      (item) => item['product'].id == product.id,
    );
    if (index != -1) {
      var item = cartItems[index];
      if (item['qty'] > 1) {
        item['qty'] = item['qty'] - 1;
        cartItems[index] = item;
      } else {
        cartItems.removeAt(index);
      }
      if (product.quantity > 0) product.quantity--;
      menuData.refresh();
    }
  }

  Future<void> resetAll() async {
    cartItems.clear();

    // BERSIHKAN INPUT TEKS JUGA
    tableController.clear();
    nameController.clear();

    // Reset qty di menu
    for (var cat in menuData) {
      for (var sub in cat.subCategories) {
        for (var p in sub.products) {
          p.quantity = 0;
        }
      }
    }
    menuData.refresh();
  }

  Future<void> processPayment(
    String name,
    String table,
    String orderType,
    String paymentMethod,
  ) async {
    await DatabaseHelper.instance.saveTransaction(
      cartItems,
      name,
      table,
      orderType,
      paymentMethod,
    );
    await resetAll();
    // NOTIFIKASI BARU
    showNotif("Sukses", "Transaksi Berhasil Disimpan");
  }

  Future<void> cancelOrder(String reason) async {
    await DatabaseHelper.instance.saveCancellation(cartItems, reason);
    await resetAll();
    // NOTIFIKASI BARU
    showNotif("Info", "Transaksi Dibatalkan", isError: true);
  }

  Future<void> deleteHistoryItem(
    int id,
    Map<String, dynamic> item,
    String reason,
  ) async {
    try {
      await DatabaseHelper.instance.moveOrderToCancel(id, item, reason);
      await loadStatistics();
      Get.back();
      // NOTIFIKASI BARU
      showNotif("Sukses", "Data dipindah ke Batal");
    } catch (e) {
      showNotif("Error", "Gagal menghapus: $e", isError: true);
    }
  }

  Future<void> addProduct(
    String name,
    String basePrice,
    String category,
    String sub,
    String imagePath,
    Map<String, int> variantPrices,
  ) async {
    try {
      int priceInt = int.tryParse(basePrice) ?? 0;
      Product newProduct = Product(
        name: name,
        price: priceInt, // Harga dasar (Tampilan)
        imagePath: imagePath.isEmpty ? 'assets/images/nasi.png' : imagePath,
        category: category,
        subCategory: sub,
        variantPrices: variantPrices, // Simpan Map Harga Varian
      );

      await DatabaseHelper.instance.insertProduct(newProduct);
      loadData();
      Get.back();
      showNotif("Sukses", "Menu berhasil ditambah");
    } catch (e) {
      showNotif("Error", "Gagal: $e", isError: true);
    }
  }

  Future<void> editProduct(
    int id,
    String name,
    String basePrice,
    String category,
    String sub,
    String imagePath,
    Map<String, int> variantPrices,
  ) async {
    try {
      int priceInt = int.tryParse(basePrice) ?? 0;
      Product updatedProduct = Product(
        id: id,
        name: name,
        price: priceInt,
        imagePath: imagePath,
        category: category,
        subCategory: sub,
        variantPrices: variantPrices,
      );

      await DatabaseHelper.instance.updateProduct(updatedProduct);
      loadData();
      Get.back();
      showNotif("Sukses", "Menu berhasil diupdate");
    } catch (e) {
      showNotif("Error", "Gagal: $e", isError: true);
    }
  }

  Future<void> deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    loadData();
    // NOTIFIKASI BARU
    showNotif("Info", "Menu dihapus", isError: true);
  }

  Future<String?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }

  Future<void> loadStatistics() async {
    final tiers = await DatabaseHelper.instance.getTableTierList();
    tableTierList.value = tiers;
  }

  List<String> getExistingCategories() {
    return menuData.map((e) => e.name).toSet().toList(); // toSet agar unik
  }

  // Ambil Sub-Kategori berdasarkan Kategori yang dipilih
  List<String> getExistingSubCategories(String categoryName) {
    // Cari kategori yang namanya cocok
    var category = menuData.firstWhereOrNull(
      (e) => e.name.toLowerCase() == categoryName.toLowerCase(),
    );

    if (category != null) {
      return category.subCategories.map((e) => e.name).toSet().toList();
    }
    return []; // Return kosong jika kategori baru/tidak ditemukan
  }
}
