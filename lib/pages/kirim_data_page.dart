import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/kasir_controller.dart';
import '../data/db_helper.dart';

class KirimDataPage extends StatefulWidget {
  const KirimDataPage({super.key});

  @override
  State<KirimDataPage> createState() => _KirimDataPageState();
}

class _KirimDataPageState extends State<KirimDataPage> {
  final KasirController controller = Get.find<KasirController>();
  int pendingCount = 0;
  bool isLoadingCount = true;

  @override
  void initState() {
    super.initState();
    _checkPendingData();
  }

  // Hitung ada berapa struk yang belum dikirim
  Future<void> _checkPendingData() async {
    final data = await DatabaseHelper.instance.getUnsyncedTransactions();
    // Grouping by ID agar hitungannya per struk, bukan per item
    final uniqueIds = data.map((e) => e['transaction_id']).toSet();

    setState(() {
      pendingCount = uniqueIds.length;
      isLoadingCount = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sinkronisasi Data"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ikon Awan
              Icon(
                Icons.cloud_upload_outlined,
                size: 100,
                color: pendingCount > 0 ? Colors.orange : Colors.green,
              ),
              const SizedBox(height: 20),

              const Text(
                "Status Data Lokal",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 10),

              // Counter
              if (isLoadingCount)
                const CircularProgressIndicator()
              else
                Text(
                  pendingCount > 0
                      ? "$pendingCount Struk Belum Terkirim"
                      : "Semua Data Sudah Aman",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: pendingCount > 0 ? Colors.red : Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 40),

              // Tombol Upload
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Disable tombol jika tidak ada data atau sedang loading
                    onPressed: (pendingCount == 0 || controller.isSyncing.value)
                        ? null
                        : () async {
                            await controller.syncDataToFirebase();
                            _checkPendingData(); // Cek ulang setelah selesai
                          },
                    icon: controller.isSyncing.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      controller.isSyncing.value
                          ? "MENGIRIM..."
                          : "KIRIM DATA SEKARANG",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Pastikan Anda terhubung ke internet agar proses ini berhasil.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
