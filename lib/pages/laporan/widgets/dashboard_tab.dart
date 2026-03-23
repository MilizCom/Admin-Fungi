import 'package:flutter/material.dart';
import 'financial_card.dart';

class DashboardTab extends StatelessWidget {
  final Map<String, Map<String, int>> financialStats;
  final List<Map<String, dynamic>> tableTierList;
  final List<Map<String, dynamic>> topProducts;
  final String Function(int) formatRupiah;

  const DashboardTab({
    super.key,
    required this.financialStats,
    required this.tableTierList,
    required this.topProducts,
    required this.formatRupiah,
  });

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(msg, style: TextStyle(color: Colors.grey[400])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FinancialCard(
          title: "Hari Ini",
          data: financialStats['Harian']!,
          color: Colors.green,
          isBig: true,
          formatRupiah: formatRupiah,
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: FinancialCard(
                title: "Minggu Ini",
                data: financialStats['Mingguan']!,
                color: Colors.blue,
                isBig: false,
                formatRupiah: formatRupiah,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FinancialCard(
                title: "Bulan Ini",
                data: financialStats['Bulanan']!,
                color: Colors.orange,
                isBig: false,
                formatRupiah: formatRupiah,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const Text(
          "🏆 Performa Meja",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        tableTierList.isEmpty
            ? _buildEmptyState("Belum ada data meja.")
            : Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: tableTierList.take(5).toList().asMap().entries.map((
                    entry,
                  ) {
                    int idx = entry.key;
                    var item = entry.value;
                    return ListTile(
                      leading: Text(
                        idx == 0
                            ? "🥇"
                            : idx == 1
                            ? "🥈"
                            : idx == 2
                            ? "🥉"
                            : "#${idx + 1}",
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(
                        "Meja ${item['table_number']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Chip(
                        label: Text("${item['frequency']}x"),
                        backgroundColor: Colors.green[50],
                      ),
                      dense: true,
                    );
                  }).toList(),
                ),
              ),
        const SizedBox(height: 30),
        const Text(
          "🔥 Produk Terlaris",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        topProducts.isEmpty
            ? _buildEmptyState("Belum ada penjualan.")
            : Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: topProducts.take(5).map((item) {
                      int qty = item['total_qty'] as int;
                      double percent = (qty / 100.0).clamp(0.0, 1.0);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
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
                                  "$qty Porsi",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: percent,
                              minHeight: 6,
                              backgroundColor: Colors.grey[100],
                              color: Colors.green,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
        const SizedBox(height: 30),
      ],
    );
  }
}
