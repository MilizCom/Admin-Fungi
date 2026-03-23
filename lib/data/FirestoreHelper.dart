import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/menu_model.dart';

class FirestoreHelper {
  static final FirestoreHelper instance = FirestoreHelper._init();
  FirestoreHelper._init();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // === KONFIGURASI NAMA COLLECTION (ARSITEKTUR BARU) ===
  final String _colProducts = 'products';

  // 1. TEMPAT BILL GANTUNG (PENDING)
  final String _colPending = 'orders';

  // 2. TEMPAT BILL LUNAS (LAPORAN)
  final String _colReports = 'transaksi';

  final String _colCancellations = 'cancellations';

  // ===========================================================================
  // 1. DATA LAPORAN (BACA DARI COLLECTION 'TRANSAKSI')
  // ===========================================================================

  Future<List<Map<String, dynamic>>> getTransactionsByCustomRange(
    DateTime start,
    DateTime end,
  ) async {
    // Ambil data HANYA dari collection 'transaksi' (karena yang lunas pindah ke sini)
    var snapshot = await _db
        .collection(_colReports)
        .orderBy('transaction_date', descending: true)
        .get();

    List<Map<String, dynamic>> filteredResults = [];
    DateFormat formatFirebase = DateFormat("yyyy-MM-dd HH:mm:ss");

    for (var doc in snapshot.docs) {
      var data = doc.data();
      String? dateString = data['transaction_date'];

      if (dateString != null) {
        try {
          DateTime transDate = formatFirebase.parse(dateString);

          bool isAfterStart = transDate.isAfter(
            start.subtract(const Duration(seconds: 1)),
          );
          bool isBeforeEnd = transDate.isBefore(
            end.add(const Duration(seconds: 1)),
          );

          if (isAfterStart && isBeforeEnd) {
            data['id'] = doc.id;
            data['total_bill'] = (data['total_bill'] ?? 0).toInt();
            filteredResults.add(data);
          }
        } catch (e) {
          print("Error parse date: $e");
        }
      }
    }
    return filteredResults;
  }

  // ===========================================================================
  // 2. DATA BILL GANTUNG (BACA DARI COLLECTION 'ORDERS')
  // ===========================================================================

