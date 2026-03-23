import 'package:flutter/material.dart';
import 'package:fungi_casheer/controllers/kasir_controller.dart';
import 'package:fungi_casheer/models/menu_model.dart';
import 'package:fungi_casheer/pages/kasir/kasir_dialogs.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final KasirController controller;

  const ProductCard({
    super.key,
    required this.product,
    required this.controller,
  });

  void onProductTap() {
    if (product.hasVariant) {
      KasirDialogs.showVariantDialog(product, controller);
    } else {
      controller.addToCart(product, "-", product.price);
    }
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder mendeteksi ukuran widget yang dialokasikan oleh GridView
    return LayoutBuilder(
      builder: (context, constraints) {
        // Logika Responsif: Jika lebar card > 150 (seperti di Tablet), perbesar font & icon
        double cardWidth = constraints.maxWidth;
        bool isTablet = cardWidth > 150;

        double titleFontSize = isTablet ? 14 : 12;
        double priceFontSize = isTablet ? 13 : 11;
        double badgeFontSize = isTablet ? 11 : 9;
        double buttonHeight = isTablet ? 40 : 35;
        double iconSize = isTablet ? 20 : 18;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10), // Sedikit lebih melengkung
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 5,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === BAGIAN ATAS: GAMBAR & INFO (FLEXIBLE) ===
                Expanded(
                  child: InkWell(
                    onTap: onProductTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // GAMBAR (Menggunakan Expanded dengan flex ratio agar tidak fixed 80px)
                        Expanded(
                          flex: 5, // Gambar mengambil 5 bagian ruang
                          child: Stack(
                            fit: StackFit
                                .expand, // Memaksa gambar mengisi penuh area ini
                            children: [
                              Image.asset(
                                product.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.fastfood,
                                    size: isTablet ? 40 : 30,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              // Badge Quantity (Kanan Atas)
                              if (product.quantity > 0)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      "${product.quantity}",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: badgeFontSize,
                                      ),
                                    ),
                                  ),
                                ),
                              // Badge Varian/Opsi (Kiri Bawah)
                              if (product.hasVariant)
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "Opsi",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: badgeFontSize - 1,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // TEKS NAMA & HARGA (Mengambil 3 bagian ruang)
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 6.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment
                                  .center, // Pusatkan teks di ruangnya
                              children: [
                                Text(
                                  product.name,
                                  maxLines:
                                      2, // Izinkan 2 baris jika nama menu panjang
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: titleFontSize,
                                    height: 1.2,
                                  ),
                                ),
                                const Spacer(), // Dorong harga ke paling bawah
                                Text(
                                  KasirDialogs.formatRupiah(product.price),
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: priceFontSize,
                                    fontWeight: FontWeight.w800,
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

                // === BAGIAN BAWAH: TOMBOL AKSI (UKURAN FIXED TAPI RESPONSIVE) ===
                if (product.quantity == 0)
                  InkWell(
                    onTap: onProductTap,
                    child: Container(
                      width: double.infinity,
                      height: buttonHeight, // Dinamis antara HP & Tablet
                      color: Colors.green,
                      alignment: Alignment.center,
                      child: Text(
                        "TAMBAH",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize:
                              titleFontSize, // Mengikuti ukuran font dinamis
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: buttonHeight,
                    child: Row(
                      children: [
                        // Tombol Kurang (-)
                        Expanded(
                          child: InkWell(
                            onTap: () => controller.removeFromCart(product),
                            child: Container(
                              color: Colors.red[50],
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.remove,
                                color: Colors.red,
                                size: iconSize,
                              ),
                            ),
                          ),
                        ),
                        // Angka Jumlah
                        InkWell(
                          onTap: onProductTap,
                          child: Container(
                            width:
                                cardWidth *
                                0.3, // Lebar area angka adalah 30% dari lebar card
                            color: Colors.white,
                            alignment: Alignment.center,
                            child: Text(
                              "${product.quantity}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: titleFontSize + 2,
                              ),
                            ),
                          ),
                        ),
                        // Tombol Tambah (+)
                        Expanded(
                          child: InkWell(
                            onTap: onProductTap,
                            child: Container(
                              color: Colors.green,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: iconSize,
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
      },
    );
  }
}
