import 'package:flutter/material.dart';
import 'package:fungi_casheer/controllers/kasir_controller.dart';
import 'package:fungi_casheer/pages/active_order_page.dart';
import 'package:fungi_casheer/pages/atur_menu_page.dart';
import 'package:fungi_casheer/pages/laporan/laporan_page.dart';
import 'package:get/get.dart';

import 'widgets/product_card.dart';
import 'widgets/category_section.dart';
import 'widgets/kasir_bottom_bar.dart';

class KasirPage extends StatelessWidget {
  const KasirPage({super.key});

  @override
  Widget build(BuildContext context) {
    final KasirController controller = Get.put(KasirController());

    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F6F8,
      ), // Latar belakang abu-abu sangat muda yang modern
      // === 1. APP BAR ===
      appBar: AppBar(
        title: const Text(
          'Kasir Fungi',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),

      // === 2. SIDEBAR (DRAWER) ===
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header Drawer dengan Gradient
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[800]!, Colors.green[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: const Text(
                "Admin Fungi",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: const Text("Kasir Utama"),
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            // Menu Navigasi
            _buildDrawerItem(
              icon: Icons.point_of_sale_rounded,
              color: Colors.green,
              title: 'Menu Kasir',
              onTap: () => Get.back(),
              isActive: true, // Beri highlight karena ini halaman aktif
            ),
            _buildDrawerItem(
              icon: Icons.receipt_long_rounded,
              color: Colors.blue,
              title: 'Pesanan Berjalan',
              onTap: () {
                Get.back();
                Get.to(
                  () => ActiveOrderPage(),
                  transition: Transition.cupertino,
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.insights_rounded,
              color: Colors.orange,
              title: 'Laporan & Riwayat',
              onTap: () {
                Get.back();
                Get.to(
                  () => const LaporanPage(),
                  transition: Transition.cupertino,
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Divider(),
            ),
            _buildDrawerItem(
              icon: Icons.tune_rounded,
              color: Colors.grey[700]!,
              title: 'Atur Menu & Harga',
              onTap: () {
                Get.back();
                Get.to(
                  () => const AturMenuPage(),
                  transition: Transition.cupertino,
                );
              },
            ),
            const Spacer(),
            _buildDrawerItem(
              icon: Icons.logout_rounded,
              color: Colors.red,
              title: 'Keluar',
              textColor: Colors.red,
              onTap: () => Get.snackbar(
                "Info",
                "Fitur logout belum diatur.",
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // === 3. BOTTOM BAR (KERANJANG) ===
      bottomSheet: KasirBottomBar(controller: controller),

      // === 4. BODY UTAMA ===
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }
        if (controller.menuData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.no_meals_rounded, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  "Menu Kosong.\nSilakan tambahkan di Pengaturan.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // --- FIXED HEADER (Background Hijau Melengkung) ---
            Container(
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(25),
                ),
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
                  // A. Search Bar (Floating Style)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (val) => controller.searchText.value = val,
                        decoration: InputDecoration(
                          hintText: "Cari hidangan favorit...",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Colors.green,
                          ),
                          suffixIcon: controller.searchText.value.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.cancel_rounded,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    controller.searchText.value = '';
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // B. Kategori & Subkategori
            if (controller.searchText.value.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CategorySection(controller: controller),
              ),

            // --- BAGIAN YANG BISA DI-SCROLL (LIST PRODUK) ---
            Expanded(
              child: controller.displayedProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 60,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Produk tidak ditemukan.",
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        120,
                      ), // Padding rapi
                      itemCount: controller.displayedProducts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600
                            ? 4
                            : 2,
                        childAspectRatio:
                            MediaQuery.of(context).size.width > 600
                            ? 1.3
                            : 1, // RASIO TETAP
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: controller.displayedProducts[index],
                          controller: controller,
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  // Helper Widget untuk Item Drawer agar lebih rapi & seragam
  Widget _buildDrawerItem({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? (isActive ? color : Colors.grey[800]),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
