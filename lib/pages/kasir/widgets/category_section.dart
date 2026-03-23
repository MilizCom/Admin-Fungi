import 'package:flutter/material.dart';
import 'package:fungi_casheer/controllers/kasir_controller.dart';
import 'package:get/get.dart';

class CategorySection extends StatelessWidget {
  final KasirController controller;

  const CategorySection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kategori Utama
        Container(
          height: 50,
          color: Colors.white,
          child: Obx(
            () => ListView.builder(
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
        ),
        // Sub Kategori
        Container(
          height: 45,
          color: Colors.white,
          child: Obx(
            () => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: controller.menuData.isEmpty
                  ? 0
                  : controller
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
                      color: isSelected ? Colors.green[50] : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
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
        ),
      ],
    );
  }
}
