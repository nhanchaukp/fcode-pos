import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ImageClipboard {
  static const _channel = MethodChannel('fcode/image_clipboard');

  /// Sao chép ảnh vào clipboard iOS
  static Future<void> copyFromUrl(String url) async {
    // 1. Tải ảnh
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Không thể tải ảnh');
    }

    // 2. Lưu tạm
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/clipboard_image.jpg');
    await file.writeAsBytes(response.bodyBytes);

    // 3. Gọi native iOS để copy
    await _channel.invokeMethod('copyImage', {'path': file.path});
  }
}
