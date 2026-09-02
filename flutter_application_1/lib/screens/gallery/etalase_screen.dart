import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EtalaseScreen extends StatefulWidget {
  const EtalaseScreen({super.key});

  @override
  State<EtalaseScreen> createState() => _EtalaseScreenState();
}

class _EtalaseScreenState extends State<EtalaseScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Etalase')),
        body: const Center(child: Text('Harap login untuk melihat Etalase.')),
      );
    }

    // Mengambil data outfit beserta relasi gambar dari tabel clothing_items
    final outfitStream = _supabase
        .from('outfits')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etalase Outfit'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFF121212),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: outfitStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat etalase.', style: TextStyle(color: Colors.red)));
          }

          final outfits = snapshot.data ?? [];
          if (outfits.isEmpty) {
            return const Center(child: Text('Belum ada outfit yang disimpan. Coba Generate!'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.65, // Lebih tinggi karena menumpuk banyak gambar
            ),
            itemCount: outfits.length,
            itemBuilder: (context, index) {
              final outfit = outfits[index];
              return _buildOutfitCard(outfit);
            },
          );
        },
      ),
    );
  }

  Widget _buildOutfitCard(Map<String, dynamic> outfit) {
    // Karena StreamBuilder tidak mendukung JOIN bawaan di Supabase Flutter v2 secara mudah,
    // Kita buat komponen yang me-load URL gambarnya secara dinamis menggunakan FutureBuilder
    return Card(
      color: const Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Render item-item di dalam outfit ini
          _FutureImageLayer(itemId: outfit['accessory_id'], top: 5, height: 40),
          _FutureImageLayer(itemId: outfit['top_id'], top: 40, height: 90),
          _FutureImageLayer(itemId: outfit['bottom_id'], top: 120, height: 90),
          _FutureImageLayer(itemId: outfit['shoes_id'], top: 200, height: 50),
          
          Positioned(
            bottom: 5,
            right: 5,
            child: Icon(
              outfit['is_favorite'] == true ? Icons.favorite : Icons.favorite_border,
              color: Colors.amber,
              size: 20,
            ),
          )
        ],
      ),
    );
  }
}

// Komponen bantuan untuk me-load gambar berdasarkan ID Pakaian
class _FutureImageLayer extends StatelessWidget {
  final String? itemId;
  final double top;
  final double height;

  const _FutureImageLayer({required this.itemId, required this.top, required this.height});

  Future<String?> _fetchImageUrl() async {
    if (itemId == null) return null;
    final data = await Supabase.instance.client
        .from('clothing_items')
        .select('image_url')
        .eq('id', itemId!)
        .maybeSingle();
    return data?['image_url'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    if (itemId == null) return const SizedBox.shrink();

    return Positioned(
      top: top,
      left: 10,
      right: 10,
      height: height,
      child: FutureBuilder<String?>(
        future: _fetchImageUrl(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          return Image.network(
            snapshot.data!,
            fit: BoxFit.contain,
            headers: const {'accept': '*/*'},
          );
        },
      ),
    );
  }
}
