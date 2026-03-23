import 'package:flutter/material.dart';

class FinancialCard extends StatelessWidget {
  final String title;
  final Map<String, int> data;
  final Color color;
  final bool isBig;
  final String Function(int) formatRupiah;

  const FinancialCard({
    super.key,
    required this.title,
    required this.data,
    required this.color,
    required this.isBig,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isBig ? 20 : 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isBig ? 14 : 12,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            child: Text(
              formatRupiah(data['Total']!),
              style: TextStyle(
                fontSize: isBig ? 24 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isBig) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tunai",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      formatRupiah(data['Tunai']!),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "QRIS",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      formatRupiah(data['QRIS']!),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
