import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

class FileDownloadService {
  static Future<void> downloadFile(String url, String fileName) async {
    try {
      if (kIsWeb) {
        // For web, open the URL in a new tab
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          throw Exception('Could not launch $url');
        }
      } else {
        // For mobile/desktop, download to local storage
        final response = await HttpClient().getUrl(Uri.parse(url));
        final HttpClientResponse clientResponse = await response.close();
        Uint8List bytes =
            await consolidateHttpClientResponseBytes(clientResponse);

        // Get the downloads directory
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');

        // Write to file
        await file.writeAsBytes(bytes);
      }
    } catch (e) {
      debugPrint('Error downloading file: $e');
      rethrow;
    }
  }
}
