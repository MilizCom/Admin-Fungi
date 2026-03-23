import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StockLogModel {
  final String id;
  final String productName; // Kita simpan nama produk langsung saat simpan log
  final int newStock; // Stok akhir setelah perubahan
  final int changeAmount; // Selisih (+10 atau -5) - Opsional jika mau hitung
  final String reason; // "Restock", "Opname", dll
  final DateTime timestamp;

  StockLogModel({
    required this.id,
    required this.productName,
    required this.newStock,
    required this.changeAmount,
    required this.reason,
    required this.timestamp,
  });

  factory StockLogModel.fromFirestore(Map<String, dynamic> data, String docId) {
    Timestamp? ts = data['timestamp'];
    return StockLogModel(
      id: docId,
      productName: data['product_name'] ?? 'Produk Dihapus',
      newStock: (data['new_stock'] ?? 0).toInt(),
      changeAmount: (data['change_amount'] ?? 0).toInt(),
      reason: data['reason'] ?? '-',
      timestamp: ts != null ? ts.toDate() : DateTime.now(),
    );
  }

  // Helper format tanggal
  String get formattedDate =>
      DateFormat('dd MMM yyyy, HH:mm').format(timestamp);
}
