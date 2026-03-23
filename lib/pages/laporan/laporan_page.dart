import 'package:flutter/material.dart';
import 'package:fungi_casheer/controllers/kasir_controller.dart';
import 'package:fungi_casheer/data/FirestoreHelper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// Import Widgets dan Dialogs
import 'laporan_dialogs.dart';
import 'widgets/dashboard_tab.dart';
import 'widgets/transaction_tab.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final KasirController controller = Get.find<KasirController>();

  List<Map<String, dynamic>> topProducts = [];
  List<Map<String, dynamic>> tableTierList = [];
  List<Map<String, dynamic>> transactionList = [];

  String timeFilter = 'Harian';
  String typeFilter = 'Semua';
  DateTime? customStartDate;
  DateTime? customEndDate;
  bool isLoading = true;

  int reportTotal = 0;
  int reportTunai = 0;
  int reportQRIS = 0;

  Map<String, Map<String, int>> financialStats = {
    'Harian': {'Total': 0, 'Tunai': 0, 'QRIS': 0},
    'Mingguan': {'Total': 0, 'Tunai': 0, 'QRIS': 0},
    'Bulanan': {'Total': 0, 'Tunai': 0, 'QRIS': 0},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final top = await FirestoreHelper.instance.getTopSellingProducts();
      final tiers = await FirestoreHelper.instance.getTableTierList();
      await calculateDashboardFinancials();
      await loadReport(timeFilter, typeFilter);

      if (mounted) {
        setState(() {
          topProducts = top;
          tableTierList = tiers;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> calculateDashboardFinancials() async {
    DateTime now = DateTime.now();
    DateTime startDay = DateTime(now.year, now.month, now.day);
    DateTime endDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    DateTime startWeek = now.subtract(Duration(days: now.weekday - 1));
    startWeek = DateTime(startWeek.year, startWeek.month, startWeek.day);
    DateTime startMonth = DateTime(now.year, now.month, 1);

    Map<String, int> processList(List<Map<String, dynamic>> data) {
      int total = 0, tunai = 0, qris = 0;
      for (var item in data) {
        int price = (item['total_bill'] ?? 0) as int;
        String method = item['payment_method'] ?? 'Tunai';
        total += price;
        if (method == 'Tunai')
          tunai += price;
        else if (method == 'QRIS')
          qris += price;
      }
      return {'Total': total, 'Tunai': tunai, 'QRIS': qris};
    }

    var daily = await FirestoreHelper.instance.getTransactionsByCustomRange(
      startDay,
      endDay,
    );
    var weekly = await FirestoreHelper.instance.getTransactionsByCustomRange(
      startWeek,
      endDay,
    );
    var monthly = await FirestoreHelper.instance.getTransactionsByCustomRange(
      startMonth,
      endDay,
    );

    if (mounted) {
      setState(() {
        financialStats['Harian'] = processList(daily);
        financialStats['Mingguan'] = processList(weekly);
        financialStats['Bulanan'] = processList(monthly);
      });
    }
  }

  Future<void> loadReport(String tFilter, String tpFilter) async {
    DateTime now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (tFilter == 'Harian') {
      start = DateTime(now.year, now.month, now.day, 0, 0, 0);
    } else if (tFilter == 'Mingguan') {
      DateTime monday = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
    } else if (tFilter == 'Bulanan') {
      start = DateTime(now.year, now.month, 1, 0, 0, 0);
    } else if (tFilter == 'Custom' &&
        customStartDate != null &&
        customEndDate != null) {
      start = customStartDate!;
      end = customEndDate!;
    } else {
      start = DateTime(now.year, now.month - 1, 1);
    }

    var rawData = await FirestoreHelper.instance.getTransactionsByCustomRange(
      start,
      end,
    );
    List<Map<String, dynamic>> filteredList = [];
    int tempTotal = 0, tempTunai = 0, tempQRIS = 0;

    for (var trx in rawData) {
      if (tpFilter != 'Semua' && trx['order_type'] != tpFilter) continue;
      filteredList.add(trx);
      int price = (trx['total_bill'] ?? 0) as int;
      String method = trx['payment_method'] ?? 'Tunai';
      tempTotal += price;
      if (method == 'Tunai')
        tempTunai += price;
      else if (method == 'QRIS')
        tempQRIS += price;
    }

    if (mounted) {
      setState(() {
        timeFilter = tFilter;
        typeFilter = tpFilter;
        transactionList = filteredList;
        reportTotal = tempTotal;
        reportTunai = tempTunai;
        reportQRIS = tempQRIS;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Laporan Penjualan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: "Dashboard"),
            Tab(text: "Riwayat & Filter"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Data",
            onPressed: loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                DashboardTab(
                  financialStats: financialStats,
                  tableTierList: tableTierList,
                  topProducts: topProducts,
                  formatRupiah: formatRupiah,
                ),
                TransactionTab(
                  transactionList: transactionList,
                  timeFilter: timeFilter,
                  typeFilter: typeFilter,
                  customStartDate: customStartDate,
                  customEndDate: customEndDate,
                  reportTotal: reportTotal,
                  reportTunai: reportTunai,
                  reportQRIS: reportQRIS,
                  formatRupiah: formatRupiah,
                  formatDate: formatDate,
                  onFilterChanged: (time, type) {
                    if (time != 'Custom') {
                      setState(() {
                        customStartDate = null;
                        customEndDate = null;
                      });
                    }
                    loadReport(time, type);
                  },
                  onPickCustomRange: () {
                    LaporanDialogs.showCustomRangePicker(
                      context: context,
                      onPicked: (start, end) {
                        setState(() {
                          customStartDate = start;
                          customEndDate = end;
                        });
                        loadReport('Custom', typeFilter);
                      },
                    );
                  },
                  onDeleteItem: (docId, itemData, trxId) {
                    LaporanDialogs.showDeleteHistoryDialog(
                      docId: docId,
                      itemData: itemData,
                      onConfirm: (reason) async {
                        await controller.deleteHistoryItem(
                          docId,
                          itemData,
                          reason,
                        );
                        loadData();
                      },
                    );
                  },
                ),
              ],
            ),
    );
  }
}
