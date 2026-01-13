import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart'; // Import ini
import 'pages/kasir_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print("✅ FIREBASE BERHASIL TERHUBUNG");
  } catch (e) {
    print("❌ FIREBASE GAGAL INIT: $e");
    // Jika gagal, aplikasi kemungkinan akan crash saat pakai fitur firebase nanti
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fungi Kasir Offline-First',
      theme: ThemeData(primarySwatch: Colors.yellow),
      home: const KasirPage(),
    );
  }
}
