import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Kelas untuk melacak posisi dan data pakaian yang bisa di-drag
class DraggableItem {
  final Map<String, dynamic> data;
  double top;
  double left;
  final double width;
  final double height;

  DraggableItem({
    required this.data,
    required this.top,
    required this.left,
    this.width = 150,
    this.height = 150,
  });
}

class GenerateOutfitScreen extends ConsumerStatefulWidget {
  const GenerateOutfitScreen({super.key});

  @override
  ConsumerState<GenerateOutfitScreen> createState() => _GenerateOutfitScreenState();
}

class _GenerateOutfitScreenState extends ConsumerState<GenerateOutfitScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  
  List<DraggableItem> _outfitItems = [];

  @override
  void initState() {
    super.initState();
    // Otomatis mengacak pakaian saat layar pertama kali dibuka
    _generateRandomOutfit();
  }

  Future<void> _generateRandomOutfit() async {
    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Harus login terlebih dahulu");

      // Ambil seluruh pakaian pengguna dari database
      final response = await _supabase
          .from('clothing_items')
          .select()
          .eq('user_id', user.id);

      final List<dynamic> allItems = response as List<dynamic>;

      // Kelompokkan berdasarkan kategori
      final tops = allItems.where((i) => i['category'] == 'Top').toList();
      final bottoms = allItems.where((i) => i['category'] == 'Bottom').toList();
      final shoes = allItems.where((i) => i['category'] == 'Shoes').toList();
      final accessories = allItems.where((i) => i['category'] == 'Accessory').toList();

      final random = Random();
      final List<DraggableItem> newOutfit = [];

      // Dapatkan ukuran layar untuk posisi awal
      // Jika ukuran belum tersedia saat initState, kita asumsikan lebar 350
      final screenWidth = 350.0; 
      final centerX = (screenWidth - 150) / 2;

      // Pilih 1 acak dari tiap kategori jika tersedia, lalu tentukan posisi vertikal (Y) awal
      if (accessories.isNotEmpty) {
        newOutfit.add(DraggableItem(
          data: accessories[random.nextInt(accessories.length)],
          top: 20, left: centerX, width: 100, height: 100,
        ));
      }
      
      if (tops.isNotEmpty) {
        newOutfit.add(DraggableItem(
          data: tops[random.nextInt(tops.length)],
          top: 100, left: centerX, width: 180, height: 180,
        ));
      }

      if (bottoms.isNotEmpty) {
        newOutfit.add(DraggableItem(
          data: bottoms[random.nextInt(bottoms.length)],
          top: 260, left: centerX, width: 160, height: 160,
        ));
      }

      if (shoes.isNotEmpty) {
        newOutfit.add(DraggableItem(
          data: shoes[random.nextInt(shoes.length)],
          top: 400, left: centerX, width: 120, height: 120,
        ));
      }

      setState(() {
        _outfitItems = newOutfit;
      });

      if (newOutfit.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lemari Anda kosong. Tambahkan pakaian dulu!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToEtalase() async {
    if (_outfitItems.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser!;
      
      // Cari ID masing-masing kategori dari item yang sedang tampil
      String? topId, bottomId, shoesId, accessoryId;
      
      for (var item in _outfitItems) {
        final cat = item.data['category'];
        final id = item.data['id'];
        if (cat == 'Top') topId = id;
        if (cat == 'Bottom') bottomId = id;
        if (cat == 'Shoes') shoesId = id;
        if (cat == 'Accessory') accessoryId = id;
      }

      await _supabase.from('outfits').insert({
        'user_id': user.id,
        'top_id': topId,
        'bottom_id': bottomId,
        'shoes_id': shoesId,
        'accessory_id': accessoryId,
        'is_favorite': true, // Otomatis masuk favorit / etalase
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outfit berhasil disimpan ke Etalase!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfit Generator'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFF121212), // Warna latar kanvas
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Stack(
              children: [
                // Lapisan Bawah: Kanvas Interaktif (GestureDetector)
                ..._outfitItems.map((item) {
                  return Positioned(
                    top: item.top,
                    left: item.left,
                    child: GestureDetector(
                      // Logika Drag and Drop
                      onPanUpdate: (details) {
                        setState(() {
                          item.top += details.delta.dy;
                          item.left += details.delta.dx;
                        });
                      },
                      child: SizedBox(
                        width: item.width,
                        height: item.height,
                        child: Image.network(
                          item.data['image_url'],
                          fit: BoxFit.contain,
                          headers: const {'accept': '*/*'},
                        ),
                      ),
                    ),
                  );
                }),
                
                // Lapisan Atas: Tombol Aksi di bagian bawah layar
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: _generateRandomOutfit,
                        icon: const Icon(Icons.shuffle),
                        label: const Text('Acak Ulang'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: _outfitItems.isEmpty ? null : _saveToEtalase,
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan Outfit'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
