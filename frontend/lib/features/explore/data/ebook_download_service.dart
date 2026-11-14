import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'open_library_service.dart';

class DownloadResult {
  final bool success;
  final String? filePath;
  final String? message;

  const DownloadResult({
    required this.success,
    this.filePath,
    this.message,
  });
}

class EbookDownloadService {
  EbookDownloadService._();
  static final EbookDownloadService instance = EbookDownloadService._();

  /// Returns the target directory for downloaded books.
  Future<Directory> getDownloadsDirectory() async {
    Directory? baseDir;
    if (!kIsWeb && Platform.isAndroid) {
      baseDir = await getExternalStorageDirectory();
    }
    baseDir ??= await getApplicationDocumentsDirectory();

    final booksDir = Directory('${baseDir.path}/Liread_Books');
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    return booksDir;
  }

  /// Sanitizes book title into a safe filename.
  String sanitizeFilename(String title, String format) {
    final clean = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    final safeName = clean.isEmpty ? 'book' : (clean.length > 50 ? clean.substring(0, 50) : clean);
    return '$safeName.$format';
  }

  /// Direct 1-click book download.
  Future<DownloadResult> downloadBook({
    required OpenLibraryBook book,
    String format = 'epub',
    void Function(double progress)? onProgress,
  }) async {
    final downloadUrl = format.toLowerCase() == 'pdf'
        ? (book.pdfDownloadUrl ?? book.epubDownloadUrl)
        : (book.epubDownloadUrl ?? book.pdfDownloadUrl);

    if (downloadUrl == null || downloadUrl.isEmpty) {
      return const DownloadResult(
        success: false,
        message: 'No direct download link available for this edition.',
      );
    }

    try {
      final uri = Uri.parse(downloadUrl);
      final client = http.Client();
      final request = http.Request('GET', uri)
        ..headers['User-Agent'] = 'LireadMobile/1.0 (contact: liread@app.local)';

      final response = await client.send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final contentLength = response.contentLength ?? 0;
        final targetDir = await getDownloadsDirectory();
        final filename = sanitizeFilename(book.title, format);
        final file = File('${targetDir.path}/$filename');

        final sink = file.openWrite();
        int bytesReceived = 0;

        await response.stream.listen(
          (chunk) {
            bytesReceived += chunk.length;
            sink.add(chunk);
            if (contentLength > 0 && onProgress != null) {
              onProgress(bytesReceived / contentLength);
            }
          },
          cancelOnError: true,
        ).asFuture();

        await sink.flush();
        await sink.close();

        return DownloadResult(
          success: true,
          filePath: file.path,
          message: 'Saved to ${file.path}',
        );
      } else {
        return DownloadResult(
          success: false,
          message: 'Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Download error: $e');
      return DownloadResult(
        success: false,
        message: 'Download failed: $e',
      );
    }
  }

  /// Launch external viewer or file explorer for the downloaded book.
  Future<bool> openDownloadedBook(String filePath) async {
    try {
      final uri = Uri.file(filePath);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening book file: $e');
      return false;
    }
  }
}
