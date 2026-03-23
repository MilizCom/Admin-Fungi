import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/kasir_controller.dart';

class ActiveOrderPage extends StatelessWidget {
  final KasirController controller = Get.find();

  ActiveOrderPage({super.key});

  String formatRupiah(int number) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(number);

  String formatTime(String dateString) {
    try {
      return DateFormat('HH:mm').format(DateTime.parse(dateString));
    } catch (e) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    // PENTING: Refresh data saat halaman dibuka
    controller.loadActiveTransactions();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Daftar Bill Aktif (Pending)",
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
                  "Tidak ada pesanan gantung",
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

  Widget _buildStrukCard(Map<String, dynamic> data) {
    String transId = data['transaction_id'];
    String tableName = data['table_number'] ?? '-';
    String custName = data['customer_name'] ?? 'Pelanggan';
    String time = formatTime(data['last_update'] ?? DateTime.now().toString());
    int total = (data['total_bill'] ?? 0).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // HEADER: MEJA & NAMA
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(6),
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
                        "Jam Order: $time",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // VOID BUTTON
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () =>
                      _showVoidDialog(transId, tableName, custName),
                ),
                // DETAIL BUTTON
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blue),
                  onPressed: () =>
                      _showDetailDialog(transId, custName, tableName),
                ),
              ],
            ),
          ),

          // BODY: TOTAL & ACTION
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
                    // TOMBOL TAMBAH ORDER
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text("Tambah"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                      onPressed: () =>
                          controller.resumeOrder(tableName, custName),
                    ),
                    const SizedBox(width: 8),
                    // TOMBOL BAYAR (FINALISASI)
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

  void _showPaymentDialog(String transId, int total) {
    Get.defaultDialog(
      title: "Pilih Pembayaran",
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        children: [
          Text(
            formatRupiah(total),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Pilih metode pembayaran untuk melunasi:",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _payBtn(transId, "Tunai", Colors.green, Icons.money),
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

  Widget _payBtn(String id, String method, Color color, IconData icon) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () async {
        // Panggil Controller untuk Bayar Bill Gantung
        await controller.payRunningOrder(id, method);
        // Jika sukses, controller akan menutup dialog
      },
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            method,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showVoidDialog(String transId, String table, String name) {
    final reasonC = TextEditingController();
    Get.defaultDialog(
      title: "Hapus Bill?",
      titleStyle: const TextStyle(color: Colors.red),
      content: Column(
        children: [
          Text(
            "Menghapus pesanan Meja $table ($name) secara permanen.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: reasonC,
            decoration: const InputDecoration(
              labelText: "Alasan (Wajib)",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        onPressed: () {
          if (reasonC.text.isEmpty) return;
          controller.voidRunningOrder(transId, reasonC.text);
        },
        child: const Text(
          "Hapus Permanen",
          style: TextStyle(color: Colors.white),
        ),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text("Batal"),
      ),
    );
  }

  void _showDetailDialog(String transId, String name, String table) async {
    // Tampilkan Loading
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    // Ambil Data Item
    List<Map<String, dynamic>> items = await controller.getOrderDetails(
      transId,
    );
    if (Get.isDialogOpen!) Get.back(); // Tutup loading

    Get.bottomSheet(
      Container(
        height: Get.height * 0.5,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Text(
              "Detail Meja $table - $name",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  var item = items[i];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['product_name']),
                    subtitle: Text(
                      "${item['qty']}x @ ${formatRupiah(item['price'])}",
                    ),
                    trailing: Text(formatRupiah(item['total'])),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 