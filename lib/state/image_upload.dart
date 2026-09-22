import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Cloudinary is used for post images instead of Firebase Storage —
/// Storage now requires the Blaze plan (a card on file) even to stay
/// within the free quota, where Cloudinary's free tier (25GB) needs no
/// card at all. The upload preset must be "Unsigned" in the Cloudinary
/// dashboard (Settings → Upload → Upload presets) — that's what lets the
/// client upload directly with no backend/signing step.
class CloudinaryConfig {
  static const cloudName = 'ehfbzrce';
  static const uploadPreset = 'contento';
}

/// Uploads a post's image to Cloudinary and returns its public URL.
Future<String> uploadPostImage({
  required String postId,
  required Uint8List bytes,
  required String fileExtension,
}) async {
  final uri = Uri.parse('https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload');
  final request = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
    ..fields['public_id'] = postId
    ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'post_$postId.$fileExtension'));

  final streamedResponse = await request.send();
  final body = await streamedResponse.stream.bytesToString();

  if (streamedResponse.statusCode != 200) {
    throw Exception('Image upload failed (${streamedResponse.statusCode}): $body');
  }

  final json = jsonDecode(body) as Map<String, dynamic>;
  return json['secure_url'] as String;
}
