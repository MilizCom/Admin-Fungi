import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../data/db_helper.dart';
import '../controllers/kasir_controller.dart';
import 'kirim_data_page.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final KasirController controller =
      Get.find<KasirController>(); // Ambil controller yg sudah ada

  // DATA STATES
  Map<String, int> summary = {'sales': 0, 'lost': 0};
  List<Map<String, dynamic>> topProducts = [];
  List<Map<String, dynamic>> tableTierList = [];
  List<Map<String, dynamic>> cancellations = [];

  // REPORT STATES (GROUPED)
  // Map<TransactionID, List<OrderItems>>
  Map<String, List<Map<String, dynamic>>> groupedTransactions = {};

  String timeFilter = 'Harian';
  String typeFilter = 'Semua'; // Dine In / Take Away
  int reportTotal = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    final sumStats = await DatabaseHelper.instance.getSummaryStats();
    final top = await DatabaseHelper.instance.getTopSellingProducts();
    final tiers = await DatabaseHelper.instance.getTableTierList();
    final cancels = await DatabaseHelper.instance.getCancellations();

    await loadReport(timeFilter, typeFilter);

    if (mounted) {
      setState(() {
        summary = sumStats;
        topProducts = top;
        tableTierList = tiers;
        cancellations = cancels;
        isLoading = false;
      });
    }
  }

  Future<void> loadReport(String tFilter, String tpFilter) async {
    final data = await DatabaseHelper.instance.getTransactionReport(tFilter);

    // Grouping Manual by transaction_id
    Map<String, List<Map<String, dynamic>>> grouped = {};
    int total = 0;

    for (var item in data) {
      // Filter Tipe Pesanan (Dine In/Take Away)
      if (tpFilter != 'Semua' && item['order_type'] != tpFilter) continue;

      String trId = item['transaction_id'] ?? 'Unknown';
      if (!grouped.containsKey(trId)) grouped[trId] = [];
      grouped[trId]!.add(item);

      total += (item['total_price'] as int);
    }

    setState(() {
      timeFilter = tFilter;
      typeFilter = tpFilter;
      groupedTransactions = grouped;
      reportTotal = total;
    });
  }

  String formatRupiah(int number) =>
      'Rp ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

  String formatDate(String dateStr) {
    try {
      return DateFormat('dd MMM HH:mm').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  // === DIALOG HAPUS HISTORY (VERSI ANTI-OVERFLOW) ===
  void showDeleteHistoryDialog(Map<String, dynamic> item) {
    final reasonC = TextEditingController();

    Get.dialog(
      Dialog(
        // Gunakan Dialog biasa, bukan AlertDialog, agar layout lebih fleksibel
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: const EdgeInsets.all(
          20,
        ), // Jarak dialog dari pinggir layar
        child: SingleChildScrollView(
          // Bungkus seluruh isi dialog agar bisa discroll
          child: Padding(
            padding: const EdgeInsets.all(20), // Padding di dalam dialog
            child: Column(
              mainAxisSize: MainAxisSize.min, // Agar tinggi menyesuaikan konten
              children: [
                // --- JUDUL ---
                const Text(
                  "Hapus Item Ini?",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 15),

                // --- KONTEN TEKS ---
                const Text(
                  "Item akan dihapus dari struk ini dan dipindah ke Data Batal.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text(
                  "${item['product_name']} (x${item['qty']})",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),

                // --- INPUT FIELD ---
                TextField(
                  controller: reasonC,
                  autofocus: true,
                  // scrollPadding memaksa layar naik tinggi saat diklik
                  scrollPadding: EdgeInsets.only(
                    bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 200,
                  ),
                  decoration: const InputDecoration(
                    labelText: "Alasan Hapus (Wajib)",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),
                    hintText: "Cth: Salah input",
                  ),
                ),
                const SizedBox(height: 25),

                // --- TOMBOL AKSI ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text(
                        "Batal",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (reasonC.text.trim().isEmpty) {
                          // Gunakan Get.rawSnackbar agar muncul di atas dialog
                          Get.rawSnackbar(
                            message: "Alasan wajib diisi!",
                            backgroundColor: Colors.red,
                            snackPosition: SnackPosition.TOP,
                          );
                          return;
                        }

                        // 1. Tutup Dialog
                        Get.back();

                        // 2. Eksekusi Hapus
                        await controller.deleteHistoryItem(
                          item['id'],
                          item,
                          reasonC.text,
                        );

                        // 3. Refresh Data
                        loadData();
                      },
                      child: const Text("Hapus"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Pusat Data'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.yellowAccent,
          tabs: const [
            Tab(text: "Dashboard"),
            Tab(text: "Riwayat"),
            Tab(text: "Batal"),
          ],
        ),
        actions: [
          // TOMBOL MENUJU HALAMAN KIRIM DATA
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: "Sinkronisasi",
            onPressed: () async {
              // Pindah ke halaman kirim data, dan refresh laporan saat kembali
              await Get.to(() => const KirimDataPage());
              loadData(); // Refresh list agar icon awan berubah jadi biru
            },
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildTransactionTab(),
                _buildCancellationTab(),
              ],
            ),
    );
  }

  // === TAB 1: DASHBOARD ===
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOTAL OMZET CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.teal],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Total Omzet",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 5),
                Text(
                  formatRupiah(summary['sales'] ?? 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // TIER LIST MEJA
          const Text(
            "🏆 Meja Terlaris",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: tableTierList.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(15),
                    child: Center(child: Text("Belum ada data meja.")),
                  )
                : Column(
                    children: tableTierList.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var item = entry.value;
                      String medal = idx == 0
                          ? "🥇"
                          : idx == 1
                          ? "🥈"
                          : idx == 2
                          ? "🥉"
                          : "#${idx + 1}";
                      return ListTile(
                        leading: Text(
                          medal,
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          "Meja ${item['table_number']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${item['frequency']}x",
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        dense: true,
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 20),

          // PRODUK TERLARIS
          const Text(
            "🔥 Produk Terlaris",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: topProducts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(15),
                    child: Center(child: Text("Belum ada penjualan.")),
                  )
                : Column(
                    children: topProducts.map((item) {
                      int qty = item['total_qty'] as int;
                      double percent = (qty / 50.0).clamp(
                        0.0,
                        1.0,
                      ); // Asumsi max 50 biar bar gak error
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['product_name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "$qty Terjual",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 8,
                                backgroundColor: Colors.grey[100],
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // === TAB 2: RIWAYAT TRANSAKSI (GROUPED & DELETE BUTTON) ===
  Widget _buildTransactionTab() {
    return Column(
      children: [
        // FILTER AREA
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Harian', 'Mingguan', 'Bulanan', 'Semua'].map((
                    filter,
                  ) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: timeFilter == filter,
                        selectedColor: Colors.green[100],
                        onSelected: (bool selected) {
                          if (selected) loadReport(filter, typeFilter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Semua', 'Dine In', 'Take Away'].map((type) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(type),
                        selected: typeFilter == type,
                        selectedColor: Colors.orange[100],
                        onSelected: (bool selected) {
                          if (selected) loadReport(timeFilter, type);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // TOTAL BAR
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          color: Colors.green[50],
          child: Text(
            "Total Pendapatan: ${formatRupiah(reportTotal)}",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
        ),

        // LIST GROUPED
        Expanded(
          child: groupedTransactions.isEmpty
              ? const Center(child: Text("Tidak ada data."))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 50),
                  itemCount: groupedTransactions.length,
                  itemBuilder: (context, index) {
                    String trId = groupedTransactions.keys.elementAt(index);
                    List<Map<String, dynamic>> items =
                        groupedTransactions[trId]!;

                    var header = items.first;
                    int totalStruk = items.fold(
                      0,
                      (sum, item) => sum + (item['total_price'] as int),
                    );
                    String payMethod = header['payment_method'] ?? 'Tunai';

                    // CEK STATUS SYNC DARI DATABASE
                    bool isSynced = (header['is_synced'] ?? 0) == 1;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      elevation: 1,
                      child: ExpansionTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // INDIKATOR STATUS ONLINE/OFFLINE
                            Icon(
                              isSynced ? Icons.cloud_done : Icons.cloud_off,
                              color: isSynced ? Colors.blue : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSynced ? "Online" : "Offline",
                              style: TextStyle(
                                fontSize: 8,
                                color: isSynced ? Colors.blue : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          "${header['customer_name']} (Meja ${header['table_number']})",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              formatDate(header['transaction_date']),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 5),
                            const Text("•"),
                            const SizedBox(width: 5),
                            // Metode Bayar
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: payMethod == 'QRIS'
                                    ? Colors.purple[50]
                                    : Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                payMethod,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: payMethod == 'QRIS'
                                      ? Colors.purple
                                      : Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatRupiah(totalStruk),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              "${items.length} Item",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        children: items.map((item) {
                          return Container(
                            color: Colors.grey[50],
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.only(
                                left: 20,
                                right: 10,
                              ),
                              title: Text(
                                "${item['product_name']} ${item['variant'] != '-' ? '(${item['variant']})' : ''}",
                              ),
                              subtitle: Text(
                                "${item['qty']}x @ ${formatRupiah(item['product_price'])}",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formatRupiah(item['total_price']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // TOMBOL HAPUS ITEM (SAMPAH MERAH)
                                  InkWell(
                                    onTap: () => showDeleteHistoryDialog(item),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // === TAB 3: PEMBATALAN ===
  Widget _buildCancellationTab() {
    return cancellations.isEmpty
        ? const Center(child: Text("Belum ada data pembatalan."))
        : ListView.builder(
            itemCount: cancellations.length,
            itemBuilder: (context, index) {
              final item = cancellations[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.close, color: Colors.white),
                  ),
                  title: Text(item['product_name']),
                  subtitle: Text(
                    "Alasan: ${item['reason']}\n${formatDate(item['cancel_date'])}",
                  ),
                  trailing: Text(
                    "- ${formatRupiah(item['total_lost'])}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
  }
}
