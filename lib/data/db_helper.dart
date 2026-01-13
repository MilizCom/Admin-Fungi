import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/menu_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // GANTI NAMA FILE INI:
    _database = await _initDB('fungi_bites_v5.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. TABEL PRODUCTS
    await db.execute('''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      price INTEGER NOT NULL,
      imagePath TEXT NOT NULL,
      category TEXT NOT NULL,
      subCategory TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      variant_data TEXT  
    )
    ''');

    // 2. TABEL ORDERS (Pastikan ada discount)
    await db.execute('''
    CREATE TABLE orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id TEXT, 
      customer_name TEXT, 
      table_number TEXT, 
      order_type TEXT, 
      payment_method TEXT,
      product_name TEXT NOT NULL,
      product_price INTEGER NOT NULL,
      qty INTEGER NOT NULL,
      variant TEXT,
      discount INTEGER DEFAULT 0, 
      total_price INTEGER NOT NULL,
      transaction_date TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0,
      payment_status TEXT DEFAULT 'Paid' 
    )
    ''');

    // 3. TABEL CANCELLATIONS
    await db.execute('''
    CREATE TABLE cancellations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id TEXT, -- Kolom Baru
      product_name TEXT NOT NULL,
      product_price INTEGER NOT NULL,
      qty INTEGER NOT NULL,
      total_lost INTEGER NOT NULL,
      reason TEXT NOT NULL,
      cancel_date TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0 -- Kolom Baru
    )
    ''');

    // Seed Data Awal
    await _seedData(db);
  }

  // UPDATE FUNGSI SAVE ORDER
  Future<void> saveOrder({
    required List<Map<String, dynamic>> cartItems,
    required String customerName,
    required String tableNumber,
    required String orderType,
    required String paymentMethod,
    required bool isRunningOrder,
  }) async {
    final db = await instance.database;
    final String now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // ... (Logika penentuan transactionId dan payment_method sama seperti sebelumnya) ...
    // Copy paste logika 'isRunningOrder' dan 'transactionId' dari kode Anda sebelumnya di sini...

    // CONTOH SAJA (Supaya ringkas, pastikan logika ID Transaksi Running Order Anda tetap ada):
    String transactionId = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    String status = isRunningOrder ? 'Open' : 'Paid';
    String finalMethod = isRunningOrder ? 'PENDING' : paymentMethod;

    // Cek Running Order Logic (Get Existing ID) ... (Pertahankan kode lama Anda di sini)
    // ...

    Batch batch = db.batch();
    for (var item in cartItems) {
      Product p = item['product'];
      int finalPrice = item['price_used'] ?? p.price;
      int qty = item['qty'];
      int discount = item['discount'] ?? 0; // AMBIL DISKON

      // Hitung Total per Item setelah diskon
      int totalPerItem = (finalPrice - discount) * qty;
      if (totalPerItem < 0) totalPerItem = 0; // Jaga-jaga biar gak minus

      batch.insert('orders', {
        'transaction_id': transactionId,
        'customer_name': customerName,
        'table_number': tableNumber,
        'order_type': orderType,
        'payment_method': finalMethod,
        'product_name': p.name,
        'product_price': finalPrice,
        'qty': qty,
        'variant': item['variant'],
        'discount': discount, // SIMPAN DISKON
        'total_price': totalPerItem,
        'transaction_date': now,
        'is_synced': 0,
        'payment_status': status,
      });
    }
    await batch.commit();
  }

  // ===========================================================================
  // DATA SEEDER (DATA DUMMY)
  // ===========================================================================
  Future<void> _seedData(Database db) async {
    final batch = db.batch();

    // 1. Crisjom
    batch.insert('products', {
      'name': 'Crisjom',
      'price': 14000, // Harga terendah untuk display
      'imagePath':
          'assets/images/snack.png', // Ganti dengan path gambar asli nanti
      'category': 'Makanan',
      'subCategory': 'Snack',
      'quantity': 0,
      'variant_data': jsonEncode({'M': 14000, 'L': 22000}),
    });

    // 2. Zamur (Gyoza)
    batch.insert('products', {
      'name': 'Zamur (Gyoza)',
      'price': 10000,
      'imagePath': 'assets/images/snack.png',
      'category': 'Makanan',
      'subCategory': 'Snack',
      'quantity': 0,
      'variant_data': jsonEncode({'M': 10000, 'L': 15000}),
    });

    // 3. Dimur (Dimsum)
    batch.insert('products', {
      'name': 'Dimur (Dimsum)',
      'price': 10000,
      'imagePath': 'assets/images/snack.png',
      'category': 'Makanan',
      'subCategory': 'Snack',
      'quantity': 0,
      'variant_data': jsonEncode({'M': 10000, 'L': 15000}),
    });

    // 4. Fungiball
    batch.insert('products', {
      'name': 'Fungiball',
      'price': 11000,
      'imagePath': 'assets/images/snack.png',
      'category': 'Makanan',
      'subCategory': 'Snack',
      'quantity': 0,
      'variant_data': jsonEncode({'M': 11000, 'L': 17000}),
    });

    // 5. Si Gojam (Pangsit) - Tanpa Varian
    batch.insert('products', {
      'name': 'Si Gojam (Pangsit)',
      'price': 14000,
      'imagePath': 'assets/images/snack.png',
      'category': 'Makanan',
      'subCategory': 'Snack',
      'quantity': 0,
      'variant_data': jsonEncode({}), // Tidak ada varian
    });

    batch.insert('products', {
      'name': 'Buttermilk Fungi Bawl',
      'price': 19000,
      'imagePath': 'assets/images/nasi.png',
      'category': 'Makanan',
      'subCategory': 'Main Course',
      'quantity': 0,
      'variant_data': jsonEncode({}),
    });

    batch.insert('products', {
      'name': 'Ffungi Teriyaki Bawl',
      'price': 18000,
      'imagePath': 'assets/images/nasi.png',
      'category': 'Makanan',
      'subCategory': 'Main Course',
      'quantity': 0,
      'variant_data': jsonEncode({}),
    });

    batch.insert('products', {
      'name': 'Nasi Jamur Sambal Bawang',
      'price': 19000,
      'imagePath': 'assets/images/nasi.png',
      'category': 'Makanan',
      'subCategory': 'Main Course',
      'quantity': 0,
      'variant_data': jsonEncode({}),
    });

    batch.insert('products', {
      'name': 'Nasi Jamur Sambal Ijo',
      'price': 18000,
      'imagePath': 'assets/images/nasi.png',
      'category': 'Makanan',
      'subCategory': 'Main Course',
      'quantity': 0,
      'variant_data': jsonEncode({}),
    });

    batch.insert('products', {
      'name': 'Mie Instan Single',
      'price': 8000,
      'imagePath': 'assets/images/mie.png',
      'category': 'Makanan',
      'subCategory': 'Mie',
      'quantity': 0,
      'variant_data': jsonEncode({}),
    });
    batch.insert('products', {
      'name': 'Mie Instan Double',
      'price': 13000,
      'imagePath': 'assets/images/mie.png',
      'category': 'Makanan',
      'subCategory': 'Mie',
      'quantity': 0,
      'variant_data': jsonEncode({}),
    });
    batch.insert('products', {
      'name': 'Intel Single',
      'price': 12000,
      'imagePath': 'assets/images/mie.png',
      'category': 'Makanan',
      'subCategory': 'Mie',
      'quantity': 0,
      'variant_data': jsonEncode({}),
    });
    batch.insert('products', {
      'name': 'Intel Double',
      'price': 17000,
      'imagePath': 'assets/images/mie.png',
      'category': 'Makanan',
      'subCategory': 'Mie',
      'quantity': 0,
      'variant_data': jsonEncode({}),
    });
    batch.insert('products', {
      'name': 'Nasi Putih',
      'price': 5000,
      'imagePath': 'assets/images/nasi.png',
      'category': 'Makanan',
      'subCategory': 'Tambahan',
      'quantity': 0,
      'variant_data': jsonEncode({}),
    });
    batch.insert('products', {
      'name': 'Telur',
      'price': 4000,
      'imagePath': 'assets/images/snack.png',
      'category': 'Makanan',
      'subCategory': 'Tambahan',
      'quantity': 0,
      'variant_data': jsonEncode({}),
    });

    // Americano (Lengkap H, M, L)
    batch.insert('products', {
      'name': 'Americano',
      'price': 13000,
      'imagePath': 'assets/images/kopi.png',
      'category': 'Minuman',
      'subCategory': 'Coffee',
      'quantity': 0,
      'variant_data': jsonEncode({'H': 13000, 'M': 17000, 'L': 21000}),
    });

    // Kopi Susu (Ada 3 harga, asumsi H, M, L)
    batch.insert('products', {
      'name': 'Kopi Susu',
      'price': 15000,
      'imagePath': 'assets/images/kopi.png',
      'category': 'Minuman',
      'subCategory': 'Coffee',
      'quantity': 0,
      'variant_data': jsonEncode({'H': 15000, 'M': 18000, 'L': 22000}),
    });

    // Kopi Aren (Hanya ada 2 harga 20k & 24k, asumsi M dan L karena dingin biasanya)
    batch.insert('products', {
      'name': 'Kopi Aren',
      'price': 20000,
      'imagePath': 'assets/images/kopi.png',
      'category': 'Minuman',
      'subCategory': 'Coffee',
      'quantity': 0,
      'variant_data': jsonEncode({'M': 20000, 'L': 24000}),
    });

    // Butterscotch (24k & 28k)
    batch.insert('products', {
      'name': 'Butterscotch',
      'price': 24000,
      'imagePath': 'assets/images/kopi.png',
      'category': 'Minuman',
      'subCategory': 'Coffee',
      'quantity': 0,
      'variant_data': jsonEncode({'M': 24000, 'L': 28000}),
    });

    // Caramel Macchiato
    batch.insert('products', {
      'name': 'Caramel Macchiato',
      'price': 24000,
      'imagePath': 'assets/images/kopi.png',
      'category': 'Minuman',
      'subCategory': 'Coffee',
      'quantity': 0,
      'variant_data': jsonEncode({'M': 24000, 'L': 28000}),
    });

    // Vanila
    batch.insert('products', {
      'name': 'Vanila Latte',
      'price': 22000,
      'imagePath': 'assets/images/kopi.png',
      'category': 'Minuman',
      'subCategory': 'Coffee',
      'quantity': 0,
      'variant_data': jsonEncode({'M': 22000, 'L': 26000}),
    });

    batch.insert('products', {
      'name': 'Taro',
      'price': 19000,
      'imagePath': 'assets/images/matcha.png', // Ganti icon yg sesuai
      'category': 'Minuman',
      'subCategory': 'Non-Coffee',
      'quantity': 0,
      'variant_data': jsonEncode({'M': 19000, 'L': 23000}),
    });

    batch.insert('products', {
      'name': 'Red Velvet',
      'price': 20000,
      'imagePath': 'assets/images/matcha.png',
      'category': 'Minuman',
      'subCategory': 'Non-Coffee',
      'quantity': 0,
      'variant_data': jsonEncode({'M': 20000, 'L': 24000}),
    });

    batch.insert('products', {
      'name': 'Coklat',
      'price': 20000,
      'imagePath': 'assets/images/matcha.png',
      'category': 'Minuman',
      'subCategory': 'Non-Coffee',
      'quantity': 0,
      'variant_data': jsonEncode({'M': 20000, 'L': 24000}),
    });

    batch.insert('products', {
      'name': 'Strawberry',
      'price': 19000,
      'imagePath': 'assets/images/teh.png',
      'category': 'Minuman',
      'subCategory': 'Non-Coffee',
      'quantity': 0,
      'variant_data': jsonEncode({'M': 19000, 'L': 23000}),
    });

    batch.insert('products', {
      'name': 'Thai Tea',
      'price': 19000,
      'imagePath': 'assets/images/teh.png',
      'category': 'Minuman',
      'subCategory': 'Non-Coffee',
      'quantity': 0,
      'variant_data': jsonEncode({'M': 19000, 'L': 23000}),
    });

    batch.insert('products', {
      'name': 'Green Tea',
      'price': 19000,
      'imagePath': 'assets/images/matcha.png',
      'category': 'Minuman',
      'subCategory': 'Non-Coffee',
      'quantity': 0,
      'variant_data': jsonEncode({'M': 19000, 'L': 23000}),
    });

    await batch.commit();
  }

  // ===========================================================================
  // CRUD PRODUK
  // ===========================================================================

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products');
    return result.map((json) => Product.fromMap(json)).toList();
  }
  // ... kode sebelumnya ...

  // === FUNGSI BARU: BATALKAN SELURUH TRANSAKSI (MOVE TO CANCEL) ===
  Future<void> cancelTransaction(String transactionId, String reason) async {
    final db = await instance.database;
    final String now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // 1. Ambil data item yang akan dihapus
    final List<Map<String, dynamic>> items = await db.query(
      'orders',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );

    if (items.isEmpty) return;

    Batch batch = db.batch();

    // 2. Pindahkan ke tabel Cancellations
    for (var item in items) {
      batch.insert('cancellations', {
        'transaction_id': transactionId, // Simpan ID nya
        'product_name': item['product_name'],
        'product_price': item['product_price'],
        'qty': item['qty'],
        'total_lost': item['total_price'],
        'reason': "$reason (Void)",
        'cancel_date': now,
        'is_synced': 0, // Tandai belum dikirim
      });
    }

    // 3. Hapus dari tabel Orders
    batch.delete(
      'orders',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );

    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getUnsyncedCancellations() async {
    final db = await instance.database;
    return await db.query(
      'cancellations',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  // Tandai data cancel sudah dikirim
  Future<void> markCancellationAsSynced(int id) async {
    final db = await instance.database;
    await db.update(
      'cancellations',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertProduct(Product product) async {
    final db = await instance.database;
    String variantJson = jsonEncode(product.variantPrices);
    return await db.insert('products', {
      'name': product.name,
      'price': product.price,
      'imagePath': product.imagePath,
      'category': product.category,
      'subCategory': product.subCategory,
      'quantity': 0,
      'variant_data': variantJson,
    });
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    String variantJson = jsonEncode(product.variantPrices);
    return await db.update(
      'products',
      {
        'name': product.name,
        'price': product.price,
        'imagePath': product.imagePath,
        'category': product.category,
        'subCategory': product.subCategory,
        'variant_data': variantJson,
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateQuantity(int id, int quantity) async {
    final db = await instance.database;
    return await db.update(
      'products',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> resetAllQuantities() async {
    final db = await instance.database;
    return await db.update('products', {'quantity': 0});
  }

  // ===========================================================================
  // TRANSAKSI & SYNC LOGIC
  // ===========================================================================

  Future<void> saveTransaction(
    List<Map<String, dynamic>> cartItems,
    String customerName,
    String table,
    String orderType,
    String paymentMethod,
  ) async {
    final db = await instance.database;
    final String now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final String transactionId = DateFormat(
      'yyyyMMdd-HHmmss',
    ).format(DateTime.now());

    Batch batch = db.batch();

    for (var item in cartItems) {
      Product p = item['product'];
      int finalPrice = item['price_used'] ?? p.price;
      int qty = item['qty'];

      batch.insert('orders', {
        'transaction_id': transactionId,
        'customer_name': customerName,
        'table_number': table,
        'order_type': orderType,
        'payment_method': paymentMethod,
        'product_name': p.name,
        'product_price': finalPrice,
        'qty': qty,
        'variant': item['variant'],
        'total_price': finalPrice * qty,
        'transaction_date': now,
        'is_synced': 0, // Default 0 (Belum Sync)
      });
    }
    await batch.commit();
  }

  // Ambil Data yang belum di-sync
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    final db = await instance.database;
    return await db.query(
      'orders',
      where: 'is_synced = ? AND payment_method != ?', // <--- FILTER PENTING
      whereArgs: [0, 'PENDING'], // Abaikan yang PENDING
    );
  }

  Future<String?> getOpenTransactionId(String tableNumber) async {
    final db = await instance.database;
    final result = await db.query(
      'orders',
      columns: ['transaction_id'],
      where: 'table_number = ? AND payment_method = ?',
      whereArgs: [tableNumber, 'PENDING'],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['transaction_id'] as String;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getActiveTransactions() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT transaction_id, table_number, customer_name, SUM(total_price) as total_bill, MAX(transaction_date) as last_update
      FROM orders 
      WHERE payment_method = 'PENDING' 
      GROUP BY transaction_id
      ORDER BY last_update DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getTransactionItems(
    String transactionId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'orders',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  // 4. Proses Bayar Bill Gantung (Checkout dari Halaman Terpisah)
  Future<void> checkoutOpenBill(String transactionId, String realMethod) async {
    final db = await instance.database;

    // GUNAKAN TRANSACTION BLOCK
    // Ini mencegah database "terkunci" (Deadlock) saat update dilakukan
    await db.transaction((txn) async {
      await txn.update(
        'orders',
        {
          'payment_method': realMethod, // Simpan metode bayar (Tunai/QRIS)
          'payment_status':
              'Paid', // <--- PENTING: Ubah status jadi Paid agar hilang dari list Active
          'is_synced': 0, // Tandai butuh sync ke Firebase
        },
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );
    });
  }

  // Tandai Data sebagai sudah di-sync
  Future<void> markTransactionAsSynced(String transactionId) async {
    final db = await instance.database;
    await db.update(
      'orders',
      {'is_synced': 1},
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  // ===========================================================================
  // VOID / PEMBATALAN
  // ===========================================================================

  Future<void> moveOrderToCancel(
    int orderId,
    Map<String, dynamic> item,
    String reason,
  ) async {
    final db = await instance.database;
    final String now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    await db.transaction((txn) async {
      await txn.insert('cancellations', {
        'product_name': item['product_name'],
        'product_price': item['product_price'],
        'qty': item['qty'],
        'total_lost': item['total_price'],
        'reason': "Dihapus: $reason",
        'cancel_date': now,
      });
      await txn.delete('orders', where: 'id = ?', whereArgs: [orderId]);
    });
  }

  Future<void> saveCancellation(
    List<Map<String, dynamic>> items,
    String reason,
  ) async {
    final db = await instance.database;
    final String now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    Batch batch = db.batch();
    for (var item in items) {
      Product p = item['product'];
      int finalPrice = item['price_used'] ?? p.price;
      int qty = item['qty'];
      batch.insert('cancellations', {
        'product_name': p.name,
        'product_price': finalPrice,
        'qty': qty,
        'total_lost': finalPrice * qty,
        'reason': reason,
        'cancel_date': now,
      });
    }
    await batch.commit();
  }

  // ===========================================================================
  // REPORTING
  // ===========================================================================

  Future<List<Map<String, dynamic>>> getTransactionReport(
    String timeFilter,
  ) async {
    final db = await instance.database;
    String query = "SELECT * FROM orders";
    List<dynamic> args = [];
    DateTime now = DateTime.now();

    if (timeFilter == 'Harian') {
      query += " WHERE transaction_date LIKE ?";
      args.add('${DateFormat('yyyy-MM-dd').format(now)}%');
    } else if (timeFilter == 'Bulanan') {
      query += " WHERE transaction_date LIKE ?";
      args.add('${DateFormat('yyyy-MM').format(now)}%');
    }
    query += " ORDER BY transaction_date DESC";
    return await db.rawQuery(query, args);
  }

  Future<Map<String, int>> getSummaryStats() async {
    final db = await instance.database;
    final resultSales = await db.rawQuery(
      'SELECT SUM(total_price) as total FROM orders',
    );
    final resultCancel = await db.rawQuery(
      'SELECT SUM(total_lost) as total FROM cancellations',
    );
    return {
      'sales': Sqflite.firstIntValue(resultSales) ?? 0,
      'lost': Sqflite.firstIntValue(resultCancel) ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts() async {
    final db = await instance.database;
    return await db.rawQuery(
      'SELECT product_name, SUM(qty) as total_qty FROM orders GROUP BY product_name ORDER BY total_qty DESC LIMIT 5',
    );
  }

  Future<List<Map<String, dynamic>>> getTableTierList() async {
    final db = await instance.database;
    return await db.rawQuery(
      "SELECT table_number, COUNT(DISTINCT transaction_id) as frequency FROM orders WHERE table_number != '-' AND table_number != '' GROUP BY table_number ORDER BY frequency DESC LIMIT 5",
    );
  }

  Future<List<Map<String, dynamic>>> getCancellations() async {
    final db = await instance.database;
    return await db.query('cancellations', orderBy: "cancel_date DESC");
  }
}