  Future<List<Map<String, dynamic>>> getActiveTransactions() async {
    // Ambil semua data dari collection 'orders'
    // (Tidak perlu filter is_running_order lagi karena collection ini KHUSUS pending)
    var snapshot = await _db
        .collection(_colPending)
        .orderBy('transaction_date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      var data = doc.data();
      return {
        'transaction_id': data['transaction_id'],
        'table_number': data['table_number'],
        'customer_name': data['customer_name'],
        'total_bill': (data['total_bill'] ?? 0).toInt(),
        'last_update': data['transaction_date'],
        'is_running_order': 1,
      };
    }).toList();
  }

  Future<String?> getOpenTransactionId(String tableNumber) async {
    var snapshot = await _db
        .collection(_colPending) // Cari di orders
        .where('table_number', isEqualTo: tableNumber)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data()['transaction_id'];
    }
    return null;
  }

  // ===========================================================================
  // 3. SIMPAN ORDER (MEMISAHKAN ORDERS VS TRANSAKSI)
  // ===========================================================================

  Future<void> saveOrder({
    required List<Map<String, dynamic>> cartItems,
    required String customerName,
    required String tableNumber,
    required String orderType,
    required String paymentMethod,
    required bool isRunningOrder,
  }) async {
    final String now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    String transactionId = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());

    // Cek ID lama jika Pending (Hanya cari di orders)
    if (isRunningOrder) {
      String? existingId = await getOpenTransactionId(tableNumber);
      if (existingId != null) {
        transactionId = existingId;
      }
    }

    int totalBill = 0;
    List<Map<String, dynamic>> itemsToSave = [];

    for (var item in cartItems) {
      Product p = item['product'];
      int finalPrice = item['price_used'] ?? p.price;
      int qty = item['qty'];
      int discount = item['discount'] ?? 0;
      int totalPerItem = (finalPrice - discount) * qty;
      totalBill += totalPerItem;

      itemsToSave.add({
        'product_name': p.name,
        'price': finalPrice,
        'qty': qty,
        'variant': item['variant'] ?? '-',
        'discount': discount,
        'total': totalPerItem,
      });
    }

    Map<String, dynamic> dataToSave = {
      'transaction_id': transactionId,
      'customer_name': customerName,
      'table_number': tableNumber,
      'order_type': orderType,
      'payment_method': paymentMethod,
      'transaction_date': now,
      'total_bill': totalBill,
      'items': itemsToSave,
      'uploaded_at': FieldValue.serverTimestamp(),
    };

    // LOGIKA PERCABANGAN COLLECTION
    if (isRunningOrder) {
      // Jika Pending -> Masuk ke 'orders'
      dataToSave['is_running_order'] = 1;
      await _db.collection(_colPending).add(dataToSave);
    } else {
      // Jika Langsung Lunas -> Masuk ke 'transaksi'
      dataToSave['is_running_order'] = 0;
      await _db.collection(_colReports).add(dataToSave);
    }
  }

  // ===========================================================================
  // 4. CHECKOUT (PINDAHKAN DARI 'ORDERS' KE 'TRANSAKSI')
  // ===========================================================================

  Future<void> checkoutOpenBill(String transactionId, String realMethod) async {
    // 1. Cari dokumen di collection 'orders'
    var snapshot = await _db
        .collection(_colPending)
        .where('transaction_id', isEqualTo: transactionId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return; // Data tidak ditemukan

    var doc = snapshot.docs.first;
    var data = doc.data();

    // 2. Update Data Pembayaran
    data['payment_method'] = realMethod;
    data['is_running_order'] = 0;

    // Update tanggal ke waktu bayar (Opsional, agar laporan sesuai jam bayar)
    data['transaction_date'] = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());

    // 3. GUNAKAN TRANSACTION AGAR ATOMIC (Aman)
    await _db.runTransaction((transaction) async {
      // a. Buat dokumen baru di 'transaksi'
      DocumentReference newRef = _db.collection(_colReports).doc();
      transaction.set(newRef, data);

      // b. Hapus dokumen lama di 'orders'
      transaction.delete(doc.reference);
    });
  }

  // ===========================================================================
  // 5. HELPER LAIN (Detail, Void, Dashboard)
  // ===========================================================================

  Future<List<Map<String, dynamic>>> getTransactionItems(
    String transactionId,
  ) async {
    // Coba cari di 'orders' dulu (Siapa tau user buka detail Bill Gantung)
    var snapOrder = await _db
        .collection(_colPending)
        .where('transaction_id', isEqualTo: transactionId)
        .limit(1)
        .get();

    if (snapOrder.docs.isNotEmpty) {
      var data = snapOrder.docs.first.data();
      List<dynamic> items = data['items'] ?? [];
      return items.map((e) => e as Map<String, dynamic>).toList();
    }

    // Kalau tidak ada di orders, cari di 'transaksi' (Riwayat Laporan)
    var snapTrx = await _db
        .collection(_colReports)
        .where('transaction_id', isEqualTo: transactionId)
        .limit(1)
        .get();

    if (snapTrx.docs.isNotEmpty) {
      var data = snapTrx.docs.first.data();
      List<dynamic> items = data['items'] ?? [];
      return items.map((e) => e as Map<String, dynamic>).toList();
    }

    return [];
  }

  // VOID (Hapus Permanen)
  // Cek di kedua collection untuk jaga-jaga
  Future<void> cancelTransaction(String transactionId, String reason) async {
    WriteBatch batch = _db.batch();
    String now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // Fungsi helper kecil untuk proses void
    Future<void> processVoid(String collection) async {
      var snapshot = await _db
          .collection(collection)
          .where('transaction_id', isEqualTo: transactionId)
          .get();
      for (var doc in snapshot.docs) {
        // Arsip ke Cancellations
        DocumentReference cancelRef = _db.collection(_colCancellations).doc();
        batch.set(cancelRef, {
          ...doc.data(),
          'reason': "$reason (Void Full)",
          'cancel_date': now,
          'original_collection': collection, // Info tambahan
        });
        // Hapus
        batch.delete(doc.reference);
      }
    }

    await processVoid(_colPending); // Cek di orders
    await processVoid(_colReports); // Cek di transaksi

    await batch.commit();
  }

  // Void Partial (Hapus 1 Item)
  // Kita asumsikan partial void dilakukan di Active Order (Pending)
  // Tapi code ini support keduanya.
  Future<void> moveOrderToCancellation(
    String docId,
    Map<String, dynamic> itemToRemove,
    String reason,
  ) async {
    // Cek dokumen ada di collection mana? (Kita coba get dari Orders dulu)
    DocumentReference docRef = _db.collection(_colPending).doc(docId);
    DocumentSnapshot docSnap = await docRef.get();

    if (!docSnap.exists) {
      // Kalau gak ada di orders, coba di transaksi
      docRef = _db.collection(_colReports).doc(docId);
      docSnap = await docRef.get();
    }

    if (!docSnap.exists) return; // Gak ketemu di mana-mana

    Map<String, dynamic> data = docSnap.data() as Map<String, dynamic>;
    List<dynamic> currentItems = data['items'] ?? [];
    List<dynamic> updatedItems = [];
    bool found = false;
    int deducted = 0;

    for (var item in currentItems) {
      if (!found &&
          item['product_name'] == itemToRemove['product_name'] &&
          item['qty'] == itemToRemove['qty']) {
        found = true;
        deducted = (item['total'] as num).toInt();

        await _db.collection(_colCancellations).add({
          'transaction_id': data['transaction_id'],
          'product_name': item['product_name'],
          'qty': item['qty'],
          'total_lost': deducted,
          'reason': reason,
          'cancel_date': DateFormat(
            'yyyy-MM-dd HH:mm:ss',
          ).format(DateTime.now()),
        });
      } else {
        updatedItems.add(item);
      }
    }

    if (updatedItems.isEmpty) {
      await docRef.delete();
    } else {
      int newTotal = (data['total_bill'] ?? 0) - deducted;
      await docRef.update({'items': updatedItems, 'total_bill': newTotal});
    }
  }

  // Dashboard - Produk Terlaris (Ambil dari 'transaksi' saja)
  Future<List<Map<String, dynamic>>> getTopSellingProducts() async {
    var snapshot = await _db
        .collection(_colReports)
        .orderBy('transaction_date', descending: true)
        .limit(100)
        .get();
    Map<String, int> productCount = {};

    for (var doc in snapshot.docs) {
      var data = doc.data();
      List<dynamic> items = data['items'] ?? [];
      for (var item in items) {
        String name = item['product_name'] ?? '?';
        int qty = (item['qty'] ?? 0).toInt();
        productCount[name] = (productCount[name] ?? 0) + qty;
      }
    }
    List<Map<String, dynamic>> result = productCount.entries
        .map((e) => {'product_name': e.key, 'total_qty': e.value})
        .toList();
    result.sort((a, b) => b['total_qty'].compareTo(a['total_qty']));
    return result.take(5).toList();
  }

  // Dashboard - Meja Populer (Ambil dari 'transaksi' saja)
  Future<List<Map<String, dynamic>>> getTableTierList() async {
    var snapshot = await _db
        .collection(_colReports)
        .orderBy('transaction_date', descending: true)
        .limit(100)
        .get();
    Map<String, int> tableCount = {};

    for (var doc in snapshot.docs) {
      var data = doc.data();
      String table = data['table_number'] ?? '-';
      tableCount[table] = (tableCount[table] ?? 0) + 1;
    }
    List<Map<String, dynamic>> result = tableCount.entries
        .map((e) => {'table_number': e.key, 'frequency': e.value})
        .toList();
    result.sort((a, b) => b['frequency'].compareTo(a['frequency']));
    return result.take(5).toList();
  }

  // CRUD Produk (Helper Standar)
  Future<List<Product>> getAllProducts() async {
    QuerySnapshot snapshot = await _db.collection(_colProducts).get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Product.fromMap(data);
    }).toList();
  }

  Future<void> insertProduct(Product p) async {
    await _db.collection(_colProducts).add({
      'name': p.name,
      'price': p.price,
      'imagePath': p.imagePath,
      'category': p.category,
      'subCategory': p.subCategory,
      'quantity': 0,
      'variant_data': p.variantPrices,
    });
  }

  Future<void> updateProduct(Product p, String id) async {
    await _db.collection(_colProducts).doc(id).update({
      'name': p.name,
      'price': p.price,
      'imagePath': p.imagePath,
      'category': p.category,
      'subCategory': p.subCategory,
      'variant_data': p.variantPrices,
    });
  }

  Future<void> deleteProduct(String id) async =>
      await _db.collection(_colProducts).doc(id).delete();
  Future<void> resetAllQuantities() async {
    var snapshot = await _db.collection(_colProducts).get();
    WriteBatch batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'quantity': 0});
    }
    await batch.commit();
  }
}
