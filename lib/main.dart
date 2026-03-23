import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
// Import file konfigurasi Firebase (Hasil dari flutterfire configure)
// Jika baris ini merah, jalankan 'flutterfire configure' di terminal Anda.
import 'firebase_options.dart';

import 'package:intl/date_symbol_data_local.dart'; // Opsional: Untuk format tanggal Indonesia
import 'pages/kasir/kasir_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Setup Format Tanggal Indonesia (Opsional, agar DatePicker bahasa Indo)
  await initializeDateFormatting('id_ID', null);

  // 2. Inisialisasi Firebase
  try {
    await Firebase.initializeApp(
      // CRUCIAL: Baris ini WAJIB untuk Flutter Web
      // Tanpa ini, akan muncul error "FirebaseOptions cannot be null"
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ FIREBASE BERHASIL TERHUBUNG");
  } catch (e) {
    print("❌ FIREBASE GAGAL INIT: $e");
    print("⚠️ Pastikan Anda sudah menjalankan 'flutterfire configure'");
  }
  FlutterError.onError = (details) {
    print('FLUTTER ERROR: ${details.exception}');
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fungi Kasir',

      // Setting Tema Aplikasi
      theme: ThemeData(
        primarySwatch: Colors.green, // Gunakan Hijau sesuai tema Fungi
        scaffoldBackgroundColor: Colors.grey[50], // Latar belakang abu muda
        useMaterial3: false, // Gunakan style Material 2 agar konsisten
        // Custom App Bar Theme
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),

      // Konfigurasi Bahasa (Opsional)
      locale: const Locale('id', 'ID'),
      fallbackLocale: const Locale('en', 'US'),

      home: const KasirPage(),
    );
  }
}
