import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/kasir_controller.dart';
import '../../models/menu_model.dart';

class KasirDialogs {
  // Helper Format Rupiah
  static String formatRupiah(int number) {
    return 'Rp ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  static void showLoading() {
    Get.dialog(
      const PopScope(
        canPop: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 15),
              Text(
                "Memproses Transaksi...",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
    );
  }

  static void hideLoading() {
    Navigator.of(Get.overlayContext!).pop();
  }

  static void showDiscountDialog(
    int index,
    Map<String, dynamic> item,
    KasirController controller,
  ) {
    int currentDiscountRp = item['discount'] ?? 0;
    int price = item['price_used'] ?? item['product'].price;

    final inputC = TextEditingController();
    var isPercent = false.obs;
    var calculatedRp = 0.obs;

    void calculatePreview(String val) {
      if (val.isEmpty) {
        calculatedRp.value = 0;
        return;
      }
      String cleanVal = val.replaceAll(',', '.');
      double inputVal = double.tryParse(cleanVal) ?? 0;

      if (isPercent.value) {
        calculatedRp.value = ((price * inputVal) / 100).round();
      } else {
        calculatedRp.value = inputVal.toInt();
      }
    }

    inputC.text = currentDiscountRp > 0 ? currentDiscountRp.toString() : "";
    calculatePreview(inputC.text);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Atur Potongan Harga",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 15),
              Text(
                "Menu: ${item['product'].name}",
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                "Harga Asli: ${formatRupiah(price)}",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Obx(
                () => Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            isPercent.value = false;
                            inputC.clear();
                            calculatedRp.value = 0;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isPercent.value
                                  ? Colors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Nominal (Rp)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !isPercent.value
                                    ? Colors.white
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            isPercent.value = true;
                            inputC.clear();
                            calculatedRp.value = 0;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isPercent.value
                                  ? Colors.orange
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Persen (%)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPercent.value
                                    ? Colors.white
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Obx(
                () => TextField(
                  controller: inputC,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: true,
                  onChanged: calculatePreview,
                  decoration: InputDecoration(
                    labelText: isPercent.value
                        ? "Masukkan Persentase"
                        : "Masukkan Nominal",
                    border: const OutlineInputBorder(),
                    prefixText: isPercent.value ? "" : "Rp ",
                    suffixText: isPercent.value ? "%" : "",
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Obx(
                () => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Total Potongan:",
                        style: TextStyle(fontSize: 10, color: Colors.green),
                      ),
                      Text(
                        formatRupiah(calculatedRp.value),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Batal"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.updateItemDiscount(
                          index,
                          calculatedRp.value,
                        );
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Simpan"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showVariantDialog(Product product, KasirController controller) {
    Map<String, String> variantLabels = {
      "H": "Hot",
      "M": "Medium",
      "L": "Large",
    };

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
            Text(
              "Pilih Varian: ${product.name}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: product.variantPrices.keys.map((code) {
                int price = product.variantPrices[code]!;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    controller.addToCart(product, code, price);
                    Get.back();
                  },
                  child: Column(
                    children: [
                      Text(
                        variantLabels[code] ?? code,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatRupiah(price),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  static void showCartDetail(KasirController controller) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Rincian Pesanan & Diskon",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: Obx(
                () => ListView.separated(
                  itemCount: controller.cartItems.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    var item = controller.cartItems[index];
                    Product p = item['product'];
                    int price = item['price_used'] ?? p.price;
                    int discount = item['discount'] ?? 0;
                    int finalPrice = price - discount;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item['variant'] != '-')
                            Text("Varian: ${item['variant']}"),
                          Row(
                            children: [
                              Text(
                                formatRupiah(price),
                                style: TextStyle(
                                  decoration: discount > 0
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              if (discount > 0) ...[
                                const SizedBox(width: 5),
                                Text(
                                  formatRupiah(finalPrice),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (discount > 0)
                            Text(
                              "Diskon: -${formatRupiah(discount)}",
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.local_offer,
                              color: discount > 0 ? Colors.orange : Colors.grey,
                            ),
                            onPressed: () =>
                                showDiscountDialog(index, item, controller),
                          ),
                          Text(
                            "${item['qty']}x",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => controller.removeFromCart(p),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  static void showPaymentBottomSheet(KasirController controller) {
    var selectedType = 'Dine In'.obs;
    var paymentMethod = 'Tunai'.obs;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.9,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Konfirmasi Pesanan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Obx(
                        () => Text(
                          formatRupiah(controller.totalPrice),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller.nameController,
                      decoration: const InputDecoration(
                        labelText: "Nama Pelanggan",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Tipe Pesanan:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Obx(
                      () => Row(
                        children: ["Dine In", "Take Away"].map((type) {
                          bool isSelected = selectedType.value == type;
                          return Expanded(
                            child: InkWell(
                              onTap: () => selectedType.value = type,
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (type == "Dine In"
                                            ? Colors.green
                                            : Colors.orange)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? (type == "Dine In"
                                              ? Colors.green
                                              : Colors.orange)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Obx(
                      () => Visibility(
                        visible: selectedType.value == 'Dine In',
                        child: TextField(
                          controller: controller.tableController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Nomor Meja (Wajib)",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.table_restaurant),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Metode Pembayaran (Jika Lunas):",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Obx(
                      () => Row(
                        children: ["Tunai", "QRIS"].map((method) {
                          bool isSelected = paymentMethod.value == method;
                          return Expanded(
                            child: InkWell(
                              onTap: () => paymentMethod.value = method,
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (method == "Tunai"
                                            ? Colors.blue
                                            : Colors.purple)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      method == "Tunai"
                                          ? Icons.money
                                          : Icons.qr_code,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black54,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      method,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black54,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              if (selectedType.value == 'Dine In' &&
                                  controller.tableController.text.isEmpty)
                                return;
                              Get.back();
                              await Future.delayed(
                                const Duration(milliseconds: 300),
                              );
                              showLoading();
                              try {
                                await controller.processTransaction(
                                  customerName:
                                      controller.nameController.text.isEmpty
                                      ? "Pelanggan"
                                      : controller.nameController.text,
                                  tableNumber: selectedType.value == 'Dine In'
                                      ? controller.tableController.text
                                      : "-",
                                  orderType: selectedType.value,
                                  paymentMethod: "-",
                                  isRunningOrder: true,
                                );
                              } finally {
                                hideLoading();
                              }
                            },
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.save_as,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                Text(
                                  "SIMPAN BILL (PENDING)",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          if (selectedType.value == 'Dine In' &&
                              controller.tableController.text.isEmpty)
                            return;
                          Get.back();
                          await Future.delayed(
                            const Duration(milliseconds: 300),
                          );
                          showLoading();
                          try {
                            await controller.processTransaction(
                              customerName:
                                  controller.nameController.text.isEmpty
                                  ? "Pelanggan"
                                  : controller.nameController.text,
                              tableNumber: selectedType.value == 'Dine In'
                                  ? controller.tableController.text
                                  : "-",
                              orderType: selectedType.value,
                              paymentMethod: paymentMethod.value,
                              isRunningOrder: false,
                            );
                          } finally {
                            hideLoading();
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              "BAYAR & KIRIM STRUK",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  static void showCancelDialog(KasirController controller) {
    if (controller.totalPrice == 0) return;
    final reasonC = TextEditingController();
    Get.defaultDialog(
      title: "Batalkan Pesanan?",
      content: TextField(
        controller: reasonC,
        decoration: const InputDecoration(
          hintText: "Alasan Batal (Wajib)",
          border: OutlineInputBorder(),
        ),
      ),
      textConfirm: "Ya, Batalkan",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        if (reasonC.text.isEmpty) return;
        controller.cancelOrder(reasonC.text);
        Get.back();
      },
      cancel: TextButton(
        onPressed: () {
          controller.resetAll();
          Get.back();
        },
        child: const Text("Reset Biasa"),
      ),
    );
  }
}
