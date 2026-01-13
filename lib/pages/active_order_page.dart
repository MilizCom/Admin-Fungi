import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/kasir_controller.dart';

class ActiveOrderPage extends StatelessWidget {
  final KasirController controller = Get.find();

  // Helper Format Rupiah
  String formatRupiah(int number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  // Helper Format Waktu
  String formatTime(String dateString) {
    try {
      DateTime dt = DateTime.parse(dateString);
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    controller.loadActiveTransactions(); // Refresh data

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Daftar Bill Aktif",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.activeTransactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 10),
                Text(
                  "Tidak ada pesanan berjalan",
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.activeTransactions.length,
          itemBuilder: (context, index) {
            var data = controller.activeTransactions[index];
            return _buildStrukCard(data);
          },
        );
      }),
    );
  }

  // 1. WIDGET KARTU STRUK
  Widget _buildStrukCard(Map<String, dynamic> data) {
    String transId = data['transaction_id'];
    String tableName = data['table_number'] ?? '-';
    String custName = data['customer_name'] ?? 'Pelanggan';
    String time = formatTime(data['last_update'] ?? DateTime.now().toString());
    int total = data['total_bill'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // HEADER STRUK
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Badge Meja
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Meja $tableName",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Nama
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        custName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Tombol Delete (Void)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: "Batalkan Pesanan (Void)",
                  onPressed: () =>
                      _showVoidDialog(transId, tableName, custName),
                ),

                // Icon Detail
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blue),
                  onPressed: () =>
                      _showDetailDialog(transId, custName, tableName),
                ),
              ],
            ),
          ),

          _buildDashedLine(),

          // BODY STRUK
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Total Tagihan",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      formatRupiah(total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("Menu"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                      onPressed: () =>
                          controller.resumeOrder(tableName, custName),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text("Bayar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showPaymentDialog(transId, total),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. DIALOG ALASAN PEMBATALAN (SOLUSI FINAL OVERFLOW)
  void _showVoidDialog(String transId, String table, String name) {
    final reasonC = TextEditingController();

    Get.dialog(
      AlertDialog(
        scrollable:
            true, // <--- KUNCI PERBAIKAN: Membuat seluruh dialog bisa discroll
        title: const Text(
          "Batalkan Pesanan?",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Anda akan menghapus pesanan berjalan untuk Meja $table ($name).",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Tindakan ini tidak bisa dibatalkan!",
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: reasonC,
              // Tambahkan scrollPadding agar otomatis naik saat keyboard menutupi
              scrollPadding: const EdgeInsets.only(bottom: 200),
              autofocus: true, // Langsung fokus agar keyboard muncul
              decoration: const InputDecoration(
                labelText: "Alasan Pembatalan (Wajib)",
                border: OutlineInputBorder(),
                hintText: "Contoh: Pelanggan kabur, Salah input",
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Batal", style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (reasonC.text.trim().isEmpty) {
                return;
              }
              // Tutup dialog dulu
              Get.back();
              // Panggil fungsi void
              controller.voidRunningOrder(transId, reasonC.text);
            },
            child: const Text("HAPUS PERMANEN"),
          ),
        ],
      ),
      barrierDismissible: false, // User wajib memilih tombol
    );
  }

  // WIDGET GARIS PUTUS-PUTUS
  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey[300]),
              ),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }

  // --- DIALOG DETAIL ---
  void _showDetailDialog(String transId, String name, String table) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    List<Map<String, dynamic>> items = await controller.getOrderDetails(
      transId,
    );
    Get.back();

    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Meja $table - $name",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  var item = items[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${item['qty']}x",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(item['product_name']),
                    subtitle: item['variant'] != '-'
                        ? Text("Varian: ${item['variant']}")
                        : null,
                    trailing: Text(
                      formatRupiah(item['total_price']),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // --- DIALOG BAYAR ---
  void _showPaymentDialog(String transId, int total) {
    Get.defaultDialog(
      title: "Pilih Pembayaran",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        children: [
          Text(
            formatRupiah(total),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _payBtn(transId, "Tunai", Colors.blue, Icons.money),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _payBtn(transId, "QRIS", Colors.purple, Icons.qr_code),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET TOMBOL BAYAR (TANPA SNACKBAR)
  Widget _payBtn(String id, String method, Color color, IconData icon) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () async {
        // 1. Munculkan Loading
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        try {
          // 2. Proses Database (Tunggu sampai selesai)
          await controller.payRunningOrder(id, method);

          // 3. Tutup Loading (Pop ke-1)
          if (Get.isDialogOpen == true) Get.back();

          // 4. Tutup Dialog Pembayaran (Pop ke-2)
          if (Get.isDialogOpen == true) Get.back();
        } catch (e) {
          // Jika error, tutup Loading saja. Dialog pembayaran tetap terbuka.
          if (Get.isDialogOpen == true) Get.back();

          // Print error di console untuk debugging (Tanpa Snackbar)
          print("Error pembayaran: $e");
        }
      },
      child: Column(
        children: [Icon(icon), const SizedBox(height: 4), Text(method)],
      ),
    );
  }
}
