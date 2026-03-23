// import 'package:flutter/material.dart';
// import 'package:fungi_casheer/data/FirestoreHelper.dart';

// class KirimDataPage extends StatefulWidget {
//   const KirimDataPage({super.key});

//   @override
//   State<KirimDataPage> createState() => _KirimDataPageState();
// }

// class _KirimDataPageState extends State<KirimDataPage> {
//   int totalTransactions = 0;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _checkCloudData();
//   }

//   // Cek Data Langsung ke Cloud
//   Future<void> _checkCloudData() async {
//     // Kita ambil total transaksi hari ini sebagai contoh
//     DateTime now = DateTime.now();
//     final data = await FirestoreHelper.instance.getTransactionsByCustomRange(
//       DateTime(now.year, now.month, now.day),
//       DateTime(now.year, now.month, now.day, 23, 59, 59),
//     );

//     setState(() {
//       totalTransactions = data.length;
//       isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Status Cloud"),
//         backgroundColor: Colors.green,
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(30.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.cloud_done, size: 100, color: Colors.blue),
//               const SizedBox(height: 20),
//               const Text(
//                 "Sistem Online (Firestore)",
//                 style: TextStyle(fontSize: 18, color: Colors.grey),
//               ),
//               const SizedBox(height: 10),
//               if (isLoading)
//                 const CircularProgressIndicator()
//               else
//                 Text(
//                   "$totalTransactions Transaksi Hari Ini",
//                   style: const TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               const SizedBox(height: 20),
//               const Text(
//                 "Data Anda tersimpan otomatis di Cloud secara Real-time.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 12, color: Colors.grey),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
