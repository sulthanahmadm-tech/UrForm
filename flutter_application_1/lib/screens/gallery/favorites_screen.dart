import 'package:flutter/material.dart';
import 'etalase_screen.dart'; // Impor file etalase untuk menggunakan kembali widgetnya

// Untuk sementara waktu, Favorites dan Etalase memiliki fungsi yang hampir sama,
// namun di Favorites kita hanya menampilkan yang is_favorite = true.
// Berhubung di Outfit Generator kita selalu set is_favorite = true,
// layarnya akan menampilkan hal yang sama. Kita bisa langsung me-return EtalaseScreen.

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Tampilkan EtalaseScreen karena fungsinya sama untuk saat ini
    return const EtalaseScreen();
  }
}
