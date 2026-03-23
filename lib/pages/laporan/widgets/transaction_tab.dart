import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionTab extends StatelessWidget {
  final List<Map<String, dynamic>> transactionList;
  final String timeFilter;
  final String typeFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final int reportTotal;
  final int reportTunai;
  final int reportQRIS;
  final String Function(int) formatRupiah;
  final String Function(String) formatDate;
  final Function(String, String) onFilterChanged;
  final VoidCallback onPickCustomRange;
  final Function(String, Map<String, dynamic>, String) onDeleteItem;

  const TransactionTab({
    super.key,
    required this.transactionList,
    required this.timeFilter,
    required this.typeFilter,
    required this.customStartDate,
    required this.customEndDate,
    required this.reportTotal,
    required this.reportTunai,
    required this.reportQRIS,
    required this.formatRupiah,
    required this.formatDate,
    required this.onFilterChanged,
    required this.onPickCustomRange,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                // 1. FILTER TANGGAL
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          (timeFilter == 'Custom' && customStartDate != null)
                              ? "${DateFormat('dd/MM HH:mm').format(customStartDate!)} - ${DateFormat('dd/MM HH:mm').format(customEndDate!)}"
                              : "Pilih Tanggal & Jam",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: timeFilter == 'Custom'
                            ? Colors.blue[700]
                            : Colors.grey[400],
                        onPressed: onPickCustomRange,
                      ),
                      const SizedBox(width: 8),
                      ...['Harian', 'Mingguan', 'Bulanan', 'Semua'].map((
                        filter,
                      ) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 12,
                                color: timeFilter == filter
                                    ? Colors.green[800]
                                    : Colors.black,
                              ),
                            ),
                            selected: timeFilter == filter,
                            selectedColor: Colors.green[100],
                            onSelected: (val) {
                              if (val) onFilterChanged(filter, typeFilter);
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 2. FILTER TIPE (Dine In / Take Away)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ['Semua', 'Dine In', 'Take Away'].map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            type,
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: typeFilter == type,
                          selectedColor: Colors.orange[100],
                          onSelected: (val) {
                            if (val) onFilterChanged(timeFilter, type);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // 3. KOTAK TOTAL
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade400],
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
                        "Total Pendapatan (Filter)",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formatRupiah(reportTotal),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  "Tunai",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatRupiah(reportTunai),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white24,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  "QRIS",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatRupiah(reportQRIS),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. LIST TRANSAKSI
        transactionList.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 60,
                        color: Colors.grey[300],
                      ),
                      const Text("Tidak ada data"),
                    ],
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  var trxData = transactionList[index];
                  List<dynamic> productItems = trxData['items'] ?? [];
                  int totalBill = (trxData['total_bill'] ?? 0) as int;
                  String docId = trxData['id'] ?? '';
                  String trId = trxData['transaction_id'] ?? '';
                  String payMethod = trxData['payment_method'] ?? 'Tunai';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: payMethod == 'QRIS'
                              ? Colors.purple[50]
                              : Colors.green[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          payMethod == 'QRIS' ? Icons.qr_code : Icons.money,
                          color: payMethod == 'QRIS'
                              ? Colors.purple
                              : Colors.green,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        "${trxData['customer_name']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Meja ${trxData['table_number']} • ${formatDate(trxData['transaction_date'])}",
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: payMethod == 'QRIS'
                                  ? Colors.purple[100]
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              payMethod,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: payMethod == 'QRIS'
                                    ? Colors.purple[900]
                                    : Colors.green[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        formatRupiah(totalBill),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      children: productItems.map<Widget>((item) {
                        return Container(
                          color: Colors.grey[50],
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(
                              left: 70,
                              right: 20,
                            ),
                            title: Text(item['product_name']),
                            subtitle: Text(
                              "${item['qty']}x @ ${formatRupiah(item['price'])} ${item['variant'] != '-' ? '(${item['variant']})' : ''}",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(formatRupiah(item['total'])),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => onDeleteItem(
                                    docId,
                                    item as Map<String, dynamic>,
                                    trId,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }, childCount: transactionList.length),
              ),
      ],
    );
  }
}
