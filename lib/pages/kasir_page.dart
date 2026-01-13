import 'package:flutter/material.dart';
import 'package:fungi_casheer/pages/active_order_page.dart';
import 'package:get/get.dart';
import '../controllers/kasir_controller.dart';
import '../models/menu_model.dart';
import 'laporan_page.dart';
import 'atur_menu_page.dart';

class KasirPage extends StatelessWidget {
  const KasirPage({super.key});

  // Helper Format Rupiah
  String formatRupiah(int number) {
    return 'Rp ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final KasirController controller = Get.put(KasirController());

    // --- DIALOG INPUT DISKON (FIX OVERFLOW) ---
    // --- DIALOG INPUT DISKON (ANTI OVERFLOW & KEYBOARD AMAN) ---
    void showDiscountDialog(int index, Map<String, dynamic> item) {
      // Setup Controller & Variable
      int currentDiscountRp = item['discount'] ?? 0;
      int price = item['price_used'] ?? item['product'].price;

      final inputC = TextEditingController();
      var isPercent = false.obs;
      var calculatedRp = 0.obs;

      // Logic Hitung
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

      // Init awal
      inputC.text = currentDiscountRp > 0 ? currentDiscountRp.toString() : "";
      calculatePreview(inputC.text);

      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          // Gunakan SingleChildScrollView di root dialog agar SEMUA bisa di-scroll
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- TITLE ---
                const Text(
                  "Atur Potongan Harga",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 15),

                // --- INFO PRODUK ---
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

                // --- TOGGLE BUTTON (RP vs %) ---
                Obx(
                  () => Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // Tombol Rupiah
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
                        // Tombol Persen
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

                // --- TEXT FIELD INPUT ---
                Obx(
                  () => TextField(
                    controller: inputC,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    autofocus: true, // Keyboard muncul
                    onChanged: (val) => calculatePreview(val),
                    decoration: InputDecoration(
                      labelText: isPercent.value
                          ? "Masukkan Persentase"
                          : "Masukkan Nominal",
                      hintText: isPercent.value
                          ? "Contoh: 10, 20"
                          : "Contoh: 2000",
                      border: const OutlineInputBorder(),
                      prefixText: isPercent.value ? "" : "Rp ",
                      suffixText: isPercent.value ? "%" : "",
                      isDense: true,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // --- PREVIEW HASIL ---
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

                // --- TOMBOL AKSI (MANUAL DI DALAM SCROLL) ---
                Row(
                  children: [
                    // Tombol Batal
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
                    // Tombol Simpan
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          int finalDiscount = calculatedRp.value;
                          controller.updateItemDiscount(index, finalDiscount);
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

    // --- BOTTOM SHEET RINCIAN KERANJANG ---
    void showCartDetail() {
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
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      var item = controller.cartItems[index];
                      Product p = item['product'];
                      int price = item['price_used'] ?? p.price;
                      int discount = item['discount'] ?? 0;
                      int finalPrice = price - discount;
                      int qty = item['qty'];

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
                            // TOMBOL BERI DISKON
                            IconButton(
                              icon: Icon(
                                Icons.local_offer,
                                color: discount > 0
                                    ? Colors.orange
                                    : Colors.grey,
                              ),
                              tooltip: "Atur Diskon",
                              onPressed: () => showDiscountDialog(index, item),
                            ),
                            // INFO QTY
                            Text(
                              "${qty}x",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            // HAPUS ITEM
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

    void showVariantDialog(Product product) {
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),

              // Generate Tombol Varian + Harga
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: product.variantPrices.keys.map((code) {
                  int price =
                      product.variantPrices[code]!; // Ambil harga khusus varian

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
                      // Masukkan ke keranjang dengan HARGA KHUSUS
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
                child: const Text(
                  "Batal",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        isScrollControlled: true,
      );
    }

    // =========================================================================
    // 2. LOGIKA KLIK PRODUK
    // =========================================================================
    void onProductTap(Product product) {
      if (product.hasVariant) {
        showVariantDialog(product);
      } else {
        // Jika tidak ada varian, pakai harga dasar
        controller.addToCart(product, "-", product.price);
      }
    }

    // =========================================================================
    // 3. FORM PEMBAYARAN (FIX: MEJA HILANG SAAT TAKE AWAY)
    // =========================================================================
    void showPaymentBottomSheet() {
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
              // HEADER
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
                      // Total Harga
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

                      // INPUT NAMA
                      TextField(
                        controller: controller.nameController, // <--- UBAH INI
                        decoration: const InputDecoration(
                          labelText: "Nama Pelanggan",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // PILIHAN TIPE PESANAN
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
                                onTap: () => selectedType.value =
                                    type, // Trigger UI Update
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

                      // INPUT MEJA (HANYA MUNCUL JIKA DINE IN)
                      Obx(
                        () => Visibility(
                          visible: selectedType.value == 'Dine In',
                          child: Column(
                            children: [
                              TextField(
                                controller:
                                    controller.tableController, // <--- UBAH INI
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Nomor Meja (Wajib)",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.table_restaurant),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),

                      // PILIHAN METODE BAYAR
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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // === BAGIAN TOMBOL AKSI ===
              // === BAGIAN TOMBOL AKSI (PERBAIKAN: Gunakan controller global) ===
              Row(
                children: [
                  // TOMBOL 1: SIMPAN BILL (Running Order)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        // VALIDASI: Cek Meja HANYA jika Dine In
                        // GUNAKAN controller.tableController, BUKAN tableC
                        if (selectedType.value == 'Dine In' &&
                            controller.tableController.text.isEmpty) {
                          controller.showNotif(
                            "Error",
                            "Isi nomor meja!",
                            isError: true,
                          );
                          return;
                        }

                        // Kirim Data
                        controller.processTransaction(
                          // GUNAKAN controller.nameController
                          customerName: controller.nameController.text.isEmpty
                              ? "Pelanggan"
                              : controller.nameController.text,
                          // GUNAKAN controller.tableController
                          tableNumber: selectedType.value == 'Dine In'
                              ? controller.tableController.text
                              : "-", // Otomatis "-" jika Take Away
                          orderType: selectedType.value,
                          paymentMethod: "-",
                          isRunningOrder: true,
                        );
                        Get.back();
                      },
                      child: const Column(
                        children: [
                          Icon(Icons.save_as, color: Colors.white),
                          Text(
                            "SIMPAN BILL",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // TOMBOL 2: BAYAR LUNAS
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        // VALIDASI: Cek Meja HANYA jika Dine In
                        if (selectedType.value == 'Dine In' &&
                            controller.tableController.text.isEmpty) {
                          controller.showNotif(
                            "Error",
                            "Isi nomor meja!",
                            isError: true,
                          );
                          return;
                        }

                        // Kirim Data
                        controller.processTransaction(
                          customerName: controller.nameController.text.isEmpty
                              ? "Pelanggan"
                              : controller.nameController.text,
                          tableNumber: selectedType.value == 'Dine In'
                              ? controller.tableController.text
                              : "-",
                          orderType: selectedType.value,
                          paymentMethod: paymentMethod.value,
                          isRunningOrder: false,
                        );
                        Get.back();
                      },
                      child: const Column(
                        children: [
                          Icon(Icons.payment, color: Colors.white),
                          Text(
                            "BAYAR LUNAS",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        isScrollControlled: true,
      );
    }

    // =========================================================================
    // 4. DIALOG VOID / BATAL (Tetap simple dialog karena isinya sedikit)
    // =========================================================================
    void showCancelDialog() {
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
          if (reasonC.text.isEmpty) {
            controller.showNotif("Error", "Alasan wajib diisi!", isError: true);
            return;
          }
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

    // =========================================================================
    // 5. WIDGET KARTU PRODUK
    // =========================================================================
    Widget buildProductCard(Product product) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 3,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AREA GAMBAR & INFO (TAP TO ADD)
              Expanded(
                child: InkWell(
                  onTap: () => onProductTap(product),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // GAMBAR
                      SizedBox(
                        height: 80,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                product.imagePath,
                                fit: BoxFit.cover,
                                cacheWidth: 150,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.fastfood,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            // Badge QTY
                            if (product.quantity > 0)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    "${product.quantity}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            // Badge OPSI
                            if (product.hasVariant)
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "Opsi",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // NAMA & HARGA
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 4.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                formatRupiah(product.price),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
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

              // AREA TOMBOL BAWAH
              if (product.quantity == 0)
                InkWell(
                  onTap: () => onProductTap(product),
                  child: Container(
                    width: double.infinity,
                    height: 35,
                    color: Colors.green,
                    alignment: Alignment.center,
                    child: const Text(
                      "TAMBAH",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 35,
                  child: Row(
                    children: [
                      // Tombol Kurang (Langsung kurangi dari cart)
                      Expanded(
                        child: InkWell(
                          onTap: () => controller.removeFromCart(product),
                          child: Container(
                            color: Colors.red[50],
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.remove,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      // Angka
                      InkWell(
                        onTap: () => onProductTap(product),
                        child: Container(
                          width: 40,
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: Text(
                            "${product.quantity}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      // Tombol Tambah (Trigger opsi lagi)
                      Expanded(
                        child: InkWell(
                          onTap: () => onProductTap(product),
                          child: Container(
                            color: Colors.green,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // =========================================================================
    // 6. MAIN SCAFFOLD
    // =========================================================================
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Kasir Fungi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: "Laporan",
            onPressed: () => Get.to(() => const LaporanPage()),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Atur Menu",
            onPressed: () => Get.to(() => const AturMenuPage()),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Reset",
            color: Colors.red[100],
            onPressed: showCancelDialog,
          ),
          IconButton(
            icon: Icon(Icons.list_alt),
            tooltip: "Lihat Pesanan Berjalan",
            onPressed: () {
              Get.to(() => ActiveOrderPage());
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value)
          return const Center(child: CircularProgressIndicator());
        if (controller.menuData.isEmpty)
          return const Center(
            child: Text("Menu Kosong. Tambahkan di Settings."),
          );

        return Column(
          children: [
            // SEARCH BAR
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              color: Colors.green,
              child: TextField(
                onChanged: (val) => controller.searchText.value = val,
                decoration: InputDecoration(
                  hintText: "Cari menu...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: controller.searchText.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () => controller.searchText.value = '',
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // KATEGORI & SUBKATEGORI
            if (controller.searchText.value.isEmpty) ...[
              // Kategori
              Container(
                height: 50,
                color: Colors.white,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: controller.menuData.length,
                  itemBuilder: (context, index) {
                    bool isSelected =
                        controller.selectedCategoryIndex.value == index;
                    return GestureDetector(
                      onTap: () => controller.changeCategory(index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          controller.menuData[index].name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Sub Kategori
              Container(
                height: 45,
                color: Colors.white,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: controller
                      .menuData[controller.selectedCategoryIndex.value]
                      .subCategories
                      .length,
                  itemBuilder: (context, index) {
                    bool isSelected =
                        controller.selectedSubCategoryIndex.value == index;
                    var subCatName = controller
                        .menuData[controller.selectedCategoryIndex.value]
                        .subCategories[index]
                        .name;
                    return GestureDetector(
                      onTap: () =>
                          controller.selectedSubCategoryIndex.value = index,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green[50]
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected
                                ? Colors.green
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          subCatName,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.green[800]
                                : Colors.grey[600],
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // GRID PRODUK
            Expanded(
              child: controller.displayedProducts.isEmpty
                  ? Center(
                      child: Text(
                        "Tidak ada produk.",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.75,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: controller.displayedProducts.length,
                      itemBuilder: (context, index) {
                        return buildProductCard(
                          controller.displayedProducts[index],
                        );
                      },
                    ),
            ),
          ],
        );
      }),

      // BOTTOM SHEET TOTAL
      bottomSheet: Obx(() {
        if (controller.cartItems.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              // AREA TOTAL HARGA (KLIK UNTUK EDIT DISKON)
              Expanded(
                child: InkWell(
                  onTap: showCartDetail, // <--- PANGGIL BOTTOM SHEET DI SINI
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Total Tagihan",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_up,
                            size: 14,
                            color: Colors.grey[600],
                          ), // Indikator klik
                        ],
                      ),
                      Text(
                        formatRupiah(controller.totalPrice),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        "Klik untuk rincian & diskon",
                        style: TextStyle(fontSize: 10, color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ),

              // TOMBOL PROSES
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: showPaymentBottomSheet,
                child: const Text(
                  "PROSES",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
