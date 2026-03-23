import 'package:admin_fungi/controllers/ingredient_controller.dart';
import 'package:admin_fungi/models/admin_model.dart';
import 'package:admin_fungi/views/ingredient_page.dart';
import 'package:admin_fungi/views/manage_menu_page.dart';
import 'package:admin_fungi/views/riwayat_pembatalan.dart';
import 'package:admin_fungi/views/riwayat_transaksi.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';

class AdminDashboard extends StatelessWidget {
  final AdminController controller = Get.put(AdminController());
  final Color bgCanvas = const Color(0xFFF8F9FD);
  final Color primaryColor = const Color(0xFFFF8C00);
  final Color secondaryColor = const Color(0xFF2D3436);
  final Color chartBlue = const Color(0xFF54A0FF);
  final Color chartPurple = const Color(0xFF5F27CD);
  final Color chartRed = const Color(0xFFFF6B6B);
  final Color chartGreen = const Color(0xFF00B894);
  final IngredientController ingController = Get.put(IngredientController());
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.historySearchQuery.value = '';
      controller.historyPaymentFilter.value = 'Semua';
    });
    return Scaffold(
      backgroundColor: bgCanvas,
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.fetchDataFromFirebase,
          color: primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRevenueCard(),
                const SizedBox(height: 30),
                Text("Tren Penjualan (Harian)", style: _titleStyle()),
                const SizedBox(height: 20),
                _buildAdminMenus(),
                const SizedBox(height: 20),
                _buildSyncStockCard(),
                const SizedBox(height: 15),
                _buildSalesTrendChart(),
                const SizedBox(height: 30),
                Text("Statistik Meja Terpopuler", style: _titleStyle()),
                const SizedBox(height: 15),
                _buildTableStats(),
                const SizedBox(height: 30),
                Text("Metode Pembayaran", style: _titleStyle()),
                const SizedBox(height: 15),
                _buildPaymentPieChart(),
                const SizedBox(height: 30),
                Text("Statistik Menu Terlaris", style: _titleStyle()),
                const SizedBox(height: 15),
                _buildTopProductBarChart(),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        "Total Trx",
                        "${controller.totalTrxCount}",
                        Icons.receipt,
                        chartBlue,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildMiniStat(
                        "Total Void",
                        controller.formatRupiah(controller.totalVoidLost.value),
                        Icons.delete_sweep,
                        chartRed,
                        onTap: () => Get.to(
                          () => VoidHistoryPage(),
                        ), // <--- NAVIGASI KE SINI
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Get.to(() => TransactionHistoryPage()),
                    child: const Text(
                      "Lihat Detail Riwayat",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
  // Di admin_dashboard.dart

  Widget _buildSyncStockCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sinkronisasi Stok",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Tampilkan kapan terakhir kali diupdate
                  Obx(
                    () => Text(
                      "Terakhir update: ${ingController.lastSyncTimeDisplay.value}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTrendChart() {
    if (controller.dailyStats.isEmpty)
      return _emptyState("Belum ada data untuk periode ini");

    // Konversi Map ke List<FlSpot>
    List<String> dates = controller.dailyStats.keys.toList();
    List<FlSpot> spots = [];

    double maxY = 0;
    for (int i = 0; i < dates.length; i++) {
      double val = controller.dailyStats[dates[i]]!.toDouble();
      if (val > maxY) maxY = val;
      spots.add(FlSpot(i.toDouble(), val));
    }

    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100000;

    return Container(
      height: 300, // Tinggi Grafik
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),

            // Label Bawah (Tanggal)
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1, // Tampilkan setiap titik jika memungkinkan
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < dates.length) {
                    // Format tanggal jadi pendek: "10 Jan"
                    DateTime dt = DateTime.parse(dates[index]);
                    String text = DateFormat('d MMM', 'id_ID').format(dt);

                    // Agar tidak menumpuk jika data banyak, tampilkan selang-seling
                    if (dates.length > 7 && index % 2 != 0)
                      return const SizedBox();

                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),

            // Label Kiri (Nominal)
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0)
                    return const Text(
                      '0',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    );
                  // Singkat angka: 1jt, 500rb
                  if (value >= 1000000)
                    return Text(
                      '${(value / 1000000).toStringAsFixed(1)}jt',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    );
                  if (value >= 1000)
                    return Text(
                      '${(value / 1000).toStringAsFixed(0)}rb',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    );
                  return const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (dates.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true, // Garis melengkung halus
              color: chartGreen,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: chartGreen,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: chartGreen.withOpacity(
                  0.15,
                ), // Efek bayangan di bawah garis
              ),
            ),
          ],
          // Tooltip saat ditekan
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: secondaryColor,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  int index = barSpot.x.toInt();
                  String date = DateFormat(
                    'd MMM yyyy',
                    'id_ID',
                  ).format(DateTime.parse(dates[index]));
                  String val = controller.formatRupiah(barSpot.y.toInt());
                  return LineTooltipItem(
                    '$date\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    children: [
                      TextSpan(
                        text: val,
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  // Update sedikit pada Pie Chart agar warna konsisten
  Widget _buildPaymentPieChart() {
    int tunai = controller.paymentMethodStats['Tunai'] ?? 0;
    int qris = controller.paymentMethodStats['QRIS'] ?? 0;
    int total = tunai + qris;

    if (total == 0) return _emptyState("Belum ada data pembayaran");

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 150,
            width: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: tunai.toDouble(),
                    title: '${((tunai / total) * 100).toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.purple,
                    value: qris.toDouble(),
                    title: '${((qris / total) * 100).toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 30),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chartLegend(Colors.green, "Tunai", "$tunai Trx"),
                const SizedBox(height: 15),
                _chartLegend(Colors.purple, "QRIS", "$qris Trx"),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // Di file admin_dashboard.dart

  Widget _buildAdminMenus() {
    return Column(
      children: [
        // 1. Menu Kelola Produk (Edit Nama & Harga & RESEP)
        _menuItem(
          title: "Kelola Menu & Resep",
          subtitle: "Tambah produk, atur harga & takaran resep",
          icon: Icons.restaurant_menu,
          color: Colors.blue,
          onTap: () => Get.to(() => ManageMenuPage()),
        ),
        const SizedBox(height: 15),

        // 2. Menu STOK (SEKARANG JADI STOK BAHAN BAKU)
        _menuItem(
          title: "Stok Bahan Baku (Inventory)", // Judul diganti
          subtitle: "Cek sisa Gula, Susu, Cup, dll",
          icon: Icons.inventory, // Icon gudang
          color: Colors.orange, // Warna inventory
          // PENTING: Arahkan ke IngredientPage, BUKAN StockPage
          onTap: () => Get.to(() => IngredientPage()),
        ),

        // HAPUS menu "Stok Produk Retail" yang lama
      ],
    );
  }

  Widget _menuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductBarChart() {
    if (controller.topProducts.isEmpty)
      return _emptyState("Belum ada penjualan");
    var data = controller.topProducts.take(5).toList();
    double maxQty = data.isEmpty ? 10 : data.first.qtySold.toDouble() + 5;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxQty,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: secondaryColor,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String productName = data[group.x.toInt()].name;
                      if (productName.length > 15)
                        productName = "${productName.substring(0, 15)}...";
                      return BarTooltipItem(
                        '$productName\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} Sold',
                            style: const TextStyle(color: Colors.yellow),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() >= data.length)
                          return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            String.fromCharCode(65 + value.toInt()),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: data.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.qtySold.toDouble(),
                        color: primaryColor,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxQty,
                          color: Colors.grey.shade100,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: data.asMap().entries.map((e) {
              String letter = String.fromCharCode(65 + e.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        letter,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value.name,
                        style: const TextStyle(
                          fontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Text(
                      "${e.value.qtySold} sold",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---
  // Lokasi: Di dalam class AdminDashboard -> method _buildAppBar

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: bgCanvas,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dashboard",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Text(
            "Fungi Admin",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        // --- TOMBOL UPDATE SPREADSHEET (YANG DIPERBAIKI) ---
        Obx(
          () => IconButton(
            icon: controller.isUploadingSpreadsheet.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.green,
                    ),
                  )
                : const Icon(Icons.table_chart, color: Colors.green),
            tooltip: "Update Semua Laporan (Penjualan & Void)",

            onPressed: controller.isUploadingSpreadsheet.value
                ? null
                : () async {
                    // 1. Cek Data Kosong
                    if (controller.filteredTransactions.isEmpty &&
                        controller.filteredVoids.isEmpty) {
                      Get.snackbar(
                        "Info",
                        "Tidak ada data apapun (Penjualan/Void) di tanggal ini.",
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                      );
                      return;
                    }

                    // 2. JALANKAN SEQUENCE UPDATE
                    // Update Penjualan
                    if (controller.filteredTransactions.isNotEmpty) {
                      await controller.updateSpreadsheet();
                    }

                    // Beri jeda sedikit agar server Google tidak 'kaget' (Concurrency lock)
                    await Future.delayed(const Duration(seconds: 2));

                    // Update Pembatalan (INI YANG KEMARIN TERLEWAT)
                    if (controller.filteredVoids.isNotEmpty) {
                      await controller.updateVoidSpreadsheet();
                    } else {
                      print("Skip Void: Data kosong");
                    }
                  },
          ),
        ),

        // ---------------------------------------------------
        GestureDetector(
          onTap: () => _showFilterBottomSheet(context),
          child: Container(
            margin: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: primaryColor),
                const SizedBox(width: 8),
                Obx(
                  () => Text(
                    controller.filterLabel.value,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Pendapatan",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.formatRupiah(controller.totalOmzet.value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap, // <--- Tambahkan ini
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // Tambahkan border jika bisa diklik agar terlihat interaktif
          border: onTap != null
              ? Border.all(color: color.withOpacity(0.3))
              : null,
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartLegend(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }

  TextStyle _titleStyle() => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  Widget _buildTableStats() {
    if (controller.topTables.isEmpty) return _emptyState("Belum ada data meja");

    // Cari nilai frekuensi tertinggi untuk skala progress bar
    double maxFreq = controller.topTables.first.frequency.toDouble();
    if (maxFreq == 0) maxFreq = 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: controller.topTables.asMap().entries.map((entry) {
          int index = entry.key;
          TableStat table = entry.value;
          double percent = table.frequency / maxFreq;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                // Icon Meja / Nomor Urut
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index < 3 ? primaryColor.withOpacity(0.1) : bgCanvas,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: index < 3 ? primaryColor : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Bar & Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Meja ${table.tableNumber}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "${table.frequency}x (${controller.formatRupiah(table.totalRevenue)})",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 8,
                          backgroundColor: bgCanvas,
                          color: index == 0
                              ? primaryColor
                              : (index == 1
                                    ? chartBlue
                                    : chartPurple.withOpacity(0.6)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- FILTER BOTTOM SHEET (Copy dari sebelumnya) ---
  void _showFilterBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Pilih Periode Laporan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _filterTile(
              Icons.today,
              "Hari Ini",
              () => controller.setFilterToday(),
            ),
            _filterTile(
              Icons.history,
              "Kemarin",
              () => controller.setFilterYesterday(),
            ),
            _filterTile(
              Icons.calendar_month,
              "Bulan Ini",
              () => controller.setFilterThisMonth(),
            ),
            _filterTile(Icons.date_range, "Custom Tanggal", () async {
              Get.back();
              var picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(primary: primaryColor),
                  ),
                  child: child!,
                ),
              );
              if (picked != null)
                controller.setCustomRange(picked.start, picked.end);
            }),
          ],
        ),
      ),
    );
  }

  Widget _filterTile(IconData icon, String title, Function() onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgCanvas,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: secondaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () {
        onTap();
        if (Get.isBottomSheetOpen!) Get.back();
      },
    );
  }
}
