import 'package:flutter/material.dart';
import 'package:fungi_casheer/data/FirestoreHelper.dart';
// import 'package:fungi_casheer/service/firestore_seeder.dart';
import 'package:get/get.dart';
// Pastikan import ini sesuai dengan struktur folder Anda
import '../models/menu_model.dart';

class KasirController extends GetxController {
  // ===========================================================================
  // 1. STATE VARIABLES
  // ===========================================================================

  // Data Menu & Kategori
  var menuData = <MenuCategory>[].obs;
  var isLoading = true.obs;
  var isSyncing = false.obs;

  // Input Kasir
  final TextEditingController tableController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  // Keranjang Belanja
  var cartItems = <Map<String, dynamic>>[].obs;

  // Filter & Search Menu
  var selectedCategoryIndex = 0.obs;
  var selectedSubCategoryIndex = 0.obs;
  var searchText = ''.obs;

  // List Bill Gantung (Pending Orders)
  var activeTransactions = <Map<String, dynamic>>[].obs;

  // ===========================================================================
  // 2. INITIALIZATION
  // ===========================================================================
  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  Future<void> _initData() async {
    try {
      // await FirestoreSeeder.seedProducts();
      loadData();
      loadActiveTransactions();
    } catch (e) {
      showNotif("Error", "$e", isError: true);
    }
  }

  // ===========================================================================
  // 3. LOAD DATA
  // ===========================================================================

