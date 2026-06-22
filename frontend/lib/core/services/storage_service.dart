import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cloudinary Storage Service
// Free tier: 25 GB storage, 25 GB bandwidth/month — no credit card needed
// ─────────────────────────────────────────────────────────────────────────────
//
// HOW TO SET UP (one-time, 2 minutes):
//   1. Sign up free at https://cloudinary.com
//   2. Go to Dashboard → copy your Cloud Name, API Key, API Secret
//   3. Replace the values below
//
class StorageService {
  // ── Replace these with your Cloudinary credentials ──────────────────────────
  static const String _cloudName = 'djqh12768';
  static const String _apiKey    = '918419917996398';
  static const String _apiSecret = 'DQ7rXsCep1eCGswzDEftazss_so';
  // ────────────────────────────────────────────────────────────────────────────

  /// Uploads a file to Cloudinary and returns the secure download URL.
  /// [storagePath] is used as the public_id (folder/filename) in Cloudinary.
  Future<String> uploadFile(String storagePath, XFile file) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Build the signature: SHA-1 of "public_id=<path>&timestamp=<ts><secret>"
      final publicId  = storagePath.replaceAll('.jpg', '').replaceAll('.jpeg', '').replaceAll('.png', '');
      final sigString = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = sha1.convert(utf8.encode(sigString)).toString();

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final bytes = await file.readAsBytes();

      final request = http.MultipartRequest('POST', uri)
        ..fields['api_key']   = _apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature
        ..fields['public_id'] = publicId
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ));

      final response = await request.send().timeout(const Duration(seconds: 60));
      final body     = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final url  = json['secure_url'] as String?;
        if (url != null && url.isNotEmpty) return url;
        throw Exception('Cloudinary returned no URL. Response: $body');
      } else {
        throw Exception('Cloudinary upload failed (${response.statusCode}): $body');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Deletes a file from Cloudinary by its URL.
  Future<void> deleteFile(String url) async {
    try {
      // Extract public_id from URL and call Cloudinary destroy API
      final uri      = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.length < 2) return;

      // public_id is everything after /upload/ and before the file extension
      final uploadIdx = segments.indexOf('upload');
      if (uploadIdx == -1 || uploadIdx + 1 >= segments.length) return;
      final rawId     = segments.sublist(uploadIdx + 2).join('/');
      final publicId  = rawId.contains('.') ? rawId.substring(0, rawId.lastIndexOf('.')) : rawId;

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final sigString = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = sha1.convert(utf8.encode(sigString)).toString();

      await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
        body: {
          'api_key':   _apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
          'public_id': publicId,
        },
      );
    } catch (_) {
      // Non-fatal: log but don't fail the calling operation
    }
  }
}

final storageServiceProvider = Provider((ref) => StorageService());
