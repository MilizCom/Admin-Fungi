import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ingredient_controller.dart';
import '../models/ingredient_model.dart';

class IngredientPage extends StatefulWidget {
  const IngredientPage({super.key});

  @override
  State<IngredientPage> createState() => _IngredientPageState();
}

class _IngredientPageState extends State<IngredientPage> {
  final IngredientController controller = Get.put(IngredientController());

  // State Lokal untuk UI (Search & Filter)
  final TextEditingController searchC = TextEditingController();
  String filterStatus = 'Semua'; // Pilihan: Semua, Menipis, Aman
  // --- TAMBAHKAN INI (AUTO SYNC SAAT BUKA PAGE) ---
  @override
  void initState() {
    super.initState();
    // Gunakan postFrameCallback agar dijalankan setelah UI siap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.syncStockFromTransactions(); // <--- Auto Sync Stok
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Stok Bahan Baku",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Di dalam AppBar actions[]
          IconButton(
            icon: const Icon(
              Icons.file_upload,
              color: Colors.green,
            ), // Ikon Upload Hijau
            tooltip: "Export ke Excel/Spreadsheet",
            onPressed: () => controller.exportStockToSpreadsheet(),
          ),
          // Indikator Sync
          Obx(
            () => controller.isSyncing.value
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.sync, color: Colors.blue),
                    tooltip: "Sinkronisasi dari Kasir",
                    onPressed: () => controller.syncStockFromTransactions(),
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null),
        backgroundColor: Colors.blue[800],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Bahan Baru", style: TextStyle(color: Colors.white)),
      ),

      body: Column(
        children: [
          // --- 1. BAGIAN SEARCH & FILTER ---
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: searchC,
                  onChanged: (val) => setState(() {}), // Refresh UI saat ngetik
                  decoration: InputDecoration(
                    hintText: "Cari bahan baku...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("Semua", Colors.blue),
                      const SizedBox(width: 8),
                      _buildFilterChip("Menipis", Colors.red),
                      const SizedBox(width: 8),
                      _buildFilterChip("Aman", Colors.green),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- 2. LIST BAHAN BAKU ---
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // LOGIKA FILTERING
              var list = controller.ingredients.where((ing) {
                // 1. Filter Nama
                bool matchName = ing.name.toLowerCase().contains(
                  searchC.text.toLowerCase(),
                );

                // 2. Filter Status
                bool matchStatus = true;
                bool isLow = ing.stock <= ing.minStock;
                if (filterStatus == 'Menipis') matchStatus = isLow;
                if (filterStatus == 'Aman') matchStatus = !isLow;

                return matchName && matchStatus;
              }).toList();

              // Sort: Yang menipis ditaruh paling atas
              list.sort((a, b) {
                bool aLow = a.stock <= a.minStock;
                bool bLow = b.stock <= b.minStock;
                if (aLow && !bLow) return -1;
                if (!aLow && bLow) return 1;
                return a.name.compareTo(b.name);
              });

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 60,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Tidak ada bahan ditemukan.",
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (c, i) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _buildIngredientCard(list[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- WIDGET CHIP FILTER ---
  Widget _buildFilterChip(String label, Color color) {
    bool isSelected = filterStatus == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: color,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? color : Colors.grey[300]!),
      onSelected: (val) {
        if (val) setState(() => filterStatus = label);
      },
    );
  }

  // --- WIDGET KARTU BAHAN ---
  Widget _buildIngredientCard(IngredientModel ing) {
    bool isLow = ing.stock <= ing.minStock;
    Color statusColor = isLow ? Colors.red : Colors.green;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isLow ? Colors.red.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // 1. Icon Status
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isLow
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                color: statusColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 15),

            // 2. Info Nama & Stok
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ing.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "${ing.stock} ${ing.unit}",
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "(Min: ${ing.minStock})",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Tombol Aksi
            Row(
              children: [
                // Tombol Quick Add (Stok Masuk)
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  tooltip: "Tambah Stok Cepat",
                  onPressed: () => _showQuickStockDialog(ing),
                ),
                // Tombol Edit Full
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.grey[400]),
                  tooltip: "Edit Detail",
                  onPressed: () => _showForm(context, ing),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG TAMBAH STOK CEPAT (Quick Restock) ---
  void _showQuickStockDialog(IngredientModel ing) {
    final qtyC = TextEditingController();
    Get.defaultDialog(
      title: "Restock: ${ing.name}",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      content: Column(
        children: [
          const Text("Masukkan jumlah stok yang baru datang/dibeli."),
          const SizedBox(height: 15),
          TextField(
            controller: qtyC,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: "Jumlah Tambahan",
              suffixText: ing.unit,
              border: const OutlineInputBorder(),
              hintText: "Contoh: 1000",
            ),
          ),
        ],
      ),
      textConfirm: "TAMBAH STOK",
      confirmTextColor: Colors.white,
      buttonColor: Colors.blue,
      onConfirm: () {
        int addAmount = int.tryParse(qtyC.text) ?? 0;
        if (addAmount > 0) {
          // Update Stok Lama + Baru
          controller.saveIngredient(
            id: ing.id,
            name: ing.name,
            unit: ing.unit,
            stock: ing.stock + addAmount, // <--- Logika Penambahan
            minStock: ing.minStock,
          );
          Get.back();
          Get.snackbar(
            "Berhasil",
            "Stok ${ing.name} bertambah $addAmount ${ing.unit}",
          );
        }
      },
    );
  }

  // --- FORM FULL (Edit / Baru) ---
  void _showForm(BuildContext context, IngredientModel? ing) {
    final nameC = TextEditingController(text: ing?.name);
    final stockC = TextEditingController(text: ing?.stock.toString());
    final minStockC = TextEditingController(
      text: ing?.minStock.toString() ?? '10',
    );
    String selectedUnit = ing?.unit ?? 'gr';
    final List<String> unitOptions = [
      'gr',
      'ml',
      'pcs',
      'pack',
      'kg',
      'liter',
      'butir',
      'siung',
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        height: Get.height * 0.7, // Setengah layar
        child: Column(
          children: [
            Text(
              ing == null ? "Bahan Baku Baru" : "Edit ${ing.name}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  TextField(
                    controller: nameC,
                    decoration: const InputDecoration(
                      labelText: "Nama Bahan",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: stockC,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Stok Fisik",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: unitOptions.contains(selectedUnit)
                              ? selectedUnit
                              : unitOptions[0],
                          items: unitOptions
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (val) => selectedUnit = val!,
                          decoration: const InputDecoration(
                            labelText: "Unit",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: minStockC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Minimal Stok (Warning)",
                      helperText:
                          "Jika stok di bawah ini, akan muncul tanda merah.",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  if (nameC.text.isEmpty) return;
                  controller.saveIngredient(
                    id: ing?.id,
                    name: nameC.text,
                    unit: selectedUnit,
                    stock: int.tryParse(stockC.text) ?? 0,
                    minStock: int.tryParse(minStockC.text) ?? 10,
                  );
                  Get.back();
                },
                child: Text(
                  ing == null ? "SIMPAN" : "UPDATE",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
