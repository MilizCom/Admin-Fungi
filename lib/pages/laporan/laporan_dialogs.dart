import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LaporanDialogs {
  // --- DIALOG PICKER RENTANG WAKTU (DATE & TIME) ---
  static Future<void> showCustomRangePicker({
    required BuildContext context,
    required Function(DateTime start, DateTime end) onPicked,
  }) async {
    DateTime now = DateTime.now();

    // 1. Pilih Rentang Tanggal
    DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: now, end: now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.green,
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );

    if (dateRange == null) return;

    // 2. Pilih Jam Mulai
    TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
      helpText: "PILIH JAM MULAI",
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );
    startTime ??= const TimeOfDay(hour: 0, minute: 0);

    // 3. Pilih Jam Selesai
    TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
      helpText: "PILIH JAM SELESAI",
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );
    endTime ??= const TimeOfDay(hour: 23, minute: 59);

    DateTime start = DateTime(
      dateRange.start.year,
      dateRange.start.month,
      dateRange.start.day,
      startTime.hour,
      startTime.minute,
    );
    DateTime end = DateTime(
      dateRange.end.year,
      dateRange.end.month,
      dateRange.end.day,
      endTime.hour,
      endTime.minute,
    );

    onPicked(start, end);
  }

  // --- DIALOG KONFIRMASI HAPUS ITEM (VOID) ---
  static void showDeleteHistoryDialog({
    required String docId,
    required Map<String, dynamic> itemData,
    required Function(String reason) onConfirm,
  }) {
    final reasonC = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 40,
                ),
                const SizedBox(height: 15),
                const Text(
                  "Hapus Item?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  "Menghapus ${itemData['product_name']} x${itemData['qty']}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: reasonC,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: "Alasan Pembatalan",
                    hintText: "Contoh: Salah input",
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: const Text(
                          "Batal",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (reasonC.text.trim().isEmpty) return;
                          Get.back();
                          onConfirm(reasonC.text);
                        },
                        child: const Text("Hapus"),
                      ),
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
}
