// Model untuk Statistik Meja
class TableStat {
  final String tableNumber;
  final int frequency; // Berapa kali diduduki
  final int totalRevenue; // Total uang dari meja ini

  TableStat(this.tableNumber, this.frequency, this.totalRevenue);
}

// Model Utama Transaksi
class TransactionModel {
  final String docId; // ID Dokumen Firestore (Unik)
  final String transactionId; // ID Transaksi (Format: YYYYMMDD-HHmmss)
  final String transactionDate;
  final String customerName;
  final String tableNumber;
  final String paymentMethod;
  final String orderType; // "Dine In" atau "Take Away"
  final int totalBill;
  final List<dynamic> items; // List menu yang dicheckout

  TransactionModel({
    required this.docId,
    required this.transactionId,
    required this.transactionDate,
    required this.customerName,
    required this.tableNumber,
    required this.paymentMethod,
    required this.orderType,
    required this.totalBill,
    required this.items,
  });

  // Factory: Mengubah Data Firestore (Map) -> Object Dart
  factory TransactionModel.fromFirestore(Map<String, dynamic> data, String id) {
    return TransactionModel(
      docId: id,
      transactionId: data['transaction_id'] ?? '',
      transactionDate: data['transaction_date'] ?? '',
      customerName: data['customer_name'] ?? 'Pelanggan',
      tableNumber: data['table_number'] ?? '-',
      paymentMethod: data['payment_method'] ?? 'Tunai',
      orderType: data['order_type'] ?? 'Dine In',
      // Pastikan konversi ke integer aman meskipun data aslinya double/string
      totalBill: int.tryParse(data['total_bill'].toString()) ?? 0,
      items: data['items'] ?? [],
    );
  }

  // Method: Mengubah Object Dart -> Map (Untuk simpan ke Firestore)
  // INI YANG SEBELUMNYA KOSONG/ERROR
  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      'transaction_date': transactionDate,
      'customer_name': customerName,
      'table_number': tableNumber,
      'payment_method': paymentMethod,
      'order_type': orderType,
      'total_bill': totalBill,
      'items': items,
    };
  }
}

// Model untuk Log Pembatalan (Void)
class VoidModel {
  final String id; // ID Dokumen Firebase
  final String transactionId;
  final String productName;
  final int qty;
  final int totalLost; // Uang yang hilang/rugi
  final String reason;
  final String cancelDate;

  VoidModel({
    required this.id,
    required this.transactionId,
    required this.productName,
    required this.qty,
    required this.totalLost,
    required this.reason,
    required this.cancelDate,
  });

  factory VoidModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return VoidModel(
      id: docId,
      transactionId: data['transaction_id'] ?? '-',
      productName: data['product_name'] ?? '-',
      qty: int.tryParse(data['qty'].toString()) ?? 0,
      totalLost: int.tryParse(data['total_lost'].toString()) ?? 0,
      reason: data['reason'] ?? '-',
      cancelDate: data['cancel_date'] ?? '',
    );
  }
}

// Model untuk Laporan Produk Terlaris
class ProductStat {
  final String name;
  final int qtySold;
  final int totalRevenue;

  ProductStat(this.name, this.qtySold, this.totalRevenue);
}
