import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ClothingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // URL untuk Python API (menggunakan 10.0.2.2 untuk Android Emulator, 127.0.0.1 untuk lainnya)
  String get _pythonApiUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/remove-background';
    }
    return 'http://127.0.0.1:8000/remove-background';
  }

  /// 1. Mengirim gambar asli ke API Python untuk dihapus backgroundnya
  Future<Uint8List> removeBackground(File imageFile) async {
    final request = http.MultipartRequest('POST', Uri.parse(_pythonApiUrl));
    request.files.add(await http.MultipartFile.fromPath(
      'image', 
      imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    
    final response = await request.send();
    
    if (response.statusCode == 200) {
      // Mengembalikan byte gambar PNG transparan
      return await response.stream.toBytes();
    } else {
      throw Exception('Gagal menghapus background: ${response.statusCode}');
    }
  }

  /// 2. Mengunggah gambar PNG transparan ke Supabase Storage
  Future<String> uploadImageToStorage(Uint8List imageBytes, String userId) async {
    final fileName = '${const Uuid().v4()}.png';
    final filePath = '$userId/$fileName';
    
    await _supabase.storage.from('clothing_images').uploadBinary(
      filePath, 
      imageBytes,
      fileOptions: const FileOptions(contentType: 'image/png'),
    );
    
    // Dapatkan URL publik dari gambar yang baru diupload
    final String publicUrl = _supabase.storage.from('clothing_images').getPublicUrl(filePath);
    return publicUrl;
  }

  /// 3. Menyimpan data pakaian ke database
  Future<void> saveClothingItem({
    required String category,
    required String imageUrl,
    String? color,
    String? style,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Anda harus login terlebih dahulu');

    await _supabase.from('clothing_items').insert({
      'user_id': user.id,
      'category': category,
      'color': color ?? '',
      'style': style ?? '',
      'image_url': imageUrl,
    });
  }
}
