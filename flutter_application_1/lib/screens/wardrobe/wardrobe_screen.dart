import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/clothing_service.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  final ClothingService _clothingService = ClothingService();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isUploading = false;
  String _uploadStatus = '';

  Future<void> _pickAndUploadImage() async {
    // 1. Pastikan user login
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk menambah pakaian'), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. Pilih sumber gambar (Kamera atau Galeri)
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return; // User membatalkan

    XFile? pickedFile;
    try {
      final picker = ImagePicker();
      pickedFile = await picker.pickImage(source: source);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka kamera/galeri.'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    
    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Menghapus latar belakang...';
    });

    try {
      // 3. Hapus background pakai Python API
      final file = File(pickedFile.path);
      final transparentBytes = await _clothingService.removeBackground(file);

      setState(() => _uploadStatus = 'Mengunggah ke Supabase...');

      // 4. Upload ke Supabase Storage
      final imageUrl = await _clothingService.uploadImageToStorage(transparentBytes, user.id);

      // 5. Minta user memilih kategori via Dialog
      if (!mounted) return;
      final category = await _showCategoryDialog();
      if (category == null) {
        throw Exception('Kategori tidak dipilih, batal menyimpan.');
      }

      setState(() => _uploadStatus = 'Menyimpan data...');

      // 6. Simpan ke database
      await _clothingService.saveClothingItem(
        category: category,
        imageUrl: imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pakaian berhasil ditambahkan!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambahkan pakaian. Silakan coba lagi.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
      }
    }
  }

  Future<String?> _showCategoryDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Kategori'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: const Text('Atasan (Top)'), onTap: () => Navigator.pop(context, 'Top')),
              ListTile(title: const Text('Bawahan (Bottom)'), onTap: () => Navigator.pop(context, 'Bottom')),
              ListTile(title: const Text('Sepatu (Shoes)'), onTap: () => Navigator.pop(context, 'Shoes')),
              ListTile(title: const Text('Aksesoris (Accessory)'), onTap: () => Navigator.pop(context, 'Accessory')),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Harap login untuk melihat lemari Anda.')),
      );
    }

    // Gunakan StreamBuilder untuk update grid secara realtime, difilter berdasarkan user_id
    final stream = _supabase.from('clothing_items').stream(primaryKey: ['id']).eq('user_id', user.id).order('created_at', ascending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lemari Pakaian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _isUploading ? null : _pickAndUploadImage,
          ),
        ],
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.amber),
                  const SizedBox(height: 16),
                  Text(_uploadStatus, style: const TextStyle(color: Colors.amber)),
                ],
              ),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Gagal memuat isi lemari.'));
                }
                
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('Lemari Anda masih kosong. Tambahkan pakaian!'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      color: const Color(0xFF2C2C2C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                item['image_url'],
                                fit: BoxFit.contain,
                                // Menambahkan header kosong untuk mengatasi cache/CORS
                                headers: const {'accept': '*/*'},
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                            ),
                            child: Text(
                              item['category'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
