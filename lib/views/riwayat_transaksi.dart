import 'package:admin_fungi/models/admin_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});
  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final AdminController controller = Get.put(AdminController());

  // Style Warna
  final Color bgCanvas = const Color(0xFFF8F9FD);

  final Color primaryColor = const Color(0xFFFF8C00);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Panggil fungsi fetch data dari Firebase setiap buka halaman
      controller.fetchDataFromFirebase();

      // Reset filter visual
      controller.historySearchQuery.value = '';
      controller.historyPaymentFilter.value = 'Semua';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Reset filter saat masuk
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.historySearchQuery.value = '';
      controller.historyPaymentFilter.value = 'Semua';
    });

    return Scaffold(
      backgroundColor: bgCanvas,
      appBar: AppBar(
        title: const Text(
          "Kelola Transaksi",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        // ... (Bagian Search Bar & Filter Chips SAMA SEPERTI SEBELUMNYA) ...
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                // SEARCH
                TextField(
                  onChanged: (val) => controller.setHistorySearch(val),
                  decoration: InputDecoration(
                    hintText: "Cari Nama / Meja...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: bgCanvas,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // FILTER
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        "Filter: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Obx(() => _buildFilterChip("Semua")),
                      const SizedBox(width: 8),
                      Obx(() => _buildFilterChip("Tunai")),
                      const SizedBox(width: 8),
                      Obx(() => _buildFilterChip("QRIS")),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        var data = controller.displayedHistory;
        if (data.isEmpty)
          return const Center(
            child: Text(
              "Data tidak ditemukan",
              style: TextStyle(color: Colors.grey),
            ),
          );

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            var trx = data[index];
            String time = trx.transactionDate.split(' ').length > 1
                ? trx.transactionDate.split(' ')[1].substring(0, 5)
                : "-";

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: trx.paymentMethod == 'Tunai'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    trx.paymentMethod == 'Tunai' ? Icons.money : Icons.qr_code,
                    color: trx.paymentMethod == 'Tunai'
                        ? Colors.green
                        : Colors.purple,
                    size: 20,
                  ),
                ),
                title: Text(
                  "Meja ${trx.tableNumber} - ${trx.customerName}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  "$time • ${controller.formatRupiah(trx.totalBill)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showOptionsDialog(context, trx),
                ),
                onTap: () => _showDetailSheet(context, trx),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = controller.historyPaymentFilter.value == label;
    return GestureDetector(
      onTap: () => controller.setHistoryPaymentFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, TransactionModel trx) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
              title: const Text("Lihat Detail"),
              onTap: () {
                Get.back();
                _showDetailSheet(context, trx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text("Edit Transaksi"),
              subtitle: const Text("Ubah Meja / Metode Bayar"),
              onTap: () {
                Get.back();
                _showEditDialog(context, trx);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Void / Batalkan Transaksi"),
              subtitle: const Text("Hapus dan pindahkan ke Void Log"),
              onTap: () {
                Get.back();
                _showVoidConfirmation(context, trx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. FITUR UPDATE (EDIT) ---
  void _showEditDialog(BuildContext context, TransactionModel trx) {
    final tableC = TextEditingController(text: trx.tableNumber);
    String selectedMethod = trx.paymentMethod;

    Get.defaultDialog(
      title: "Edit Transaksi",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      content: Column(
        children: [
          TextField(
            controller: tableC,
            decoration: const InputDecoration(
              labelText: "Nomor Meja",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: (selectedMethod == 'Tunai' || selectedMethod == 'QRIS')
                ? selectedMethod
                : 'Tunai',
            items: const [
              DropdownMenuItem(value: "Tunai", child: Text("Tunai")),
              DropdownMenuItem(value: "QRIS", child: Text("QRIS")),
            ],
            onChanged: (val) => selectedMethod = val!,
            decoration: const InputDecoration(
              labelText: "Metode Pembayaran",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      textConfirm: "Simpan Perubahan",
      confirmTextColor: Colors.white,
      buttonColor: Colors.orange,
      onConfirm: () {
        controller.updateTransaction(
          trx.transactionId,
          selectedMethod,
          tableC.text,
        );
      },
      textCancel: "Batal",
    );
  }

  // --- 3. FITUR DELETE (VOID) ---
  void _showVoidConfirmation(BuildContext context, TransactionModel trx) {
    final reasonC = TextEditingController();
    Get.defaultDialog(
      title: "Batalkan Transaksi?",
      titleStyle: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
      ),
      content: Column(
        children: [
          const Text(
            "Transaksi ini akan dihapus dari penjualan dan dicatat sebagai VOID/Rug.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: reasonC,
            decoration: const InputDecoration(
              labelText: "Alasan Pembatalan (Wajib)",
              hintText: "Contoh: Salah input, Refund customer",
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      textConfirm: "YA, BATALKAN",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        if (reasonC.text.isEmpty) {
          Get.snackbar("Error", "Alasan wajib diisi!");
          return;
        }
        controller.voidTransaction(trx, reasonC.text);
      },
      textCancel: "Kembali",
    );
  }

  // --- 4. READ (DETAIL SHEET) ---
  void _showDetailSheet(BuildContext context, TransactionModel trx) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, color: Colors.grey[300]),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Meja ${trx.tableNumber}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    trx.paymentMethod,
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(trx.customerName, style: const TextStyle(color: Colors.grey)),
            const Divider(height: 30),
            Expanded(
              child: ListView(
                children: trx.items.map<Widget>((item) {
                  String name = item['product_name'] ?? '-';
                  if (item['variant'] != null && item['variant'] != '-')
                    name += " (${item['variant']})";
                  int qty = item['qty'] ?? 0;
                  int total = item['total'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: bgCanvas,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${qty}x",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(name)),
                        Text(
                          controller.formatRupiah(total),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Tagihan", style: TextStyle(fontSize: 16)),
                Text(
                  controller.formatRupiah(trx.totalBill),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Trx ID: ${trx.transactionId}",
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
