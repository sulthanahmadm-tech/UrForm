import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const OutfitApp());
}

class OutfitApp extends StatelessWidget {
  const OutfitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Outfit Generator',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.amber,
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amberAccent,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

// ==========================================
// KONTROL NAVIGASI UTAMA (BOTTOM NAVBAR)
// ==========================================
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Daftar halaman yang akan ditampilkan sesuai urutan
  final List<Widget> _pages = [
    const EtalaseScreen(), // Index 0: Bintang (Inspo/Etalase)
    const FavoriteScreen(), // Index 1: Hati (Favorit)
    const WardrobeScreen(), // Index 2: Lemari (Katalog Baju)
    const ProfileScreen(), // Index 3: Orang (Profil)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Menampilkan halaman sesuai index
      
      // Tombol Generate Besar di Tengah (Navigasi ke halaman khusus)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GenerateScreen()),
          );
        },
        backgroundColor: Colors.amber,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // Navbar Bawah
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey[900],
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.auto_awesome, color: _currentIndex == 0 ? Colors.amber : Colors.white54),
              onPressed: () => setState(() => _currentIndex = 0),
            ),
            IconButton(
              icon: Icon(Icons.favorite_border, color: _currentIndex == 1 ? Colors.amber : Colors.white54),
              onPressed: () => setState(() => _currentIndex = 1),
            ),
            const SizedBox(width: 48), // Ruang kosong untuk tombol +
            IconButton(
              icon: Icon(Icons.checkroom, color: _currentIndex == 2 ? Colors.amber : Colors.white54),
              onPressed: () => setState(() => _currentIndex = 2),
            ),
            IconButton(
              icon: Icon(Icons.person_outline, color: _currentIndex == 3 ? Colors.amber : Colors.white54),
              onPressed: () => setState(() => _currentIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// HALAMAN 1: ETALASE / INSPO (Bintang)
// ==========================================
class EtalaseScreen extends StatelessWidget {
  const EtalaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Etalase Outfit", style: TextStyle(color: Colors.amber)), backgroundColor: Colors.black),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.amber), borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Icon(Icons.image, color: Colors.white54, size: 50)),
          );
        },
      ),
    );
  }
}

// ==========================================
// HALAMAN 2: GENERATE (Tombol + Tengah)
// ==========================================
class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final List<String> dummyAtasan = ["Kaos Hitam", "Kemeja Putih", "Jaket Denim", "Hoodie Abu"];
  final List<String> dummyBawahan = ["Jeans Biru", "Celana Chino Hitam", "Celana Pendek", "Cargo Pants"];
  
  String hasilAtasan = "?";
  String hasilBawahan = "?";

  void _generateOutfit() {
    final random = Random();
    setState(() {
      hasilAtasan = dummyAtasan[random.nextInt(dummyAtasan.length)];
      hasilBawahan = dummyBawahan[random.nextInt(dummyBawahan.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generate Photo", style: TextStyle(color: Colors.black)), backgroundColor: Colors.amber),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(border: Border.all(color: Colors.amber, width: 2)),
              child: Column(
                children: [
                  Text("Atasan: $hasilAtasan", style: const TextStyle(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 10),
                  Text("Bawahan: $hasilBawahan", style: const TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
              onPressed: _generateOutfit,
              child: const Text("GENERATE SEKARANG", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// HALAMAN 3, 4, 5: FAVORIT, LEMARI, PROFIL
// ==========================================
class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Katalog Favorit", style: TextStyle(color: Colors.amber, fontSize: 24)));
  }
}

class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Database Pakaian (Lemari)", style: TextStyle(color: Colors.amber, fontSize: 24)));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Akun User", style: TextStyle(color: Colors.amber, fontSize: 24)));
  }
}