  /// Mengambil data produk dari Firebase dan mengelompokkannya
  void loadData() async {
    isLoading.value = true;
    try {
      final List<Product> rawProducts = await FirestoreHelper.instance
          .getAllProducts();

      // Logika Grouping (Kategori -> Sub -> Produk)
      Map<String, Map<String, List<Product>>> grouped = {};
      for (var p in rawProducts) {
        if (cartItems.isEmpty)
          p.quantity = 0; // Reset counter UI jika cart kosong

        if (!grouped.containsKey(p.category)) grouped[p.category] = {};
        if (!grouped[p.category]!.containsKey(p.subCategory)) {
          grouped[p.category]![p.subCategory] = [];
        }
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
    } catch (e) {
      showNotif("Error", "Gagal memuat menu: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  /// Mengambil daftar Bill Gantung (Running Orders)
  void loadActiveTransactions() async {
    try {
      activeTransactions.value = await FirestoreHelper.instance
          .getActiveTransactions();
    } catch (e) {
      print("Error load active trx: $e");
    }
  }

  /// Mengambil detail item dari sebuah transaksi
  Future<List<Map<String, dynamic>>> getOrderDetails(
    String transactionId,
  ) async {
    return await FirestoreHelper.instance.getTransactionItems(transactionId);
  }

  // ===========================================================================
  // 4. TRANSACTION LOGIC (PENDING VS PAID)
  // ===========================================================================

  /// FITUR 1: SIMPAN BILL (PENDING)
  /// Data masuk Firebase tapi statusnya 'Open'. Tidak muncul di Laporan.
  Future<void> saveAsPending() async {
    if (cartItems.isEmpty) {
      showNotif("Gagal", "Keranjang kosong!", isError: true);
      return;
    }
    if (tableController.text.trim().isEmpty) {
      showNotif(
        "Gagal",
        "Nomor Meja wajib diisi untuk Bill Gantung!",
        isError: true,
      );
      return;
    }

    await processTransaction(
      paymentMethod: "PENDING",
      isRunningOrder: true, // TRUE = Masuk Bill Gantung
      orderType: "Dine In", // Default Dine In kalau pending
    );
  }

  /// FITUR 2: BAYAR LANGSUNG (LUNAS)
  /// Data masuk Firebase status 'Paid'. Langsung muncul di Laporan.
  Future<void> payNow(String method, String type) async {
    if (cartItems.isEmpty) {
      showNotif("Gagal", "Keranjang kosong!", isError: true);
      return;
    }
    await processTransaction(
      paymentMethod: method, // Tunai / QRIS
      isRunningOrder: false, // FALSE = Langsung Lunas
      orderType: type,
    );
  }

  /// FITUR 3: MELUNASI BILL GANTUNG
  /// Mengubah status transaksi dari 'Open' ke 'Paid'.
  /// Data pindah dari Active Order ke Laporan.
  Future<void> payRunningOrder(String transactionId, String method) async {
    try {
      isLoading.value = true;
      // Update di Firestore: is_running_order jadi 0, status jadi Paid
      await FirestoreHelper.instance.checkoutOpenBill(transactionId, method);

      loadActiveTransactions(); // Refresh agar hilang dari list active

      Get.back(); // Tutup dialog bayar jika ada
      showNotif("Lunas", "Bill berhasil dibayar dan masuk Laporan.");
    } catch (e) {
      showNotif("Error", "Gagal bayar: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  /// FUNGSI INTERNAL: Proses Simpan ke Firestore
  /// FUNGSI UTAMA PROSES TRANSAKSI
  Future<void> processTransaction({
    // <--- HAPUS garis bawah
    required String paymentMethod,
    required bool isRunningOrder,
    required String orderType,
    // Tambahkan parameter optional jika UI Anda mengirimkannya manual
    String? customerName,
    String? tableNumber,
  }) async {
    try {
      isLoading.value = true;

      // Gunakan data dari parameter JIKA ADA, kalau tidak ambil dari Controller Text
      String custName =
          customerName ??
          (nameController.text.isEmpty ? "Pelanggan" : nameController.text);
      String tableNum =
          tableNumber ??
          (tableController.text.isEmpty ? "-" : tableController.text);

      await FirestoreHelper.instance.saveOrder(
        cartItems: cartItems,
        customerName: custName,
        tableNumber: tableNum,
        orderType: orderType,
        paymentMethod: paymentMethod,
        isRunningOrder: isRunningOrder,
      );

      await resetAll(); // Bersihkan keranjang UI
      loadActiveTransactions(); // Refresh List Bill Gantung

      String msg = isRunningOrder
          ? "Bill disimpan (Pending)"
          : "Pembayaran Berhasil!";
      showNotif("Sukses", msg);

      if (!isRunningOrder) Get.closeAllSnackbars();
    } catch (e) {
      showNotif("Gagal", "Error transaksi: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }
  // ===========================================================================
  // 5. VOID / PEMBATALAN
  // ===========================================================================

  /// Membatalkan (Menghapus) seluruh Bill Gantung
  Future<void> voidRunningOrder(String transactionId, String reason) async {
    try {
      await FirestoreHelper.instance.cancelTransaction(transactionId, reason);
      loadActiveTransactions();
      Get.back(); // Tutup dialog
      showNotif("Void Sukses", "Transaksi dibatalkan permanen.", isError: true);
    } catch (e) {
      showNotif("Error", "Gagal void: $e", isError: true);
    }
  }

  /// Menghapus SATU ITEM dari Bill yang sudah tersimpan
  Future<void> deleteHistoryItem(
    String docId,
    Map<String, dynamic> item,
    String reason,
  ) async {
    try {
      isLoading.value = true;
      // Panggil Helper dengan 3 Parameter
      await FirestoreHelper.instance.moveOrderToCancellation(
        docId,
        item,
        reason,
      );
      showNotif("Sukses", "Item dihapus dari transaksi.");

      // Opsional: Jika Anda memanggil ini dari ActiveOrderPage, refresh listnya
      // loadActiveTransactions();
    } catch (e) {
      showNotif("Error", "Gagal hapus item: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // 6. CART LOGIC (KERANJANG)
  // ===========================================================================

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
        'discount': 0,
      });
    }
    product.quantity++;
    menuData.refresh();
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

  void updateItemDiscount(int index, int discountAmount) {
    var item = cartItems[index];
    int price = item['price_used'] ?? item['product'].price;

    if (discountAmount > price) {
      showNotif("Gagal", "Diskon melebihi harga!", isError: true);
      return;
    }
    item['discount'] = discountAmount;
    cartItems[index] = item;
    cartItems.refresh();
    Get.back();
    showNotif("Sukses", "Diskon diterapkan.");
  }

  int get totalPrice {
    int total = 0;
    for (var item in cartItems) {
      int price = item['price_used'];
      int qty = item['qty'];
      int discount = item['discount'] ?? 0;
      total += (price - discount) * qty;
    }
    return total;
  }

  /// Reset UI (Batalkan input sebelum disimpan)
  void cancelOrder(String reason) {
    print("Reset UI. Alasan: $reason");
    resetAll();
    showNotif("Info", "Input direset", isError: true);
  }

  Future<void> resetAll() async {
    cartItems.clear();
    tableController.clear();
    nameController.clear();
    for (var cat in menuData) {
      for (var sub in cat.subCategories) {
        for (var p in sub.products) p.quantity = 0;
      }
    }
    menuData.refresh();
  }

  // ===========================================================================
  // 7. PRODUCT MANAGEMENT (CRUD)
  // ===========================================================================

  Future<void> addProduct(
    String name,
    String basePrice,
    String cat,
    String sub,
    String imgPath,
    Map<String, int> variants,
  ) async {
    try {
      int price = int.tryParse(basePrice) ?? 0;
      Product newProduct = Product(
        name: name,
        price: price,
        imagePath: imgPath.isEmpty ? 'assets/images/nasi.png' : imgPath,
        category: cat,
        subCategory: sub,
        variantPrices: variants,
      );
      await FirestoreHelper.instance.insertProduct(newProduct);
      loadData();
      Get.back();
      showNotif("Sukses", "Menu ditambah");
    } catch (e) {
      showNotif("Error", "$e", isError: true);
    }
  }

  Future<void> editProduct(
    String docId,
    String name,
    String basePrice,
    String cat,
    String sub,
    String imgPath,
    Map<String, int> variants,
  ) async {
    try {
      int price = int.tryParse(basePrice) ?? 0;
      Product updated = Product(
        name: name,
        price: price,
        imagePath: imgPath,
        category: cat,
        subCategory: sub,
        variantPrices: variants,
      );
      await FirestoreHelper.instance.updateProduct(updated, docId);
      loadData();
      Get.back();
      showNotif("Sukses", "Menu diupdate");
    } catch (e) {
      showNotif("Error", "$e", isError: true);
    }
  }

  Future<void> deleteProduct(String docId) async {
    try {
      await FirestoreHelper.instance.deleteProduct(docId);
      loadData();
      showNotif("Info", "Menu dihapus", isError: true);
    } catch (e) {
      showNotif("Error", "$e", isError: true);
    }
  }

  // Future<String?> pickImage() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  //   return image?.path;
  // }

  // ===========================================================================
  // 8. UI HELPERS
  // ===========================================================================

  /// Mengambil data dari Bill Gantung untuk ditambahkan menu baru
  void resumeOrder(String table, String name) {
    tableController.text = table;
    nameController.text = name;
    Get.back(); // Tutup halaman active order
    Get.snackbar("Lanjut Order", "Silakan tambah menu untuk Meja $table");
  }

  void changeCategory(int i) {
    selectedCategoryIndex.value = i;
    selectedSubCategoryIndex.value = 0;
  }

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

  List<String> getExistingCategories() =>
      menuData.map((e) => e.name).toSet().toList();

  List<String> getExistingSubCategories(String categoryName) {
    var category = menuData.firstWhereOrNull(
      (e) => e.name.toLowerCase() == categoryName.toLowerCase(),
    );
    if (category != null)
      return category.subCategories.map((e) => e.name).toSet().toList();
    return [];
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
}
